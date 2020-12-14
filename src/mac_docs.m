

#include <config.h>
#include <Foundation/Foundation.h>
//#include "lisp.h"
//#include "blockinput.h"

#include "lisp.h"
#include "nsgui.h"
#include "nsterm.h"

#import <objc/runtime.h>

#import "macappkit.h"


#if USE_ARC
#define MRC_RETAIN(receiver)		((id) (receiver))
#define MRC_RELEASE(receiver)
#define MRC_AUTORELEASE(receiver)	((id) (receiver))
#define CF_BRIDGING_RETAIN		CFBridgingRetain
#define CF_BRIDGING_RELEASE		CFBridgingRelease
#else
#define MRC_RETAIN(receiver)		[(receiver) retain]
#define MRC_RELEASE(receiver)		[(receiver) release]
#define MRC_AUTORELEASE(receiver)	[(receiver) autorelease]
#define __bridge
static inline CFTypeRef
CF_BRIDGING_RETAIN (id X)
{
  return X ? CFRetain ((CFTypeRef) X) : NULL;
}
static inline id
CF_BRIDGING_RELEASE (CFTypeRef X)
{
  return [(id)(X) autorelease];
}
#endif
#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1090
#define CF_AUTORELEASE	CFAutorelease
#else
static inline CFTypeRef
CF_AUTORELEASE (CFTypeRef X)
{
  id __autoreleasing result = CF_BRIDGING_RELEASE (X);

  return (__bridge CFTypeRef) result;
}
#endif

typedef const struct _EmacsDocument *EmacsDocumentRef; /* opaque */

#define DOCUMENT_RASTERIZER_CACHE_DURATION 60.0


static NSMutableDictionaryOf (id, NSDictionaryOf (NSString *, id) *)
  *documentRasterizerCache;
static NSDate *documentRasterizerCacheOldestTimestamp;
#define DOCUMENT_RASTERIZER_CACHE_DURATION 60.0

@implementation EmacsPDFDocument

/* Like -[PDFDocument initWithURL:], but suppress warnings if not
   loading a PDF file.  */

- (instancetype)initWithURL:(NSURL *)url
		    options:(NSDictionaryOf (NSString *, id) *)options
{
  NSFileHandle *fileHandle;
  NSData *data;
  NSString *type = [options objectForKey:@"UTI"]; /* NSFileTypeDocumentOption */

  if (type && !UTTypeEqual ((__bridge CFStringRef) type, kUTTypePDF))
    goto error;

  fileHandle = [NSFileHandle fileHandleForReadingFromURL:url error:NULL];
  data = [fileHandle readDataOfLength:5];

  if ([data length] < 5 || memcmp ([data bytes], "%PDF-", 5) != 0)
    goto error;

  self = [self initWithURL:url];

  return self;

 error:
  self = [super init];
  MRC_RELEASE (self);
  self = nil;

  return self;
}

/* Like -[PDFDocument initWithData:], but suppress warnings if not
   loading a PDF data.  */

- (instancetype)initWithData:(NSData *)data
		     options:(NSDictionaryOf (NSString *, id) *)options
{
  NSString *type = [options objectForKey:@"UTI"]; /* NSFileTypeDocumentOption */

  if (type && !UTTypeEqual ((__bridge CFStringRef) type, kUTTypePDF))
    goto error;
  if ([data length] < 5 || memcmp ([data bytes], "%PDF-", 5) != 0)
    goto error;

  self = [self initWithData:data];

  return self;

 error:
  self = [super init];
  MRC_RELEASE (self);
  self = nil;

  return self;
}

+ (NSArrayOf (NSString *) *)supportedTypes
{
  return [NSArray arrayWithObject:((__bridge NSString *) kUTTypePDF)];
}

- (NSSize)integralSizeOfPageAtIndex:(NSUInteger)index
{
  PDFPage *page = [self pageAtIndex:index];
  NSRect bounds = [page boundsForBox:kPDFDisplayBoxTrimBox];
  int rotation = [page rotation];

  if (rotation == 0 || rotation == 180)
    return NSMakeSize (ceil (NSWidth (bounds)), ceil (NSHeight (bounds)));
  else
    return NSMakeSize (ceil (NSHeight (bounds)), ceil (NSWidth (bounds)));
}

- (CGColorRef)copyBackgroundCGColorOfPageAtIndex:(NSUInteger)index
{
  return NULL;
}

- (NSDictionaryOf (NSString *, id) *)documentAttributesOfPageAtIndex:(NSUInteger)index
{
  return [self documentAttributes];
}

- (void)drawPageAtIndex:(NSUInteger)index inRect:(NSRect)rect
	      inContext:(CGContextRef)ctx
{
  PDFPage *page = [self pageAtIndex:index];
  NSRect bounds = [page boundsForBox:kPDFDisplayBoxTrimBox];
  int rotation = [page rotation];
  CGFloat width, height;

  if (rotation == 0 || rotation == 180)
    width = ceil (NSWidth (bounds)), height = ceil (NSHeight (bounds));
  else
    width = ceil (NSHeight (bounds)), height = ceil (NSWidth (bounds));
#if MAC_OS_X_VERSION_MIN_REQUIRED < 101200
  if ([page respondsToSelector:@selector(drawWithBox:toContext:)])
#endif
    {
      CGContextSaveGState (ctx);
      CGContextTranslateCTM (ctx, NSMinX (rect), NSMinY (rect));
      CGContextScaleCTM (ctx, NSWidth (rect) / width, NSHeight (rect) / height);
      [page drawWithBox:kPDFDisplayBoxTrimBox toContext:ctx];
      CGContextRestoreGState (ctx);
    }
#if MAC_OS_X_VERSION_MIN_REQUIRED < 101200
  else
    {
      NSAffineTransform *transform = [NSAffineTransform transform];
      NSGraphicsContext *gcontext =
	[NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:NO];

      [NSGraphicsContext saveGraphicsState];
      NSGraphicsContext.currentContext = gcontext;
      [transform translateXBy:(NSMinX (rect)) yBy:(NSMinY (rect))];
      [transform scaleXBy:(NSWidth (rect) / width)
		      yBy:(NSHeight (rect) / height)];
      [transform concat];
      [page drawWithBox:kPDFDisplayBoxTrimBox];
      [NSGraphicsContext restoreGraphicsState];
    }
#endif
}

@end				// EmacsPDFDocument

@implementation EmacsDocumentRasterizer
- (instancetype)initWithAttributedString:(NSAttributedString *)anAttributedString
		      documentAttributes:(NSDictionaryOf (NSString *, id) *)docAttributes
{
  NSLayoutManager *layoutManager;
  NSTextContainer *textContainer;
  int viewMode;
  NSRange glyphRange;

  self = [super init];

  if (self == nil)
    return nil;

  textStorage = [[NSTextStorage alloc]
		  initWithAttributedString:anAttributedString];
  layoutManager = [[NSLayoutManager alloc] init];
  textContainer = [[NSTextContainer alloc] init];

#if MAC_OS_X_VERSION_MIN_REQUIRED < 101100
  [layoutManager setUsesScreenFonts:NO];
#endif

  [layoutManager addTextContainer:textContainer];
  MRC_RELEASE (textContainer);
  [textStorage addLayoutManager:layoutManager];
  MRC_RELEASE (layoutManager);

  if (!(textStorage && layoutManager && textContainer))
    {
      MRC_RELEASE (self);
      self = nil;

      return self;
    }

  viewMode = [[docAttributes objectForKey:NSViewModeDocumentAttribute]
	       intValue];
  if (viewMode == 0)
    [textContainer setLineFragmentPadding:0];
  else
    {
      /* page layout */
      NSSize pageSize =
	[[docAttributes objectForKey:NSPaperSizeDocumentAttribute] sizeValue];
      NSAttributedStringDocumentAttributeKey __unsafe_unretained
	marginAttributes[4] = {
	NSLeftMarginDocumentAttribute, NSRightMarginDocumentAttribute,
	NSTopMarginDocumentAttribute, NSBottomMarginDocumentAttribute
      };
      NSNumber * __unsafe_unretained marginValues[4];
      int i;

      for (i = 0; i < 4; i++)
	marginValues[i] = [docAttributes objectForKey:marginAttributes[i]];
      for (i = 0; i < 2; i++)
	if (marginValues[i])
	  pageSize.width -= [marginValues[i] doubleValue];
      for (; i < 4; i++)
	if (marginValues[i])
	  pageSize.height -= [marginValues[i] doubleValue];

      pageSize.width = ceil (pageSize.width);
      pageSize.height = ceil (pageSize.height);
#if MAC_OS_X_VERSION_MIN_REQUIRED >= 101100
      [textContainer setSize:pageSize];
#else
      [textContainer setContainerSize:pageSize];
#endif

      [layoutManager setDelegate:self];
    }

  /* Fully lay out.  */
  glyphRange =
    [layoutManager
      glyphRangeForCharacterRange:(NSMakeRange (0, [textStorage length]))
	     actualCharacterRange:NULL];
  if (NSMaxRange (glyphRange) == 0)
    {
      MRC_RELEASE (self);
      self = nil;

      return self;
    }
  (void) [layoutManager
	   textContainerForGlyphAtIndex:(NSMaxRange (glyphRange) - 1)
			 effectiveRange:NULL];

  if (viewMode == 0)
    {
      NSRect rect = [layoutManager usedRectForTextContainer:textContainer];
      NSSize containerSize = NSMakeSize (ceil (NSMaxX (rect)),
					 ceil (NSMaxY (rect)));

#if MAC_OS_X_VERSION_MIN_REQUIRED >= 101100
      [textContainer setSize:containerSize];
#else
      [textContainer setContainerSize:containerSize];
#endif
    }

  documentAttributes = MRC_RETAIN (docAttributes);

  return self;
}

- (instancetype)initWithURL:(NSURL *)url
		    options:(NSDictionaryOf (NSString *, id) *)options
{
  NSAttributedString *attrString;
  NSDictionaryOf (NSAttributedStringDocumentAttributeKey, id) *docAttributes;

  attrString = [[NSAttributedString alloc]
		 initWithURL:url options:options
		 documentAttributes:&docAttributes error:NULL];
  if (attrString == nil)
    goto error;

  self = [self initWithAttributedString:attrString
		     documentAttributes:docAttributes];
  MRC_RELEASE (attrString);

  return self;

 error:
  self = [self init];
  MRC_RELEASE (self);
  self = nil;

  return self;
}

- (instancetype)initWithData:(NSData *)data
		     options:(NSDictionaryOf (NSString *, id) *)options
{
  NSAttributedString *attrString;
  NSDictionaryOf (NSAttributedStringDocumentAttributeKey, id) *docAttributes;

  attrString = [[NSAttributedString alloc]
		 initWithData:data options:options
		 documentAttributes:&docAttributes error:NULL];
  if (attrString == nil)
    goto error;

  self = [self initWithAttributedString:attrString
		     documentAttributes:docAttributes];
  MRC_RELEASE (attrString);

  return self;

 error:
  self = [self init];
  MRC_RELEASE (self);
  self = nil;

  return self;
}

#if !USE_ARC
- (void)dealloc
{
  [textStorage release];
  [documentAttributes release];
  [super dealloc];
}
#endif

- (NSLayoutManager *)layoutManager
{
  return [[textStorage layoutManagers] objectAtIndex:0];
}

- (NSUInteger)pageCount
{
  NSLayoutManager *layoutManager = [self layoutManager];

  return [[layoutManager textContainers] count];
}

+ (NSArrayOf (NSString *) *)supportedTypes
{
  return [NSAttributedString textTypes];
}

- (NSSize)integralSizeOfPageAtIndex:(NSUInteger)index
{
  NSLayoutManager *layoutManager = [self layoutManager];
  NSTextContainer *textContainer =
    [[layoutManager textContainers] objectAtIndex:index];

#if MAC_OS_X_VERSION_MIN_REQUIRED >= 101100
  return [textContainer size];
#else
  return [textContainer containerSize];
#endif
}

- (CGColorRef)copyBackgroundCGColorOfPageAtIndex:(NSUInteger)index
{
  NSColor *backgroundColor = [documentAttributes
			       objectForKey:NSBackgroundColorDocumentAttribute];

  /* `backgroundColor' might be nil, but that's OK.  */
  return [backgroundColor copyCGColor];
}

- (NSDictionaryOf (NSString *, id) *)documentAttributesOfPageAtIndex:(NSUInteger)index
{
  return documentAttributes;
}

- (void)drawPageAtIndex:(NSUInteger)index inRect:(NSRect)rect
	      inContext:(CGContextRef)ctx
{
  NSLayoutManager *layoutManager = [self layoutManager];
  NSTextContainer *textContainer =
    [[layoutManager textContainers] objectAtIndex:index];
#if MAC_OS_X_VERSION_MIN_REQUIRED >= 101100
  NSSize containerSize = [textContainer size];
#else
  NSSize containerSize = [textContainer containerSize];
#endif
  NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
  NSAffineTransform *transform = [NSAffineTransform transform];
  NSGraphicsContext *gcontext =
#if MAC_OS_X_VERSION_MIN_REQUIRED >= 101000
    [NSGraphicsContext graphicsContextWithCGContext:ctx flipped:YES];
#else
    [NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:YES];
#endif

  [NSGraphicsContext saveGraphicsState];
  NSGraphicsContext.currentContext = gcontext;
  [transform translateXBy:(NSMinX (rect)) yBy:(NSMaxY (rect))];
  [transform scaleXBy:(NSWidth (rect) / containerSize.width)
		  yBy:(- NSHeight (rect) / containerSize.height)];
  [transform concat];
  [layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:NSZeroPoint];
  [layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:NSZeroPoint];
  [NSGraphicsContext restoreGraphicsState];
}

- (void)layoutManager:(NSLayoutManager *)aLayoutManager
didCompleteLayoutForTextContainer:(NSTextContainer *)aTextContainer
		atEnd:(BOOL)flag
{
  if (aTextContainer == nil)
    {
      NSLayoutManager *layoutManager = [self layoutManager];
      NSTextContainer *firstContainer =
	[[layoutManager textContainers] objectAtIndex:0];
#if MAC_OS_X_VERSION_MIN_REQUIRED >= 101100
      NSTextContainer *textContainer = [[NSTextContainer alloc]
					 initWithSize:[firstContainer size]];
#else
      NSSize containerSize = [firstContainer containerSize];
      NSTextContainer *textContainer = [[NSTextContainer alloc]
					 initWithContainerSize:containerSize];
#endif

      [aLayoutManager addTextContainer:textContainer];
      MRC_RELEASE (textContainer);
    }
}

@end				// EmacsDocumentRasterizer




static void
document_cache_evict (void)
{
  NSDate *currentDate, *oldestTimestamp;

  if ([documentRasterizerCacheOldestTimestamp timeIntervalSinceNow]
      > - DOCUMENT_RASTERIZER_CACHE_DURATION)
    return;

  currentDate = [NSDate date];
  oldestTimestamp = nil;
  for (id key in [documentRasterizerCache allKeys])
    {
      NSDictionaryOf (NSString *, id) *value =
	[documentRasterizerCache objectForKey:key];
      NSDate *timestamp = [value objectForKey:@"timestamp"];

      if ([currentDate timeIntervalSinceDate:timestamp]
	  >= DOCUMENT_RASTERIZER_CACHE_DURATION)
	[documentRasterizerCache removeObjectForKey:key];
      else
	{
	  if (oldestTimestamp == nil)
	    oldestTimestamp = timestamp;
	  else
	    oldestTimestamp = [oldestTimestamp earlierDate:timestamp];
	}
    }
  MRC_RELEASE (documentRasterizerCacheOldestTimestamp);
  documentRasterizerCacheOldestTimestamp = MRC_RETAIN (oldestTimestamp);
}

static id <EmacsDocumentRasterizer>
document_cache_lookup (id key, NSDate *modificationDate)
{
  id <EmacsDocumentRasterizer> result = nil;

  if (documentRasterizerCache)
    {
      NSDictionaryOf (NSString *, id) *dictionary =
	[documentRasterizerCache objectForKey:key];

      if (dictionary
	  && (modificationDate == nil
	      || [modificationDate
		   isEqualToDate:[dictionary fileModificationDate]]))
	result = [dictionary objectForKey:@"document"];
    }

  return result;
}

static void
document_cache_set (id <NSCopying> key, id <EmacsDocumentRasterizer> document,
		    NSDate *modificationDate)
{
  NSDate *currentDate;
  NSDictionaryOf (NSString *, id) *value;

  if (documentRasterizerCache == nil)
    documentRasterizerCache = [[NSMutableDictionary alloc] init];

  currentDate = [NSDate date];
  value = [NSDictionary dictionaryWithObjectsAndKeys:document, @"document",
			currentDate, @"timestamp",
			/* The value of modificationDate might be nil,
			   but that's OK.  */
			modificationDate, NSFileModificationDate,
			nil];
  /* This might update an object containing the oldest time stamp.
     Even in such a case, documentRasterizerCacheOldestTimestamp still
     holds an older or equal date than the real oldest time stamp in
     the cache.  */
  [documentRasterizerCache setObject:value forKey:key];
  if (documentRasterizerCacheOldestTimestamp == nil)
    documentRasterizerCacheOldestTimestamp = MRC_RETAIN (currentDate);
}

static NSArrayOf (Class <EmacsDocumentRasterizer>) *
document_rasterizer_get_classes (void)
{
  return [NSArray arrayWithObjects:[EmacsPDFDocument class],
		  [EmacsDocumentRasterizer class],
		  nil];
}

static id <EmacsDocumentRasterizer>
document_rasterizer_create (id url_or_data,
			    NSDictionaryOf (NSString *, id) *options)
{
  BOOL isURL = [url_or_data isKindOfClass:[NSURL class]];

  for (Class class in document_rasterizer_get_classes ())
    {
      id <EmacsDocumentRasterizer> document;

      if (isURL)
	document = [((id <EmacsDocumentRasterizer>) [class alloc])
		     initWithURL:((NSURL *) url_or_data) options:options];
      else
	document = [((id <EmacsDocumentRasterizer>) [class alloc])
		     initWithData:((NSData *) url_or_data) options:options];

      if (document)
	return document;
    }

  return nil;
}




EmacsDocumentRef
mac_document_create_with_url (CFURLRef url, CFDictionaryRef options)
{
  NSURL *nsurl = (__bridge NSURL *) url;
  NSDictionaryOf (NSString *, id) *nsoptions =
    (__bridge NSDictionaryOf (NSString *, id) *) options;
  NSDate *modificationDate = nil;
  id <EmacsDocumentRasterizer> document = nil;

  if ([nsurl isFileURL])
    {
      [[nsurl URLByResolvingSymlinksInPath]
	getResourceValue:&modificationDate
		  forKey:NSURLAttributeModificationDateKey
		   error:NULL];
    }

  if (modificationDate)
    {
      NSDictionaryOf (NSString *, id) *key =
	[NSDictionary dictionaryWithObjectsAndKeys:nsurl, @"URL",
		      /* The value of nsoptions might be nil, but
			 that's OK.  */
		      nsoptions, @"options", nil];

      document = document_cache_lookup (key, modificationDate);
      if (document == nil)
	document = MRC_AUTORELEASE (document_rasterizer_create (nsurl,
								nsoptions));
      if (document)
	document_cache_set (key, document, modificationDate);
    }

  document_cache_evict ();

  return CF_BRIDGING_RETAIN (document);
}

EmacsDocumentRef
mac_document_create_with_data (CFDataRef data, CFDictionaryRef options)
{
  NSData *nsdata = (__bridge NSData *) data;
  NSDictionaryOf (NSString *, id) *nsoptions =
    (__bridge NSDictionaryOf (NSString *, id) *) options;
  NSDictionaryOf (NSString *, id) *key =
    [NSDictionary dictionaryWithObjectsAndKeys:nsdata, @"data",
		  /* The value of nsoptions might be nil, but that's
		     OK.  */
		  nsoptions, @"options", nil];
  id <EmacsDocumentRasterizer> document = document_cache_lookup (key, nil);

  if (document == nil)
    document = MRC_AUTORELEASE (document_rasterizer_create (nsdata, nsoptions));
  if (document)
    document_cache_set (key, document, nil);

  document_cache_evict ();

  return CF_BRIDGING_RETAIN (document);
}

size_t
mac_document_get_page_count (EmacsDocumentRef document)
{
  id <EmacsDocumentRasterizer> documentRasterizer =
    (__bridge id <EmacsDocumentRasterizer>) document;

  return [documentRasterizer pageCount];
}

void
mac_document_copy_page_info (EmacsDocumentRef document, size_t index,
			     CGSize *size, CGColorRef *background,
			     CFDictionaryRef *attributes)
{
  id <EmacsDocumentRasterizer> documentRasterizer =
    (__bridge id <EmacsDocumentRasterizer>) document;

  if (size)
    *size = NSSizeToCGSize ([documentRasterizer
			      integralSizeOfPageAtIndex:index]);
  if (background)
    *background = [documentRasterizer copyBackgroundCGColorOfPageAtIndex:index];
  if (attributes)
    *attributes = CF_BRIDGING_RETAIN ([documentRasterizer
					documentAttributesOfPageAtIndex:index]);
}

void
mac_document_draw_page (CGContextRef c, CGRect rect, EmacsDocumentRef document,
			size_t index)
{
  id <EmacsDocumentRasterizer> documentRasterizer =
    (__bridge id <EmacsDocumentRasterizer>) document;

  [documentRasterizer drawPageAtIndex:index inRect:(NSRectFromCGRect (rect))
			    inContext:c];
}
