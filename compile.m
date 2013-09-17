
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

mex -outdir features-speakers/private -O features-speakers/src/mre_maxelem.cxx
mex -outdir features-speakers/private -O features-speakers/src/mre_boxfilter.cxx
mex -outdir features-speakers/private -O features-speakers/src/mre_resizebilinear.cxx
mex -outdir features-speakers/private -O features-speakers/src/mre_intimg_cols.cxx
mex -outdir features-speakers/private -O features-speakers/src/mre_haarcascade_masked.cxx
mex -outdir features-speakers/private -O features-speakers/src/mre_disttransform.cxx
mex -outdir features-speakers/private -O features-speakers/src/klt_goodfeats.cxx
mex -outdir features-speakers/private -O features-speakers/src/klt_mextrack.cxx
mex -outdir features-speakers/private -O features-speakers/src/klt_trackfeat.cxx
mex -outdir features-speakers/private -O features-speakers/src/vgg_k_nearest_neighbour.cxx
mex -outdir features-speakers/private -O features-speakers/src/vgg_ssd_aux.cxx
mex -outdir features-speakers/private -O features-speakers/src/vgg_interp2.cxx
mex -outdir features-speakers/private -O features-speakers/src/patrick_hog.c
