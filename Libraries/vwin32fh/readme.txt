My apologies for using Visual DataFlex Libraries in a very unconvential way.

For a minimum class library the standard file layout is a bit overkill.
Usually there are no data files, no IdeSrc required, no bitmaps etc.. just a few packages.

By putting the library meta data files in a subfolder and having the packages at the top, the focus stays on the code.

When adding the packages as a library, just select the .sws file version that is for your DataFlex version and it should all work as normal.

You can find the .sws files in the StudioLibrary folder (as is the other meta data stuff)