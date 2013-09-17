#include "mex.h"

typedef unsigned char uint8_t;

struct INTERP
{
	int off0, off1;
	float a0, a1;
};

void ResizeBilinear(const uint8_t *S, int sh, int sw, int sd, uint8_t *D, int dh, int dw, mxLogical interlace)
{
	if (interlace)
	{
		INTERP *interp = new INTERP[dh];
		int ylim = dh - 1;

		{
			float scale = (float) (sh / 2) / dh;

			for (int dy = 0; dy < dh; dy++)
			{
				float sy = dy * scale;
				int	isy = (int) sy;

				interp[dy].off0 = isy * 2;
				
				if (interp[dy].off0 == sh - 2)
				{
					ylim = dy;
					break;
				}

				interp[dy].off1 = interp[dy].off0 + 2;
				interp[dy].a1 = sy - isy;
				interp[dy].a0 = 1 - interp[dy].a1;			
			}
		}

		for (int d = 0; d < sd; d++, S += sh * sw)
		{
			float scale = (float) sw / dw;

			for (int dx = 0; dx < dw; dx++)
			{
				float sx = dx * scale;
				int isx = (int) sx;
				const uint8_t *Sx = S + isx * sh;
				
				if (isx == sw - 1)
				{
					INTERP *ip = interp;
					
					for (int dy = 0; dy < ylim; dy++, ip++)
						*(D++) = (uint8_t) (Sx[ip->off0] * ip->a0 + Sx[ip->off1] * ip->a1);
					for (int dy = ylim; dy < dh; dy++)
						*(D++) = Sx[sh - 2];
				}
				else
				{
					float a1 = sx - isx, a0 = 1 - a1;
					INTERP *ip = interp;
					
					for (int dy = 0; dy < ylim; dy++, ip++)
						*(D++) = (uint8_t) ((Sx[ip->off0] * ip->a0 + Sx[ip->off1] * ip->a1) * a0 +
											(Sx[ip->off0 + sh] * ip->a0 + Sx[ip->off1 + sh] * ip->a1) * a1);

					for (int dy = ylim; dy < dh; dy++)
						*(D++) = Sx[sh - 2];
				}			
			}
		}

		delete[] interp;
	}
	else
	{
		mexErrMsgTxt("unsupported");
	}
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	if (nrhs != 4)
		mexErrMsgTxt("4 input arguments expected");
	if (nlhs != 1)
		mexErrMsgTxt("1 output argument expected");

	if (mxIsComplex(prhs[0]) ||
		(!mxIsUint8(prhs[0])) ||
		mxGetNumberOfDimensions(prhs[0]) != 3)
		mexErrMsgTxt("argument 1 (I) must be a uint8 h x w x 3 array");
	int sh = mxGetDimensions(prhs[0])[0], sw = mxGetDimensions(prhs[0])[1], sd = mxGetDimensions(prhs[0])[2];

	int dh;
	if (mxIsComplex(prhs[1]) || !mxIsDouble(prhs[1]) || mxGetNumberOfElements(prhs[1]) != 1 ||
		(dh = (int) mxGetScalar(prhs[1])) != mxGetScalar(prhs[1]))
		mexErrMsgTxt("argument 2 (h) must be an integer-valued double scalar");

	int dw;
	if (mxIsComplex(prhs[2]) || !mxIsDouble(prhs[2]) || mxGetNumberOfElements(prhs[2]) != 1 ||
		(dw = (int) mxGetScalar(prhs[2])) != mxGetScalar(prhs[2]))
		mexErrMsgTxt("argument 3 (w) must be an integer-valued double scalar");

	if (mxIsComplex(prhs[3]) || !mxIsLogical(prhs[3]) || mxGetNumberOfElements(prhs[3]) != 1)
		mexErrMsgTxt("argument 4 (interlace) must be a logical");
	mxLogical interlace = *mxGetLogicals(prhs[3]);

	int dims[3] = {dh, dw, sd};
	plhs[0] = mxCreateNumericArray(3, dims, mxGetClassID(prhs[0]), mxREAL);

	switch (mxGetClassID(prhs[0]))
	{
		case mxUINT8_CLASS:
			ResizeBilinear((const uint8_t *) mxGetData(prhs[0]),
							sh, sw, sd,
							(uint8_t *) mxGetData(plhs[0]),
							dh, dw,
							interlace);
			break;
	}
}
