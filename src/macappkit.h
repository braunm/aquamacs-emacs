/* Definitions and headers for AppKit framework on macOS.
   Copyright (C) 2008-2020  YAMAMOTO Mitsuharu

This file is part of GNU Emacs Mac port.

GNU Emacs Mac port is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

GNU Emacs Mac port is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Emacs Mac port.  If not, see <http://www.gnu.org/licenses/>.  */

#undef Z
#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <Quartz/Quartz.h>
#import <QuartzCore/QuartzCore.h>
#import <IOKit/graphics/IOGraphicsLib.h>
#import <OSAKit/OSAKit.h>
#define Z (current_buffer->text->z)

#ifndef NSFoundationVersionNumber10_8_3
#define NSFoundationVersionNumber10_8_3 945.16
#endif

#if MAC_OS_X_VERSION_MAX_ALLOWED < 101300
typedef double NSAppKitVersion;
#ifndef NSAppKitVersionNumber10_6
static const NSAppKitVersion NSAppKitVersionNumber10_6 = 1038;
#endif
#ifndef NSAppKitVersionNumber10_7
static const NSAppKitVersion NSAppKitVersionNumber10_7 = 1138;
#endif
#ifndef NSAppKitVersionNumber10_8
static const NSAppKitVersion NSAppKitVersionNumber10_8 = 1187;
#endif
#ifndef NSAppKitVersionNumber10_9
static const NSAppKitVersion NSAppKitVersionNumber10_9 = 1265;
#endif
#ifndef NSAppKitVersionNumber10_10_Max
static const NSAppKitVersion NSAppKitVersionNumber10_10_Max = 1349;
#endif
#ifndef NSAppKitVersionNumber10_11
static const NSAppKitVersion NSAppKitVersionNumber10_11 = 1404;
#endif
#ifndef NSAppKitVersionNumber10_12
static const NSAppKitVersion NSAppKitVersionNumber10_12 = 1504;
#endif
#endif
#if MAC_OS_X_VERSION_MAX_ALLOWED < 101400
static const NSAppKitVersion NSAppKitVersionNumber10_13 = 1561;
#endif
#if MAC_OS_X_VERSION_MAX_ALLOWED < 101500
static const NSAppKitVersion NSAppKitVersionNumber10_14 = 1671;
#endif

#if MAC_OS_X_VERSION_MAX_ALLOWED >= 101500 || (WK_API_ENABLED && MAC_OS_X_VERSION_MIN_REQUIRED >= 101300)
#define USE_WK_API 1
#endif

#ifndef USE_ARC
#if defined (__clang__) && __has_feature (objc_arc)
#define USE_ARC 1
#endif
#endif

#if !USE_ARC
#ifndef __unsafe_unretained
#define __unsafe_unretained
#endif
#ifndef __autoreleasing
#define __autoreleasing
#endif
#endif

#if !__has_feature (objc_instancetype)
typedef id instancetype;
#endif

#if MAC_OS_X_VERSION_MAX_ALLOWED >= 101100 && __has_feature (objc_generics)
#define NSArrayOf(ObjectType)		NSArray <ObjectType>
#define NSMutableArrayOf(ObjectType)	NSMutableArray <ObjectType>
#define NSSetOf(ObjectType)		NSSet <ObjectType>
#define NSMutableSetOf(ObjectType)	NSMutableSet <ObjectType>
#define NSDictionaryOf(KeyT, ObjectT)	NSDictionary <KeyT, ObjectT>
#define NSMutableDictionaryOf(KeyT, ObjectT) NSMutableDictionary <KeyT, ObjectT>
#else
#define NSArrayOf(ObjectType)		NSArray
#define NSMutableArrayOf(ObjectType)	NSMutableArray
#define NSSetOf(ObjectType)		NSSet
#define NSMutableSetOf(ObjectType)	NSMutableSet
#define NSDictionaryOf(KeyT, ObjectT)	NSDictionary
#define NSMutableDictionaryOf(KeyT, ObjectT) NSMutableDictionary
#define __kindof
#endif

#ifndef NS_NOESCAPE
#define NS_NOESCAPE CF_NOESCAPE
#endif

#if MAC_OS_X_VERSION_MAX_ALLOWED < 101200
typedef NSString * NSKeyValueChangeKey;
#endif

#if MAC_OS_X_VERSION_MAX_ALLOWED < 101201
typedef NSString * NSTouchBarItemIdentifier;
#endif

#if MAC_OS_X_VERSION_MAX_ALLOWED < 101300
typedef NSString * NSAccessibilityAttributeName;
typedef NSString * NSAccessibilityActionName;
typedef NSString * NSAccessibilityNotificationName;
typedef NSString * NSAccessibilityParameterizedAttributeName;
typedef NSString * NSAppearanceName;
typedef NSString * NSAttributedStringDocumentAttributeKey;
typedef NSString * NSColorListName;
typedef NSString * NSColorName;
typedef NSString * NSPasteboardType;
typedef NSString * NSPasteboardName;
typedef NSString * NSToolbarIdentifier;
typedef NSString * NSToolbarItemIdentifier;
typedef NSString * NSWindowTabbingIdentifier;
#endif



/* Categories for existing classes.  */

@interface NSData (Emacs)
- (Lisp_Object)lispString;
@end

@interface NSString (Emacs)
+ (instancetype)stringWithLispString:(Lisp_Object)lispString;
+ (instancetype)stringWithUTF8LispString:(Lisp_Object)lispString;
+ (instancetype)stringWithUTF8String:(const char *)bytes fallback:(BOOL)flag;
- (Lisp_Object)lispString;
- (Lisp_Object)UTF8LispString;
- (Lisp_Object)UTF16LispString;
- (NSArrayOf (NSString *) *)componentsSeparatedByCamelCasingWithCharactersInSet:(NSCharacterSet *)separator;
@end



@interface NSAttributedString (Emacs)
- (Lisp_Object)UTF16LispString;
@end

@interface NSColor (Emacs)
+ (NSColor *)colorWithXColorPixel:(unsigned long)pixel;
- (CGColorRef)copyCGColor;
@end

@interface NSImage (Emacs)
+ (NSImage *)imageWithCGImage:(CGImageRef)cgImage exclusive:(BOOL)flag;
@end

/* @interface NSApplication (Emacs) */
/* - (void)postDummyEvent; */
/* - (void)runTemporarilyWithBlock:(void (^)(void))block; */
/* @end */

/* @interface NSScreen (Emacs) */
/* + (NSScreen *)screenContainingPoint:(NSPoint)aPoint; */
/* + (NSScreen *)closestScreenForRect:(NSRect)aRect; */
/* - (BOOL)containsDock; */
/* - (BOOL)canShowMenuBar; */
/* @end */

/* @interface NSWindow (Emacs) */
/* - (Lisp_Object)lispFrame; */
/* @end */

/* @interface NSCursor (Emacs) */
/* + (NSCursor *)cursorWithThemeCursor:(ThemeCursor)shape; */
/* @end */

/* #if MAC_OS_X_VERSION_MIN_REQUIRED < 101000 */
/* /\* Workarounds for memory leaks on OS X 10.9.  *\/ */
/* @interface NSApplication (Undocumented) */
/* - (void)_installMemoryPressureDispatchSources; */
/* - (void)_installMemoryStatusDispatchSources; */
/* @end */
/* #endif */

/* @interface EmacsApplication : NSApplication */
/* @end */

/* @interface EmacsPosingWindow : NSWindow */
/* + (void)setup; */
/* @end */

/* Class for delegate for NSApplication.  It also becomes the target
   of several actions such as those from EmacsMainView, menus,
   dialogs, and actions/services bound in the mac-apple-event
   keymap.  */

/* @interface EmacsController : NSObject <NSApplicationDelegate, NSUserInterfaceValidations> */
/* { */
/*   /\* Points to HOLD_QUIT arg passed to read_socket_hook.  *\/ */
/*   struct input_event *hold_quit; */

/*   /\* Number of events stored during a */
/*      handleQueuedEventsWithHoldingQuitIn: call.  *\/ */
/*   int count; */

/*   /\* Whether to generate a HELP_EVENT at the end of handleOneNSEvent: */
/*      call.  *\/ */
/*   int do_help; */

/*   /\* Non-zero means that a HELP_EVENT has been generated since Emacs */
/*    start.  *\/ */
/*   bool any_help_event_p; */

/*   /\* The frame on which a HELP_EVENT occurs.  *\/ */
/*   struct frame *emacsHelpFrame; */

/*   /\* The item selected in the popup menu.  *\/ */
/*   int menuItemSelection; */

/*   /\* Non-nil means left mouse tracking has been suspended and will be */
/*      resumed when this block is called.  *\/ */
/*   void (^trackingResumeBlock)(void); */

/*   /\* Whether a service provider for Emacs is registered as of */
/*      applicationWillFinishLaunching: or not.  *\/ */
/*   BOOL serviceProviderRegistered; */

/*   /\* Whether the application should update its presentation options */
/*      when it becomes active next time.  *\/ */
/*   BOOL needsUpdatePresentationOptionsOnBecomingActive; */

/*   /\* Whether conflicting Cocoa's text system key bindings (e.g., C-q) */
/*      are disabled or not.  *\/ */
/*   BOOL conflictingKeyBindingsDisabled; */

/*   /\* Saved key bindings with or without conflicts (currently, those */
/*      for writing direction commands on Mac OS X 10.6).  *\/ */
/*   NSDictionaryOf (NSString *, NSString *) */
/*     *keyBindingsWithConflicts, *keyBindingsWithoutConflicts; */

/*   /\* Help topic that the user selected using Help menu search.  *\/ */
/*   id selectedHelpTopic; */

/*   /\* Search string for which the user selected "Show All Help */
/*      Topics".  *\/ */
/*   NSString *searchStringForAllHelpTopics; */

/* #if MAC_OS_X_VERSION_MIN_REQUIRED < 101100 */
/*   /\* Date of last flushWindow call.  *\/ */
/*   NSDate *lastFlushDate; */

/*   /\* Timer for deferring flushWindow call.  *\/ */
/*   NSTimer *flushTimer; */

/*   /\* Set of windows whose flush is deferred.  *\/ */
/*   NSMutableSetOf (NSWindow *) *deferredFlushWindows; */
/* #endif */

/*   /\* Set of key paths for which NSApp is observed via the */
/*      `application-kvo' subkeymap in mac-apple-event-map.  *\/ */
/*   NSSetOf (NSString *) *observedKeyPaths; */
/* } */
/* - (void)updateObservedKeyPaths; */
/* - (int)getAndClearMenuItemSelection; */
/* - (void)storeInputEvent:(id)sender; */
/* - (void)setMenuItemSelectionToTag:(id)sender; */
/* - (void)storeEvent:(struct input_event *)bufp; */
/* - (void)setTrackingResumeBlock:(void (^)(void))block; */
/* - (NSTimeInterval)minimumIntervalForReadSocket; */
/* - (int)handleQueuedNSEventsWithHoldingQuitIn:(struct input_event *)bufp; */
/* - (void)cancelHelpEchoForEmacsFrame:(struct frame *)f; */
/* - (BOOL)conflictingKeyBindingsDisabled; */
/* - (void)setConflictingKeyBindingsDisabled:(BOOL)flag; */
/* - (void)flushWindow:(NSWindow *)window force:(BOOL)flag; */
/* - (void)updatePresentationOptions; */
/* - (void)showMenuBar; */
/* @end */

/* /\* Like NSWindow, but allows suspend/resume resize control tracking.  *\/ */

/* @interface EmacsWindow : NSWindow <NSMenuItemValidation> */
/* { */
/*   /\* Left mouse up event used for suspending resize control */
/*      tracking.  *\/ */
/*   NSEvent *mouseUpEvent; */

/*   /\* Pointer location of the left mouse down event that initiated the */
/*      current resize control tracking session.  The value is in the */
/*      base coordinate system of the window.  *\/ */
/*   NSPoint resizeTrackingStartLocation; */

/*   /\* Window size when the current resize control tracking session was */
/*      started.  *\/ */
/*   NSSize resizeTrackingStartWindowSize; */

/*   /\* Whether the call to setupResizeTracking: is suspended for the */
/*      next left mouse down event.  *\/ */
/*   BOOL setupResizeTrackingSuspended; */

/*   /\* Whether the window should be made visible when the application */
/*      gets unhidden next time.  *\/ */
/*   BOOL needsOrderFrontOnUnhide; */

/*   /\* Positive values mean the usual -constrainFrameRect:toScreen: */
/*      behavior is suspended.  *\/ */
/*   char constrainingToScreenSuspensionCount; */
/* } */
/* - (void)suspendResizeTracking:(NSEvent *)event */
/* 	   positionAdjustment:(NSPoint)adjustment; */
/* - (void)resumeResizeTracking; */
/* - (BOOL)needsOrderFrontOnUnhide; */
/* - (void)setNeedsOrderFrontOnUnhide:(BOOL)flag; */
/* - (void)suspendConstrainingToScreen:(BOOL)flag; */
/* - (void)exitTabGroupOverview; */
/* @end */

/* @interface EmacsFullscreenWindow : EmacsWindow */
/* @end */

@interface NSObject (EmacsWindowDelegate)
- (BOOL)window:(NSWindow *)sender shouldForwardAction:(SEL)action to:(id)target;
- (NSRect)window:(NSWindow *)sender willConstrainFrame:(NSRect)frameRect
	toScreen:(NSScreen *)screen;
@end


/* Class for delegate of NSWindow and NSToolbar (see its Toolbar
   category declared later).  It also becomes that target of
   frame-dependent actions such as those from font panels.  */







/* Protocol for document rasterization.  */

@protocol EmacsDocumentRasterizer <NSObject>
- (instancetype)initWithURL:(NSURL *)url
		    options:(NSDictionaryOf (NSString *, id) *)options;
- (instancetype)initWithData:(NSData *)data
		     options:(NSDictionaryOf (NSString *, id) *)options;
+ (NSArrayOf (NSString *) *)supportedTypes;
- (NSUInteger)pageCount;
- (NSSize)integralSizeOfPageAtIndex:(NSUInteger)index;
- (CGColorRef)copyBackgroundCGColorOfPageAtIndex:(NSUInteger)index;
- (NSDictionaryOf (NSString *, id) *)documentAttributesOfPageAtIndex:(NSUInteger)index;
- (void)drawPageAtIndex:(NSUInteger)index inRect:(NSRect)rect
	      inContext:(CGContextRef)ctx;
@end

/* Class for PDF rasterization.  */

@interface EmacsPDFDocument : PDFDocument <EmacsDocumentRasterizer>
@end

/* Class for document rasterization other than PDF.  It also works as
   the layout manager delegate when rasterizing a multi-page
   document.  */

@interface EmacsDocumentRasterizer : NSObject <EmacsDocumentRasterizer, NSLayoutManagerDelegate>
{
  /* The text storage and document attributes for the document to be
     rasterized.  */
  NSTextStorage *textStorage;
  NSDictionaryOf (NSAttributedStringDocumentAttributeKey, id)
    *documentAttributes;
}
- (instancetype)initWithAttributedString:(NSAttributedString *)anAttributedString
		      documentAttributes:(NSDictionaryOf (NSString *, id) *)docAttributes;
@end
