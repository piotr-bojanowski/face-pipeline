#include "mex.h"
#include <float.h>
#include <memory.h>

/**************************************************
 [ilist, dlist] = k_nearest_neighbour(X, Train, knn [, mind])
In: 
 X     - the data to test in columns:            double (ndim x npoints1)
 Train - the training data in columns:           double (ndim x npoints2)
 knn   - how many nearest neighbours to return:  double 1x1 
 mind  - minimum distance (deafault -1):         double 1x1 

 ilist - list of indices of nearest neighbours   int32  (knn x npoints1)
 dlist - !squared! distances                     double (knn x npoints1)

 Mark Everingham, me@robots.ox.ac.uk
 David Claus, dclaus@robots.ox.ac.uk
 Josef Sivic, josef@robots.ox.ac.uk

******************************************************/

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	int		nx, ny, dim;
        double          *X, *Train, *py;
	double          d, dmin;
	int		i, j, k, s, t;
	double          dist;
        
        double          *knnpd; 
        //int             *knnp; 
        int              knn;        
        
        
	double          *dlist;
	int             *ilist;

        double          mind=-1; //minimum distance
        double          *mindp; 

	if ((nrhs < 3) && (nrhs > 4))
		mexErrMsgTxt("Three or four input arguments expected.");        

	if (nlhs != 2)
		mexErrMsgTxt("Two output arguments expected.");

	if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) ||
		mxGetNumberOfDimensions(prhs[0]) != 2)
		mexErrMsgTxt("input 1 (X) must be a real double matrix");

	dim = mxGetM(prhs[0]);
	nx  = mxGetN(prhs[0]);

	if (!mxIsDouble(prhs[1]) || mxIsComplex(prhs[1]) ||
		mxGetNumberOfDimensions(prhs[1]) != 2 ||
		mxGetM(prhs[1]) != dim)
		mexErrMsgTxt("input 2 (Y) must be a real double matrix compatible with input 1 (X)");

	ny = mxGetN(prhs[1]); //% number of training points

        knnpd  = (double*) mxGetData(prhs[2]);       
        knn   = knnpd[0]; // converting double to int

        //minimum distance
        if (nrhs == 4)
          {
            mindp  = (double*) mxGetData(prhs[3]);       
            mind   = mindp[0]; 
          }

	plhs[0] = mxCreateNumericMatrix(knn, nx, mxINT32_CLASS, mxREAL);
	ilist = (int*) mxGetData(plhs[0]);

	plhs[1] = mxCreateNumericMatrix(knn, nx, mxDOUBLE_CLASS, mxREAL);
	dlist = (double*) mxGetData(plhs[1]);

	X     = (double*) mxGetData(prhs[0]);
	Train = (double*) mxGetData(prhs[1]);

        
        for (i=1; i<=nx; i++, X+= dim, dlist+=knn, ilist+=knn)
          {
            // Initialization
            for (s = 0;s < knn; s++)
              {
                dlist[s] = DBL_MAX;
                ilist[s] = -1;
              }
            
            dmin = DBL_MAX;
            for (j = 1, py = Train; j <= ny; j++, py += dim)
              {
                d = 0;
                for (k = 0; k < dim; k++)   // compute the distance for this sample
                  {
                    dist = X[k] - py[k];
                    d += dist * dist;
                    if (d > dmin) break;    // if it is already too far then don't bother with the remaining dimensions
                  }            
                
                if ((d < dmin) && (d > mind))  // save this sample if it is closer than the current list
                  {
                    s = 0;
                    while ((dlist[s] < d) && (s < knn)) s++; // find the place where to insert the point
                    for (t = 1; t < (knn-s); t++) // shift the points behind
                      {
                        //mexPrintf("s:%d  t:%d   knn:%d  j:%d   knn-t:%d    knn-t-1:%d   mind:%.2f \n",s,t,knn,j,knn-t, knn-t-1,mind);
                        dlist[knn-t] = dlist[knn-t-1];
                        ilist[knn-t] = ilist[knn-t-1];
                      }
                    dlist[s] = d;
                    ilist[s] = j;
                    dmin = dlist[knn-1];
                  }
              }           
          }
}
