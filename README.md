Description
=====================================

This code is the face detection, tracking and description used in our ICCV 2013 paper.
It includes the following parts :

- face detection
- shot boundary detection
- face tracking using klt
- facial landmark localization
- facial descriptor extraction
- mouth motion estimation
- face-track kernel computation

Dependencies
=====================================

This code uses vlfeat v0.9.14. This version of the package can be downloaded from :
http://www.vlfeat.org/download/vlfeat-0.9.14-bin.tar.gz

References
===================================== 

Runing the code
=====================================

To run this code you will need to have vl_feat working on your computer.
In the main.m script modify the vl_feat_path to point to the vl_setup script.

```
vl_feat_path = '/path/to/vl_setup';
```

Unpack the dumped frames to a dump directory and specify the path in the main.m script in the dump_dir variable.

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
