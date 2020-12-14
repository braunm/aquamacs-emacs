

#include <config.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>


#include "lisp.h"
#include "frame.h"
#include "dispextern.h"

#define CACHE_IMAGE_TYPE(type, status)

#define HAVE_MACGUI 1

extern struct define_image_type (struct image_type *);

// REQUIRED FOR PREVIEW
static struct image_type *
lookup_image_type (Lisp_Object type)
{
  /* Types pbm and xbm are built-in and always available.  */
  if (EQ (type, Qpbm))
    return define_image_type (&pbm_type);

  if (EQ (type, Qxbm))
    return define_image_type (&xbm_type);

#if defined (HAVE_XPM) || defined (HAVE_NS)
  if (EQ (type, Qxpm))
    return define_image_type (&xpm_type);
#endif

#if defined (HAVE_JPEG)  || defined (HAVE_NS)
  if (EQ (type, Qjpeg))
    return define_image_type (&jpeg_type);
#endif

#if defined (HAVE_TIFF)  || defined (HAVE_NS)
  if (EQ (type, Qtiff))
    return define_image_type (&tiff_type);
#endif

#if defined (HAVE_GIF)  || defined (HAVE_NS)
  if (EQ (type, Qgif))
    return define_image_type (&gif_type);
#endif

#if defined (HAVE_PNG) ||  defined (HAVE_NS) || defined (USE_CAIRO)
  if (EQ (type, Qpng))
    return define_image_type (&png_type);
#endif

  #if defined (HAVE_RSVG)
  if (EQ (type, Qsvg))
    return define_image_type (&svg_type);
#endif


#if defined (HAVE_IMAGEMAGICK)
  if (EQ (type, Qimagemagick))
    return define_image_type (&imagemagick_type);
#endif


#ifdef HAVE_GHOSTSCRIPT
  if (EQ (type, Qpostscript))
    return define_image_type (&gs_type);
#endif

  return NULL;
}



// REQUIRED FOR PREVIEW
DEFUN ("init-image-library-io", Finit_image_library_io, Sinit_image_library_io, 1, 1, 0,
       doc: /* Initialize image library implementing image type TYPE.
Return non-nil if TYPE is a supported image type.

If image libraries are loaded dynamically (currently only the case on
MS-Windows), load the library for TYPE if it is not yet loaded, using
the library file(s) specified by `dynamic-library-alist'.  */)
  (Lisp_Object type)
{
  return lookup_image_type_io (type) ? Qt : Qnil;
}
