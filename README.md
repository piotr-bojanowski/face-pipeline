Description (26 Sep 2013)
=====================================

This code implements the face detection, tracking and descriptor extraction pipeline used in [1].
It includes the following parts :

1. face detection
2. shot boundary detection
3. face tracking using point trajectories
4. facial landmark localization
5. facial descriptor extraction
6. mouth motion estimation
7. face-track kernel computation

The face detection (1.) is based on and includes pre-trained models from [3]. The rest of the pipeline is based on and includes code as well as pre-trained models from [2].

Acknowledgements: We graciously thank the authors of the previous code releases for making them available.


Dependencies
=====================================

This code uses vlfeat v0.9.14. This version of the package can be downloaded from :
http://www.vlfeat.org/download/vlfeat-0.9.14-bin.tar.gz


References
=====================================

[1] P. Bojanowski, F. Bach, I. Laptev, J. Ponce, C. Schmid, and J. Sivic: Finding actors and actions in movies, ICCV 2013

[2] J. Sivic, M. Everingham and A. Zisserman. "Who are you?" : Learning person specific classifiers from video. CVPR 2009.

[3] X. Zhu, D. Ramanan. Face detection, pose estimation and landmark localization in the wild. CVPR 2012.



Running the code
=====================================

To run this code you will need to have vl_feat working on your computer.
In the main.m script modify the vl_feat_path to point to the vl_setup script.

```
vl_feat_path = '/path/to/vl_setup';
```

Unpack the dumped frames to a dump directory and specify the path in
the main.m script in the dump_dir variable.

```
dump_dir = '/path/to/the/dump';
```

To compile the mex functions, run :

```
>>compile
```

To launch the demo of the pipeline on the short sequence of buffy, type :

```
>>main
```
