=== ATTENTION this is THE HAMMER 4.0 UNSTABLE ===

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

YOU REALLY SHOULD USE THE HAMMER 3.0 BRANCH FOR THE MOMENT!!
BREAKAGE WILL HAPPEN!!!

GET HAMMER 3.0 via Subversion from:

http://svn.vdf-guidance.com/TheHammer/branches/Hammer3

(You can use switch in the subversion client)

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


We try to supply a daily development zip bundle that contains everything you need to compile and run.
You do not need anything else as this zip to run and test.

You can find it here:
http://projects.vdf-guidance.com/projects/hammer/files 

Download the file that has a filename like:
Hammer4-development-alfa-2019mmdd.zip
where mm=month and dd=day of the date we created the snapshot of our development files.

The preview is still in alfa stage, but a lot of the real issues have been taken care of. 

If you want to compile Hammer 4.0 then use one of the Hammer4.xx.sws workspace files.
You should select Hammer4.src to compile.
You can use Hammer4-191.src to compile for DF19.1 etcetera.

Currently the lowest supported version of DataFlex that you can use to compile The Hammer 4.0 with is DataFlex 19.1
Supporting lower versions -for building the hammer 4.0- meant having to duplicate a lot of the windows structs that are already taken care of in DataFlex 19.1.
As we've got better things to do, DataFlex 19.1 it is.

The Hammer itself however is made to work with ALL versions of DataFlex, we just don't want to have to miss out on all the great
improvements in DataFlex for our development on the Hammer itself.

IMPORTANT: If you unzip the Hammer on top of an older version of the Hammer then you will have problems. 
Main issue is the file "Codemaxedit<username>.ini" 
in the data folder. Where <username> is your user/computer name.
Please remove (or rename) that file! You'll get all kind of errors on misbehavior if you leave an version of that file in place.
Actually EVERY time the CODEMAXEDIT.INI file in the program's folder gets updated you should remove that preferences file. 
Yes this is a pain, sorry.

=== Get the Hammer via Subversion ===

In order to check out a working copy of The Hammer 4.0 need to add some files 
that are not versioned. 
Data Files that contain knowledge about DataFlex are not under source control.
You should get a zip (see above) first and then update via subversion on top of those files.

The Hammer will not run without those data files!

--
Hammer time^H^H^H^H Team