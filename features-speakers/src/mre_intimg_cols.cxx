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

	if (nrhs != 2)
		mexErrMsgTxt("two input arguments expected");

	if (nlhs != 1)
		mexErrMsgTxt("one output argument expected");
	
	pX = prhs[0];

	if (!mxIsDouble(pX) || mxIsComplex(pX) || mxGetNumberOfDimensions(pX) != 2 || !mxGetNumberOfElements(pX))
		mexErrMsgTxt("input must be a non-empty double matrix");

	if (!mxIsDouble(prhs[1]) || mxIsComplex(prhs[1]) || mxGetNumberOfElements(prhs[1]) != 2)
		mexErrMsgTxt("argument 2 must be a double 2-vector");

	const double *sz = mxGetPr(prhs[1]);

	int	ih = (int) sz[0];
	int	iw = (int) sz[1];

	double	*X = mxGetPr(pX);
	int		n = mxGetN(pX);
	double	*Y;

	int	xd = ih * iw;
	int yd = (ih + 1) * (iw + 1);

	plhs[0] = mxCreateDoubleMatrix(yd, n, mxREAL);
	Y = mxGetPr(plhs[0]);

	Y += ih + 2;
	for (int i = 0; i < n; i++, X += xd, Y += yd)
	{
		const double	*xp;
		double	*yp;
		
		xp = X;
		yp = Y;
		for (int x = 0; x < iw; x++)
		{
			double s = *(xp++);

			*(yp++) = s;
			for (int y = 1; y < ih; y++, xp++, yp++)
				*yp = (s += *xp);
			yp++;
		}

		yp = Y + ih + 1;
		for (int x = 1; x < iw; x++)
		{
			for (int y = 0; y < ih; y++, yp++)
				*yp += *(yp - ih - 1);
			yp++;
		}
	}
}
