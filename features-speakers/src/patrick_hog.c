#ifndef _hog_c /* Copyright Bill.Triggs@inrialpes.fr */
#define _hog_c "$ 2006-07-20 10:38:52 GMT $"
/** NO WARRANTY. Use & distribute freely. Fixes/feedback welcome. **/
/*--------------------------------------------------------------------
 * CHANGES MADE:
 * - had to compile on unix machines with -lm
 * - had to download getopt.h and getopt.c such that it works on windows
 * - had to modify getopt.h and .c bcs otherwise index pointer to argv was never resetted
 *   (and hence calling this function a second time didn't work
 * - i do not know whay adx and ady were set to 1. set them to 0 and seems to work (get as many hog (x,y) desc as expected now).
 *--------------------------------------------------------------------*/


/*--------------------------------------------------------------------
  Histogram of Oriented Gradient (HOG) features. Look-up table version.

  For each pixel we map the x,y gradient directly to a pair of
  weighted votes into adjacent orientation channels using a big
  look-up table, then use another precompiled weight table to
  integrate the pixels orientation votes into the HOG blocks that it
  contributes to.
 --------------------------------------------------------------------*/
#include <stdio.h>
#include <math.h>
#include "mex.h"
#include "bips.h"

/*--------------------------------------------------------------------
  Packed value for a contribution to an orientation channel, as stored
  in the look up table. The table is large so we store values in 16
  bits for compactness. We allow up to 32 orientation channels (5 bits
  for the channel index), leaving 11 bits for the weighted vote
  corresponding to the given x,y gradient (LUT index). Votes are
  interpolated between two adjacent orientations so each table entry
  contains a pair of these values.
 --------------------------------------------------------------------*/

typedef u16 orientation_lut_value;
typedef struct { orientation_lut_value v[2]; } orientation_lut_entry;
#define ORIENTATION_LUT_MAXVAL ((1<<12)-1)
#define ORIENTATION_LUT_CHANNEL(x) ((x)&0x1F)
#define ORIENTATION_LUT_VALUE(x) ((x)>>5)
#define ORIENTATION_LUT_ENTRY(val,chan) (((u16)(val)<<5)|ORIENTATION_LUT_CHANNEL(chan))

/*--------------------------------------------------------------------
  Structure containing the spatial weightings to apply to a pixel's
  orientation vote when integrating it into a HOG descriptor that it
  belongs to.  We precalculate these for speed and store them in a
  table with one entry per relative pixel position in the HOG block.
  The pixel contributes to at most 4 adjacent spatial cells of the
  HOG, with spatial weightings that are typically defined by linear
  interpolation between the cell centres, perhaps with an optional
  overall Gaussian envelope that downweights the peripheral pixels of
  the HOG before integrating them. The "offset" values are indices
  into the output HOG vector.  The structure can be used for both
  R-HOG's and C-HOG's.
 --------------------------------------------------------------------*/

typedef struct { float weight[4]; short offset[4]; } hog_pixel_weights;

/* The offsets are used for indexing into the output vector in the
   inner loop of the method, and our vectors are organized with
   orientations innermost so the offsets are always scaled by norient
   before use. Usually we premultiply them by norient when creating
   the offset table, unless this causes overflow in a short...
*/
#if 1
# define PRESCALE_OFFSET(val,norient) ((val)*(norient))
# define POSTSCALE_OFFSET(val,norient) (val)
#else
# define PRESCALE_OFFSET(val,norient) (val)
# define POSTSCALE_OFFSET(val,norient) ((val)*(norient))
#endif

#define SET_INTERPOLATOR_WEIGHTS(w0,w1,x,interpolator)		\
  switch (interpolator) {					\
  case 1: /* linear interpolation - sum of coeffs is 1 */	\
     w0 = 1.0-x; w1 = x; break;					\
  case 2: /* sqrt interpolation - sum of squared coeffs is 1 	\
	     (more appropriate for L2 normalization of HoG) */	\
     w0 = sqrt(1.0-x); w1 = sqrt(x); break;			\
  case 3: /* cubic spline interpolation - sum of coeffs is 1 */	\
     w0 = SQ(1.0-x)*(2.0*x+1.0); w1 = SQ(x)*(3.0-2.0*x); break;	\
  default: /* shouldn't happen! */				\
     w0 = w1 = 0.0; break;					\
  }


/*--------------------------------------------------------------------
  Build orientation look up table. This converts signed gradient
  values (gx,gy) with components in the range [-gmax,gmax] into
  weighted votes into pairs of adjacent orientation channels. The
  gradient magnitude weighting functions implemented here have the
  form (g-g_dead)**a, or 0 if g<g_dead, where g=||(gx,gy)||, a is an
  exponent (usually 1) and g_dead is a dead zone radius that
  suppresses the vote if the norm of the gradient is too small. (The
  orientation estimate is unreliable for small g in any case). For
  orientation voting we use interpolation into the orientation bins on
  either side of the orientation of the given pixel gradient
  vector. Linear, square root and cubic spline interpolation are
  supported. Orientation voting can be either signed (range [0,360)
  degrees) or unsigned (range [0,180) degrees with larger values
  flipped through origin).
 --------------------------------------------------------------------*/
orientation_lut_entry*
new_orientation_lut(int gmax, int norient, int is_signed, double g_dead, double a, int interpolator)
{
   int dy=2*gmax+1, x,y;
   /* scale max weight to max value that can be stored in LUT */
   double norm = ORIENTATION_LUT_MAXVAL/(pow(sqrt(2)*gmax-g_dead,a));

   /* allocate and centre LUT */
   orientation_lut_entry *lut = ALLOC(orientation_lut_entry,dy*dy);
   if (!lut) return 0;
   lut += gmax*dy + gmax;

   /* fill table, one entry (a pair of adjacent orientation channel votes) 
      for each possible gradient vector */
   for (y=-gmax; y<=gmax; y++) {
      double gy = y;
      for (x=-gmax; x<=gmax; x++) {
	 double gx = x, g = sqrt(gx*gx+gy*gy)-g_dead, w0,w1;
	 int c0,c1;
	 if (g<=0.0) {
	    w0 = w1 = 0.0;
	    c0 = c1 = 0;
	 } else {
	    /* find orientation channels and weightings */
	    double orient = atan2(gy,gx), c;
	    if (is_signed) {
	       if (orient<0) orient += 2*M_PI;
	       c = orient/(2*M_PI);
	    } else {
	       if (orient<0) orient += M_PI;
	       c = orient/M_PI;
	    }
	    if (c>=1.0) c = 0.0;
	    c *= norient;
	    c -= (c0 = floor(c));
	    c1 = c0+1;
	    if (c1 == norient) c1 = 0;
	    SET_INTERPOLATOR_WEIGHTS(w0,w1,c,interpolator);
	    /* scale by gradient norm weighting */
	    g = norm*pow(g,a);
	    w0 *= g;
	    w1 *= g;
	 }
	 lut[x+y*dy].v[0] = ORIENTATION_LUT_ENTRY(w0,c0);
	 lut[x+y*dy].v[1] = ORIENTATION_LUT_ENTRY(w1,c1);	 
      }
   }
   return lut;
}

/*--------------------------------------------------------------------
  Precalculate a table of weights for integrating (the orientation
  votes of) each pixel of an R-HOG block into the R-HOG. There are
  xhog x yhog pixels and each has a set of at most 4 entries for the 4
  adjacent spatial cells that it contributes to. The weights are
  defined by linear interpolation between the cell centres with an
  optional overall Gaussian envelope to downweight the peripheral
  pixels of the HOG before integrating them.  The output cell centres
  are in a rectangular grid centred on the _centres_ of the input
  cells. These have size [0,xcell-1] x [0,ycell-1] so the centres for
  interpolation are at k*xcell+(xcell-1)/2.0 for some k, and similarly
  for y. xhog,yhog are the pixel widths of the full HOG block. The
  Gaussian width sigma is measured in pixels. Pixels less than 1/2 of
  a cell width from the border get the standard interpolated weights
  but contribute to only 1-2 output cells - the remaining weight is
  "lost off the edge" of the HOG.
 --------------------------------------------------------------------*/
hog_pixel_weights*
new_rhog_pixel_weights(int xhog, int yhog, int xcell, int ycell, int norient, double sigma, int interpolator) 
{
   int yblocks = yhog/ycell, xblocks = xhog/xcell, x,y;
   hog_pixel_weights* out = ALLOC(hog_pixel_weights,xhog*yhog);
   if (!out) return 0;
   for (y=0; y<yhog; y++) {
      float yc = (y-(ycell-1)/2.0)/ycell, wy = y-(yhog-1)/2.0, wy0,wy1;
      int yb = floor(yc);
      yc -= yb;	/* fractional coordinate relative to output cell grid */
      SET_INTERPOLATOR_WEIGHTS(wy0,wy1,yc,interpolator);

      for (x=0; x<xhog; x++) {
	 hog_pixel_weights *oyx = &out[x+y*xhog];
	 float xc = (x-(xcell-1)/2.0)/xcell, wx = x-(xhog-1)/2.0, wx0,wx1;
	 float w = (sigma>0.0)? exp(-(wx*wx+wy*wy)/(2.0*sigma*sigma)) : 1.0;
	 int xb = floor(xc), i=0;
	 xc -= xb;
	 SET_INTERPOLATOR_WEIGHTS(wx0,wx1,xc,interpolator);

	 /* Each pixel contributes to at most 4 HOG cells, whose
	    centres (for interpolation) are placed at the centre of
	    the corresponding HOG cell. The centres are respectively
	    above and to the left of, above and to the right of, below
	    and to the left of, below and to the right of, the
	    pixel. If the pixel is less than 1/2 pixel from the top
	    border there is no contribution to the "above" cells
	    because they are not in this HOG block (centres above the
	    top border of the block), etc. 
	 */
	 if (yb>=0 && wy0>0) { /* contrib to centres above pixel (none if pixel < 1/2 cell from top border) */
	    if (xb>=0 && wx0>0) { /* contrib to above left centre (none if pixel < 1/2 cell from left border) */
	       oyx->weight[i] = w*wy0*wx0;
	       oyx->offset[i] = PRESCALE_OFFSET(xb+yb*xblocks,norient);
	       i++;
	    }
	    if (xb<xblocks-1 && wx1>0) { /* contrib to above right centre (none if pixel < 1/2 cell from right border) */
	       oyx->weight[i] = w*wy0*wx1;
	       oyx->offset[i] = PRESCALE_OFFSET((xb+1)+yb*xblocks,norient);
	       i++;
	    }
	 }
	 if (yb<yblocks-1 && wy1>0) { /* contribs to centres below pixel (none if pixel < 1/2 cell from bottom border) */
	    if (xb>=0 && wx0>0) {  /* contrib to below left centre (none if pixel < 1/2 cell from left border) */
	       oyx->weight[i] = w*wy1*wx0;
	       oyx->offset[i] = PRESCALE_OFFSET(xb+(yb+1)*xblocks,norient);
	       i++;
	    }
	    if (xb<xblocks-1 && wx1>0) { /* contrib to above right centre (none if pixel < 1/2 cell from right border) */
	       oyx->weight[i] = w*wy1*wx1;
	       oyx->offset[i] = PRESCALE_OFFSET((xb+1)+(yb+1)*xblocks,norient);
	       i++;
	    }
	 }
	 while (i<4) { /* null out any unused entries */
	    oyx->weight[i] = 0;
	    oyx->offset[i] = 0;	 
	    i++;
	 }
      }
   }
   return out;
}


/*--------------------------------------------------------------------
  Accumulate a HOG descriptor vector given as input an "image" of
  pixel orientation votes and the HOG's pixel weight table.
 --------------------------------------------------------------------*/
void
accumulate_hog(int norient, int xhog, int yhog, int xcell, int ycell,
	       float out[/*norient*(xhog/xcell)*(yhog/ycell)*/],
	       orientation_lut_entry in[], int idx, int idy,
	       hog_pixel_weights weights[/*xhog*yhog*/])
{
   int yblocks = yhog/ycell, xblocks = xhog/xcell, ody = norient*xblocks, nhog = yblocks*ody, x,y;

   for (x=0; x<nhog; x++) /* clear output */
      out[x] = 0.0;
   
   /* Most of the time in a HoG computation is spent in the following
    * loop, so we optimize it.
    */
   for (y=0; y<yhog; y++) {
      for (x=0; x<xhog; x++) {
	 orientation_lut_entry *ixy = &in[x*idx+y*idy];
	 hog_pixel_weights *wxy = &weights[x+y*xhog];
	 float v0 = ORIENTATION_LUT_VALUE(ixy->v[0]), v1 = ORIENTATION_LUT_VALUE(ixy->v[1]);
	 int c0 = ORIENTATION_LUT_CHANNEL(ixy->v[0]), c1 = ORIENTATION_LUT_CHANNEL(ixy->v[1]);
#if 1
# if 1
#  define OUTPUT_HOG(I)						\
   float w=wxy->weight[I];					\
   if (w) {							\
      float *oi=out+POSTSCALE_OFFSET(wxy->offset[I],norient);	\
      oi[c0]+=w*v0;						\
      oi[c1]+=w*v1;						\
   }
# elif 1
#  define OUTPUT_HOG(I)					\
   float w=wxy->weight[I],*oi;				\
   if (!w) continue;					\
   oi=out+POSTSCALE_OFFSET(wxy->offset[I],norient);	\
   oi[c0]+=w*v0;					\
   oi[c1]+=w*v1;
# else
#  define OUTPUT_HOG(I)						\
   float w=wxy->weight[I];					\
   float* oi=out+POSTSCALE_OFFSET(wxy->offset[I],norient);	\
   oi[c0]+=w*v0;						\
   oi[c1]+=w*v1;
# endif
         {OUTPUT_HOG(0)}
         {OUTPUT_HOG(1)}
         {OUTPUT_HOG(2)}
         {OUTPUT_HOG(3)}
#elif 1
	 int i=0;
	 float w;
	 while (i<4 && (w=wxy->weight[i])) {
	    float* oi = out + POSTSCALE_OFFSET(wxy->offset[i],norient);
	    oi[c0] += w*v0;
	    oi[c1] += w*v1;
	    i++;
	 }
#else
	 int i=0;
	 while (i<4) {
	    float* oi = out + POSTSCALE_OFFSET(wxy->offset[i],norient);
	    float w=wxy->weight[i];
	    oi[c0] += w*v0;
	    oi[c1] += w*v1;
	    i++;
	 }
#endif
      }
   }
}

/*--------------------------------------------------------------------
  Simple normalization of a hog block with L_k norm.
  We special case L1 and L2 for speed.
 --------------------------------------------------------------------*/
void
normalize_hog(int nhog, float hog[], float k, float epsilon)
{
   double t;
   int i;
#if 1
   if (k==2.0) {
      t=nhog*SQ(epsilon);
      for (i=0; i<nhog; i++) 
	 t += SQ(hog[i]);
      t = 1.0/sqrt(t);
   } else if (k == 1.0) {
      t=nhog*epsilon;
      for (i=0; i<nhog; i++) 
#if 1
	 t += hog[i]; /* hog entries are +ve */
#else
	 t += fabs(hog[i]);
#endif
      t = 1.0/t;
   } else 
#endif      
   {
      t =nhog*pow(epsilon,k);
      for (i=0; i<nhog; i++) 
	 t += pow(hog[i],k);
      t = pow(t/nhog,-1.0/k);
   }
   for (i=0; i<nhog; i++) 
      hog[i] *= t;
}


/*--------------------------------------------------------------------
  Accumulate a grid of HOG descriptor vectors given as input an "image" of
  pixel orientation votes and the HOG's pixel weight table.
 --------------------------------------------------------------------*/
void
accumulate_hog_grid(int oxmax, int oymax, int xstride, int ystride, 
		    int norient, int xhog, int yhog, int xcell, int ycell,
		    float out[/*norient*(xhog/xcell)*(yhog/ycell)*oxmax*oymax*/],
		    orientation_lut_entry in[], int idx, int idy,
		    hog_pixel_weights weights[/*xhog*yhog*/])
{
   int nhog = norient*(xhog/xcell)*(yhog/ycell), x,y;
   for (y=0; y<oymax; y++) {
      for (x=0; x<oxmax; x++) {
	 accumulate_hog(norient,xhog,yhog,xcell,ycell,
			&out[nhog*(x+y*oxmax)],
			&in[x*xstride*idx+y*ystride*idy],idx,idy,
			weights);
      }
   }
}



/*--------------------------------------------------------------------
  
 --------------------------------------------------------------------*/
#include <stdlib.h>
#include "getopt.c"
#include "pnmio.c"
#define CELL_BORDER_COLOR 2


/*--------------------------------------------------------------------
  Use orientation vote LUT to convert gradient images to orientation
  vote images. For each pixel gradient, simply copies corresponding
  LUT entry into output image.
 --------------------------------------------------------------------*/
void
gradient_to_orientation_votes(int xmax, int ymax, 
			      orientation_lut_entry out[], int odx, int ody, 
			      const orientation_lut_entry lut[], int tdx, int tdy, 
			      short gx[], short gy[], int gdx, int gdy)
{
   int x,y;
   for (y=0; y<ymax; y++) {
      for (x=0; x<xmax; x++) {
	 int tx = gx[x*gdx+y*gdy], ty = gy[x*gdx+y*gdy];
	 out[x*odx+y*ody] = lut[tx*tdx+ty*tdy];
      }
   }
}

/*--------------------------------------------------------------------
  Utility to draw and output an image displaying the R-HOG values
 --------------------------------------------------------------------*/
void
draw_rhog(int norient, int xhog, int yhog, int xcell, int ycell,
	  float out[], int odx, int ody,
	  float hog[], int is_signed)
{
   int xblocks = xhog/xcell, yblocks = yhog/ycell, x,y,xb,yb,c;
   for (yb=0; yb<yblocks; yb++) {
      for (xb=0; xb<xblocks; xb++) {
	 float *o = &out[xb*xcell*odx+yb*ycell*ody];
	 float *h = &hog[norient*(xb+yb*xblocks)];
	 for (y=0; y<ycell; y++) {
	    for (x=0; x<xcell; x++) {
#if 0
	       o[x*odx+y*ody] = (x==0 || y==0)? CELL_BORDER_COLOR : 0;
#else
	       if (x==0 || y==0) o[x*odx+y*ody] = CELL_BORDER_COLOR;
#endif
	    }
	 }
	 for (c=0; c<norient; c++) {
	    if (h[c] > 0.0) {
	       double or = (is_signed)? (2*M_PI*c)/norient : (M_PI*c)/norient;
	       double co = cos(or), si = sin(or);
	       /* FIXME - very stupid line drawing routine - checks all pixels in block for distance to line */
	       for (y=0; y<ycell; y++) {
		  for (x=0; x<xcell; x++) {
		     if (fabs((y-(ycell-1)/2.0)*si + (x-(xcell-1)/2.0)*co) <0.72) 
			o[x*odx+y*ody] = MAX(o[x*odx+y*ody],h[c]);
		  }
	       }
	    }
	 }
      }
   }
}

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[] )
{	
	int argc, buflen, startPos, endPos, ii,i, numberColours;
	int counter, nrArgs, rowLen, colLen;
    char *argString;	
    u8* imgPointer;  /*range [0,255]*/
    char **argv;
    const int *dimVec;
    
    
    if (nrhs != 2)
		mexErrMsgTxt("error: 2 input argument expected.");
	if (nlhs != 1)
		mexErrMsgTxt("error: 1 output argument expected.");


    /* Get the length of the input string. */
    buflen = (mxGetM(prhs[0]) * mxGetN(prhs[0])) + 1;
    /* printf("buflen = %i\n", buflen); */
    
    
    /* Allocate memory for input and output strings. */
    argString = mxCalloc(buflen, sizeof(char)); 
    mxGetString(prhs[0], argString, buflen);    
    /* printf("argString = %s\n", argString); */
    
    
    /* count number of white space in argument */
    argc = 0;
    for (i = 0; i < buflen; i++)
    {                
        if (argString[i] == ' ')
            argc = argc+1;
    }   
    argc = argc+1; /* bcs program name counts too */
    argc = argc+1; /* bcs last option is not followed by whitespace */
    /* printf("argc = %i\n", argc); */
    
    
    
    /* now split up string into arguments */
    argv = (char**) mxMalloc(argc*sizeof(char*));	    
    startPos = 0;
    counter = 0;
    argv[counter] = (char*) mxMalloc(4*sizeof(char));	
    argv[counter] = "hog";
    startPos = 0;
    for (i = 0; i < buflen; i++)
    {
        if (argString[i] == ' ')
        {
            endPos = i-1;
            counter++;
            argv[counter] = (char*) mxMalloc((endPos-startPos+1+1)*sizeof(char));	

            for (ii=startPos; ii<=endPos;ii++)
            {            
                argv[counter][ii-startPos] = argString[ii]; 
            }                
            argv[counter][endPos-startPos+1] = '\0';                
            startPos = i+1;
        }                
    }
    
    
    /* add last argument (which is not followed by whitespace) */
    endPos = buflen-1;
    counter++;
    argv[counter] = (char*) mxMalloc((endPos-startPos+1+1)*sizeof(char));	   
    for (ii=startPos; ii<=endPos;ii++)
    {            
        argv[counter][ii-startPos] = argString[ii];         
    }                                                
    argv[counter][endPos-startPos+1] = '\0';
    
    if (argc!=counter+1) {
        printf("argc=%d; counter=%d\n",argc,counter);
        mexErrMsgTxt("UPS something wrong with the arguments\n");
    }
    
    /* get image */
    imgPointer = (u8*) mxGetPr(prhs[1]);
    dimVec = mxGetDimensions(prhs[1]);    
    if (mxGetNumberOfDimensions(prhs[1])==2) {
        rowLen = dimVec[0]; /* (int) mxGetM(prhs[1]); */
        colLen = dimVec[1]; /* (int) mxGetN(prhs[1]); */
        numberColours = 1;
    } else {
        rowLen = dimVec[1]; /* (int) mxGetM(prhs[1]); */
        colLen = dimVec[2]; /* (int) mxGetN(prhs[1]); */
        numberColours = dimVec[0];
    }
   /*  mexPrintf("numberColours=%d\n;rowLen=%d\n;colLen=%d\n",numberColours,rowLen,colLen); */
    
    /* call original main */
    mainOrig(argc, argv, plhs, rowLen, colLen, imgPointer, numberColours);	
    
   /* free argv using loops!	 */
   /*for (i = 0; i < argc; i++)
   {
       printf("free argv[%d] = %s %p\n",i,argv[i],argv[i]);
       mxFree(argv[i]);
   }	
   mxFree(argv);   
   */

}

int mainOrig(int argc, char** argv,  mxArray *plhs[], int rowLen, int colLen, u8* imgPointer, int numberColours)
{
   FILE *fpOut;
   double g_dead = 4, a = 1, sigma = 0.0, epsilon = 1e2, alpha=0.3, k = 2.0;
   int gmax = 255, norient = 8, is_signed = 0, orient_interp=1, spatial_interp=1,
      xcell=4, ycell=4, 
      xhog=xcell*4, yhog=ycell*4, xstride=xhog, ystride=yhog, 
      nhog, hogxmax, hogymax;
   orientation_lut_entry* olut = 0;
   int nx,ny,nc,x,y,i,dy,ii,c;
   int nsteps=1,adx=1,ady=1; /* steps for tests of aliasing */
   u8 *in, *out;
   short *gxy;
   orientation_lut_entry *orimage;
   hog_pixel_weights *weights;
   float *hog, *fout;
   extern char *optarg;  
   double* hogOutPtr;   
   int counter;
   int optind =1;
   const int printDebugInfo = 0;
   short gxy1,gxy0;
   
   
    /* debug: print out all arguments */
    if (printDebugInfo==1)
    {
        for (i=0; i<argc ;i++)
        {
            printf("argv[%i] = %s %p\n", i, argv[i],argv[i]);
        }   
    }

   while (  (i=getopt(argc,argv,"A:a:d:e:b:c:i:I:n:k:s:S:",&optind)) !=EOF ) 
   {
      if (printDebugInfo==1)
      {
          mexPrintf("i = %c \n",i);
      }
	   
      switch (i) {
      case 'b': 
	 i = sscanf(optarg,"%d",&xhog);
	 yhog = xhog;
	 break;       
      case 'c': 
	 i = sscanf(optarg,"%d",&xcell);
	 ycell = xcell;
	 break;       
      case 'i': 
	 i = sscanf(optarg,"%d",&spatial_interp);
	 break;       
      case 'I': 
	 i = sscanf(optarg,"%d",&orient_interp);
	 break;       
      case 'n': 
	 i = sscanf(optarg,"%d",&norient);
	 if (norient<0) {
	    is_signed = 1;
	    norient = -norient;
	 }
	 break;       
      case 's': 
	 i = sscanf(optarg,"%d",&xstride);
	 ystride = xstride;
	 break;       
      case 'k': 
	 i = sscanf(optarg,"%lf",&k); 
	 break;       
      case 'A': 
	 i = sscanf(optarg,"%lf",&alpha); 
	 break;       
      case 'S': 
	 i = sscanf(optarg,"%lf",&sigma); 
	 break;       
      case 'e': 
	 i = sscanf(optarg,"%lf",&epsilon); 
	 break;       
      case 'a': 
	 i = sscanf(optarg,"%lf",&a); 
	 break;       
      case 'd': 
	 i = sscanf(optarg,"%lf",&g_dead); 
	 break;       
      default:
      usage:
	 fprintf(stderr,"Usage: tst_hog ...options... input-image.pgm\n"
	       "\t[-c cell-size-pixels][-b block-size-pixels][-s block-stride-pixels]\n"
	       "\t[-n num-orientations(-ve=>signed)]\n"
	       "\t[-d gradient-dead-zone][-a gradient-weighting-power]\n"
	       "\t[-i spatial-interpolator(1:linear,2:sqrt,3:cubic-spline)]\n"
	       "\t[-I orientation-interpolator(1:linear,2:sqrt,3:cubic-spline)]\n"
	       "\t[-S gaussian-block-weighting-sigma]\n"
	       "\t[-k block-normalization-power][-e block-normalization-epsilon]\n"
	       "\t[-A alpha-for-hog-display]\n");
	 exit(1);
      }
   }


   if (argc<optind+1) goto usage;

   in = imgPointer;
   nx = rowLen;
   ny = colLen;
   nc = numberColours; /* 3; */
   
   /*
   if (!(in=fread_u8_pnm(argv[optind],&nx,&ny,&nc)))
   {
	  printf("return 1\n");
      return 1;
   }
   */

   

#if 0
   /* output image at a sequence of shifts to check on aliasing */
   nsteps = xcell;
   /* adx=1,ady=1; */
   adx=0,ady=0;   
#elif 0
   nsteps = 1000;
   adx=0,ady=0;   
#else
   nsteps = 1;
   adx=0,ady=0;   
#endif   
   dy = nx;   
   olut = new_orientation_lut(gmax,norient,is_signed,g_dead,a,orient_interp);      
   weights = new_rhog_pixel_weights(xhog,yhog,xcell,ycell,norient,sigma,spatial_interp);   
   gxy = ALLOC(short,nx*ny*2);
   fout = ALLOC(float,nx*ny);
   out = ALLOC(u8,nx*ny);
   orimage = ALLOC(orientation_lut_entry,nx*ny);
   nhog = norient*(xhog/xcell)*(yhog/ycell);
   if (!nhog) fatal("block size<cell size",0);
   hogxmax = (nx-xhog-adx*(nsteps-1))/xstride+1;
   hogymax = (ny-yhog-ady*(nsteps-1))/ystride+1;
   
   /* debug: print out all arguments */
   if (printDebugInfo==1)
   {
       mexPrintf("nx = %i \n",nx);
       mexPrintf("ny = %i \n",ny);
       mexPrintf("xhog = %i \n", xhog);
       mexPrintf("yhog = %i \n", yhog);
       mexPrintf("nsteps = %i \n", nsteps);
       mexPrintf("xstride = %i \n", xstride);
       mexPrintf("ystride = %i \n", ystride);
       mexPrintf("hogxmax = %i \n", hogxmax);
       mexPrintf("hogymax = %i \n", hogymax);
   }
   
   hog = ALLOC(float,hogxmax*hogymax*nhog);


   
  
   /* wrap with optional loop for tests of timing/aliasing */
   for (i=0; i<nsteps; i++) {

      /* Find gradient image. Values must be in [-gmax,gmax] !
       */
     for (y=0; y<ny; y++) {
	 for (x=0; x<nx; x++) {
        /* initialize with first color */
            c=0;
	        gxy0 = ((x==0)?    (in[c+(x+1)*nc+y*dy*nc]-in[c+x*nc+y*dy*nc]) :
		    		(x==nx-1)? (in[c+x*nc+y*dy*nc]-in[c+(x-1)*nc+y*dy*nc]) :
		    		           (in[c+(x+1)*nc+y*dy*nc]-in[c+(x-1)*nc+y*dy*nc]));
	 
	        gxy1 = ((y==0)?    (in[c+x*nc+(y+1)*dy*nc]-in[c+x*nc+y*dy*nc]) :
		    		(y==ny-1)? (in[c+x*nc+y*dy*nc]-in[c+x*nc+(y-1)*dy*nc]) :
		    		           (in[c+x*nc+(y+1)*dy*nc]-in[c+x*nc+(y-1)*dy*nc]));

	        gxy[2*(x+y*dy)+0] = gxy0;
	        gxy[2*(x+y*dy)+1] = gxy1;

	    for (c=1; c<nc; c++) {
	        gxy0 = ((x==0)?    (in[c+(x+1)*nc+y*dy*nc]-in[c+x*nc+y*dy*nc]) :
		    		(x==nx-1)? (in[c+x*nc+y*dy*nc]-in[c+(x-1)*nc+y*dy*nc]) :
		    		           (in[c+(x+1)*nc+y*dy*nc]-in[c+(x-1)*nc+y*dy*nc]));
	 
	        gxy1 = ((y==0)?    (in[c+x*nc+(y+1)*dy*nc]-in[c+x*nc+y*dy*nc]) :
		    		(y==ny-1)? (in[c+x*nc+y*dy*nc]-in[c+x*nc+(y-1)*dy*nc]) :
		    		           (in[c+x*nc+(y+1)*dy*nc]-in[c+x*nc+(y-1)*dy*nc]));

	        gxy[2*(x+y*dy)+0] = (gxy[2*(x+y*dy)+0]<gxy0) ? gxy0 : gxy[2*(x+y*dy)+0];
	        gxy[2*(x+y*dy)+1] = (gxy[2*(x+y*dy)+1]<gxy1) ? gxy1 : gxy[2*(x+y*dy)+1];
        }
	 }
     }
      /* Compute orientation-vote image using gradient images.
       */
      gradient_to_orientation_votes(nx,ny, 
				    orimage,1,dy, 
				    olut,1,2*gmax+1, 
				    gxy,gxy+1,2,2*dy);
      /* Accumulate HOG's from orientation-vote image.
       */
      accumulate_hog_grid(hogxmax,hogymax, xstride,ystride, 
			  norient, xhog,yhog, xcell,ycell,
			  hog,
			  orimage+i*(adx+dy*ady),1,dy,
			  weights);

      /* Normalize the HOG's */
      for (y=0; y<hogymax; y++) {
	 for (x=0; x<hogxmax; x++) {
	    float *h = &hog[nhog*(x+y*hogxmax)];
	    normalize_hog(nhog,h,k,epsilon);
	 }
      }
#if 0
      /* draw output image of hog */
      for (y=0; y<ny; y++) {
	 for (x=0; x<nx; x++) {
 	    fout[x+y*dy] = 0;
	 }
      }
      for (y=0; y<hogymax; y++) {
	 for (x=0; x<hogxmax; x++) {
	    float *h = &hog[nhog*(x+y*hogxmax)];
	    draw_rhog(norient, xhog,yhog, xcell,ycell,
		      &fout[x*xstride*1+y*ystride*dy],1,dy,
		      h,is_signed);
	 }
      } 

      for (y=0; y<ny; y++) {
	 for (x=0; x<nx; x++) {
	    int xi=x+i*adx, yi=y+i*ady;
	    float t = 32*fout[x+y*dy] + ((xi<nx && yi<ny)? alpha*in[xi+yi*dy] : 0);
	    out[x+y*dy] = u8_LIMIT(t);
	 }
      }
      {
	 char buf[1024];
	 sprintf(buf,"TMP%03d.pgm",i);
	 fwrite_u8_pnm(buf,nx,ny,nc, out,nc,nc*dy,1);
      }
#endif
#if 1

      
      plhs[0] = mxCreateNumericMatrix(hogxmax*hogymax*nhog,1, mxDOUBLE_CLASS, mxREAL);  /* hogxmax*hogymax*nhog */
      /* memcpy(mxGetPr(plhs[0]), hog, hogxmax*hogymax*nhog*sizeof(u8)); */
      
      
      /* save hog features to file */            
      hogOutPtr = (double*)mxGetPr(plhs[0]);
	  /* fpOut = fopen("win_hogOut.txt","w"); */
      counter = 0;
      for (y=0; y<hogymax; y++) 
	  {
		for (x=0; x<hogxmax; x++) 
		{
			float *h = &hog[nhog*(x+y*hogxmax)];
			{
				for (ii=0; ii<nhog; ii++)
				{
					/* fprintf(stdout,"%g ",h[ii]); */
					/* fprintf(fpOut,"%g ",h[ii]); */
                    hogOutPtr[counter++] = (double) h[ii];
				}			
				/* fprintf(stdout,"\n"); */
				/* fprintf(fpOut,"\n");	*/
			}
		}
      }
	  /* fclose(fpOut); */
      
#endif
   } /* end of timing */

   FREE(olut-(gmax+gmax*(2*gmax+1)));
   FREE(weights);
   FREE(gxy);
   FREE(fout);
   FREE(out);
   FREE(orimage);
   FREE(hog);      
   
   return 0;
}


#endif /*_hog_c */
