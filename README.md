
To run this code you will need to have vl_feat working on your computer.
In the main.m script modify the vl_feat_path to point to the vl_setup script.

'''vl_feat_path = '/path/to/vl_setup';'''

Unpack the dumped frames to a dump directory and specify the path in the main.m script in the dump_dir variable.

'''dump_dir = '/path/to/the/dump';'''

To compile the mex functions, run :

'''>>compile'''

To launch the demo of the pipeline on the short sequence of buffy, type :

'''>>main'''
