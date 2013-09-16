
mex -outdir face-detection/private -O face-detection/src/resizef.cc
mex -outdir face-detection/private -O face-detection/src/reduce.cc
mex -outdir face-detection/private -O face-detection/src/shiftdt.cc
mex -outdir face-detection/private -O face-detection/src/features.cc
mex -outdir face-detection/private -O face-detection/src/fconvsse.cc -o fconv

% % 1) multithreaded convolution using blas
% % mex -O fconvblas.cc -lmwblas -o fconv
% % 2) mulththreaded convolution without blas
% % mex -O fconvMT.cc -o fconv
% % 3) basic convolution, very compatible
% % mex -O fconv.cc
