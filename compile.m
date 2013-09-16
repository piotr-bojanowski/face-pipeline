
mex -outdir face-detection/private -O face-detection/src/resizef.cc
mex -outdir face-detection/private -O face-detection/src/reduce.cc
mex -outdir face-detection/private -O face-detection/src/shiftdt.cc
mex -outdir face-detection/private -O face-detection/src/features.cc
mex -outdir face-detection/private -O face-detection/src/fconvsse.cc -o fconv

mex -outdir tracking/private -O tracking/src/klt_goodfeats.cxx
mex -outdir tracking/private -O tracking/src/klt_trackfeat.cxx
mex -outdir tracking/private -O tracking/src/klt_mextrack.cxx
mex -outdir tracking/private -O tracking/src/mre_boxfilter.cxx
mex -outdir tracking/private -O tracking/src/mre_maxelem.cxx


% % mex -O fconvblas.cc -lmwblas -o fconv
% % mex -O fconvMT.cc -o fconv
% % mex -O fconv.cc