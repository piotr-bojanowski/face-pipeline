/* Compute ssd_image of image wrt mask
 *
 *
 *
 */

#include <mex.h>
#include <stdlib.h>
#include <math.h>
#include <memory.h>

#define for if(0);else for

static void nssd_dispatch(double const* I, int w, int h,
		 double const* M, int mw, int mh,
		 int method, double* out);
static double compare(double* a, double const* b, int w, int h, int method);

struct method_ssd {
  enum { method = 0 };
};

struct method_nssd {
  enum { method = 1 };
};

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
   if (nrhs != 3)
      mexErrMsgTxt("vgg_ssd must have 3 arguments");

   if (!mxIsDouble(prhs[0]))
     mexErrMsgTxt("vgg_ssd takes only double arguments for I");
   if (!mxIsDouble(prhs[1]))
     mexErrMsgTxt("vgg_ssd takes only double arguments for M");
   if (!mxIsDouble(prhs[2]))
     mexErrMsgTxt("vgg_ssd takes only double arguments for Method");
   if (nlhs > 1)
     mexErrMsgTxt("Must have exactly one output.");

   mxArray const* I_ptr = prhs[0];
   mxArray const* M_ptr = prhs[1];
   mxArray const* method_ptr = prhs[2];

   int method = int(mxGetPr(method_ptr)[0]);

   int h = mxGetM(I_ptr);
   int w = mxGetN(I_ptr);

   int mh = mxGetM(M_ptr);
   int mw = mxGetN(M_ptr);

   int oh = h - mh + 1;
   int ow = w - mw + 1;

   if (oh < 1 || ow < 1)
     mexErrMsgTxt("vgg_ssd arguments have bad sizes: M  should be smaller than I");

   //printf("oi %d x %d  method = %d\n", oh, ow, method);
   
   // make output array
   mxArray* SSD_ptr = mxCreateDoubleMatrix(oh, ow, mxREAL);

   double const* I = mxGetPr(I_ptr);
   double const* M = mxGetPr(M_ptr);
   double* SSD = mxGetPr(SSD_ptr);

   nssd_dispatch(I, w, h, M, mw, mh, method, SSD);

   // assign output array
   plhs[0] = SSD_ptr;
}

// zero-based accessor
#define get(A,x,y,W,H) ((A)[(x)*(H) + (y)])

static inline double sqr(double x) { return x*x; }

static inline 
double compare(method_ssd*, double* a, double const* b, int w, int h)
{
  int n = w*h;
  double ssd = 0;
  for(int i = 0; i < n; ++i) {
    double d = b[i] - a[i];
    ssd += d*d;
  }
  return ssd;
}

static inline 
double compare(method_nssd*, double* a, double const* b, int w, int h)
{
  int n = w*h;

  // compute means
  double sum_a = 0;
  double sum_b = 0;
  for(int i = 0; i < n; ++i) {
    sum_a += a[i];
    sum_b += b[i];
  }
  double mean_a = sum_a / n;
  double mean_b = sum_b / n;

  // compute variances
  double sum_aa = 0;
  double sum_bb = 0;
  for(int i = 0; i < n; ++i) {
    sum_aa += sqr(a[i] - mean_a);
    sum_bb += sqr(b[i] - mean_b);
  }
  double var_a = sum_aa / (n-1);
  double var_b = sum_bb / (n-1);

    //    printf("means = %g,%g vars = %g,%g\n", mean_a, mean_b, var_a, var_b);

    // compute sum [(a_i - mean_a)/sigma_a - ditto_b]^2
  double scale_a = 1 / sqrt(var_a);
  double scale_b = 1 / sqrt(var_b);
  double nssd = 0;
  for(int i = 0; i < n; ++i) {
    double d = ((a[i] - mean_a) * scale_a - 
		(b[i] - mean_b) * scale_b);
    nssd += d*d;
  }
  return nssd;
}

template <class Method>
static void
nssd_template(double const* I, int w, int h,
	      double const* M, int mw, int mh,
	      double* out)
{
#define getI(x,y) get(I,x,y,w,h)
#define getM(x,y) get(M,x,y,mw,mh)
  int oh = h - mh + 1;
  int ow = w - mw + 1;

  double* tmp = (double*)malloc(mh*mw*sizeof (double));
  //  printf("[n%d]", Method::method);

  for(int x = 0; x < w-mw+1; ++x)
    for(int y = 0; y < h-mh+1; ++y) {
      double*p = tmp;
      for(int mx = 0; mx < mw; ++mx)
	for(int my = 0; my < mh; ++my) 
	  *p++ = getI(x+mx,y+my);
      get(out, x,y, ow,oh) = compare((Method*)0, tmp, M, mw, mh);
    }
  
  free(tmp);
}

static void
nssd_dispatch(double const* I, int w, int h,
     double const* M, int mw, int mh,
     int method,
     double* out)
{
  //  printf("[nssd%d]", method);
  if (method == method_ssd::method)
    nssd_template<method_ssd>(I, w, h, M, mw, mh, out);
  if (method == method_nssd::method)
    nssd_template<method_nssd>(I, w, h, M, mw, mh, out);
}

/////////////////////////////////////////////////////////////////////////////

#if 0
void ssd(double const* I, int w, int h,
	 double const* M, int mw, int mh,
	 double* out)
{
#define getI(x,y) get(I,x,y,w,h)
#define getM(x,y) get(M,x,y,mw,mh)
  int oh = h - mh + 1;
  int ow = w - mw + 1;

  double* p = out + oh*ow;
  while (p-- != out)
    *p = 255.0;

  for(int x = 0; x < w-mw+1; ++x)
    for(int y = 0; y < h-mh+1; ++y) {
      double ssd = 0;
      for(int mx = 0; mx < mw; ++mx)
	for(int my = 0; my < mh; ++my) {
	  //	  printf("%3d %3d %10g    %3d %3d %10g\n", x,y, getI(x,y), mx,my, getM(mx,my));
	  double  d = getI(x+mx,y+my) - getM(mx, my);
	  ssd += d*d;
	}
      get(out, x,y, ow,oh) = ssd;
    }
}
#endif

