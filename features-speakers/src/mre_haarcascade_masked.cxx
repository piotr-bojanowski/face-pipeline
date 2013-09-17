/*
	Copyright (c) 2006, Mark Everingham, University of Oxford
	All rights reserved.

	Redistribution and use in source and binary forms, with or without modification,
	are permitted provided that the following conditions are met:

	Redistributions of source code must retain the above copyright notice, this list
	of conditions and the following disclaimer.

	Redistributions in binary form must reproduce the above copyright notice,
	this list of conditions and the following disclaimer in the documentation
	and/or other materials provided with the distribution. 

	Neither the name of the University of Oxford nor the names of its contributors
	may be used to endorse or promote products derived from this software without
	specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
*/

#include "mex.h"
#include <math.h>
#include <string.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	bool			inplace;
	const mxArray	*pX;

	if (nrhs != 5)
		mexErrMsgTxt("5 input arguments expected");

	if (nlhs != 1)
		mexErrMsgTxt("one output argument expected");

	if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) || mxGetNumberOfDimensions(prhs[0]) != 2)
		mexErrMsgTxt("argument 1 must be a double matrix");

	const double	*II = mxGetPr(prhs[0]);
	int				ih = mxGetM(prhs[0]) - 1;
	int				iw = mxGetN(prhs[0]) - 1;
	
	if (!mxIsInt32(prhs[1]) || mxGetNumberOfElements(prhs[1]) != 2)
		mexErrMsgTxt("argument 2 must be an int32 2-vector");

	int	wh = ((const int *) mxGetData(prhs[1]))[0];
	int	ww = ((const int *) mxGetData(prhs[1]))[1];

	if (!mxIsInt32(prhs[2]) ||  mxGetNumberOfDimensions(prhs[2]) != 2)
		mexErrMsgTxt("argument 3 must be an int32 matrix");

	const int	*H = (const int *) mxGetData(prhs[2]);
	int			nf = mxGetM(prhs[2]);
	int			nh = mxGetN(prhs[2]);

	if (!mxIsDouble(prhs[3]) || mxIsComplex(prhs[3]) || mxGetNumberOfDimensions(prhs[3]) != 2 ||
		mxGetM(prhs[3]) != 2 || mxGetN(prhs[3]) != nh)
		mexErrMsgTxt("argument 4 must be a 2 x n double matrix compatible with argument 3");

	const double *TA = mxGetPr(prhs[3]);

	if (!mxIsLogical(prhs[4]) || mxGetNumberOfDimensions(prhs[4]) != 2 ||
		mxGetM(prhs[4]) != ih || mxGetN(prhs[4]) != iw)
		mexErrMsgTxt("argument 5 must be a logical matrix compatible with argument 1");

	const mxLogical *M = mxGetLogicals(prhs[4]);

	int	*HI = (int *) mxMalloc(nf * nh * sizeof(int));

	{
		// retarget haar features from window size to image size

		const int	*sp = H;
		int			*dp = HI;
		int			sign, ind, x, y;

		for (int h = 0; h < nh; h++)
		{
			for (int f = 0; f < nf; f++, sp++, dp++)
			{
				if (*sp == 0)
					*dp = 0;
				else
				{
					sign = (*sp < 0) ? -1 : 1;
					ind = (*sp < 0) ? -*sp : *sp;

					x = (ind - 1) / (wh + 1);
					y = ind - 1 - x * (wh + 1);

					*dp = (x * (ih + 1) + y + 1) * sign;
				}
			}
		}
	}

	plhs[0] = mxCreateDoubleMatrix(ih, iw, mxREAL);
	double	*Q = mxGetPr(plhs[0]);

	double ninf = -mxGetInf();

	for (int i = 0; i < iw * ih; i++)
		Q[i] = ninf;

	int	x1 = ww / 2, x2 = iw - 1 - ww / 2;
	int	y1 = wh / 2, y2 = ih - 1 - wh / 2;
	int	coloff = ih + y1 - y2 - 1;
	
	double *qp = Q + x1 * ih + y1;

	M += x1 * ih + y1;

	II--;
	for (int x = x1; x <= x2; x++, II += coloff + 1, qp += coloff, M += coloff)
	{
		for (int y = y1; y <= y2; y++, II++, qp++, M++)
		{
			if (*M)
			{
				const int		*hp = HI;
				const double	*tap = TA;
				double			q = 0;

				for (int h = 0; h < nh; h++, tap += 2)
				{
					if (*hp == 0)
					{
						// end of cascade level

						if (q < tap[1])
						{
							q = ninf;		// failed
							break;
						}
						if (h + 1 == nh)
						{
							q -= tap[1];	// final level passed
							break;
						}

						q = 0;				// intermediate level passed
						hp += nf;
					}
					else
					{
						double s = 0;

						for (int f = 0; f < nf; f++, hp++)
						{
							if (!*hp)
							{
								hp += nf - f;
								break;
							}

							if (*hp < 0)
								s -= II[-*hp];
							else
								s += II[*hp];
						}

						if (s >= tap[0])
							q += tap[1];
						else
							q -= tap[1];
					}
				}
				*qp = q;
			}
		}
	}

	mxFree(HI);
}
