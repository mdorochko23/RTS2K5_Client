****************************************************
*** Added to RTS 1/31/18 per task [75375]
***
*** Move RPS request PDFs to the new deleted subfolder 
***
****************************************************


PARAMETERS n_rt, n_Tag
*--test settings
*!*	n_rt = 161963
*!*	n_Tag = 224

IF NVL(n_rt,0) = 0 OR NVL(n_Tag,0) = 0
	RETURN
ENDIF

LOCAL lcrpsbase, crpsfolder, cdelfoldname, csavfoldname

*--get the base path for the files being deleted
lcrpsbase=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","RpsPdfPath", "\")))
lcrpsfolder=lcrpsbase + PADL(ALLTRIM(STR(n_rt)),6,"0")+"\"+PADL(ALLTRIM(STR(n_Tag)),3,"0")

fso = CREATEOBJECT("Scripting.FileSystemObject")
IF  NOT fso.FolderExists(lcrpsfolder)
	RETURN &&.F.
ENDIF

*--delete thumb.db file if there is one
Delthumb(lcrpsfolder)

*--set the deleted folder path
cdelfoldname=ADDBS(lcrpsbase)+"deleted\"+ADDBS(PADL(ALLTRIM(STR(n_rt)),6,"0"))
IF NOT DIRECTORY(cdelfoldname)
	MD (cdelfoldname)
	IF NOT DIRECTORY(cdelfoldname)
		RETURN
	ENDIF
ENDIF
cdelfoldname=ADDBS(lcrpsbase)+"deleted\"+ADDBS(PADL(ALLTRIM(STR(n_rt)),6,"0"))+PADL(ALLTRIM(STR(n_Tag)),3,"0")

*--move the files to the deleted folder path
lmoved = .F.
IF DIRECTORY(lcrpsfolder) AND DIRECTORY(cdelfoldname)
	csavfoldname=ADDBS(lcrpsbase)+"deleted\"+ADDBS(PADL(ALLTRIM(STR(n_rt)),6,"0"))+;
		PADL(ALLTRIM(STR(n_Tag)),3,"0")+"_"+SYS(1)
	IF DIRECTORY(csavfoldname)
*-- if second delete of day, dump the earilier set of images that were  saved.
*		oFSO.DeleteFolder(csavfoldname)
		fso.DeleteFolder(csavfoldname)	&& 07/09/2020, zd #180772, JH.
	ENDIF
	lmoved=lfmove(lcrpsfolder,csavfoldname)
ENDIF

IF lmoved = .F. AND DIRECTORY(lcrpsfolder) AND NOT DIRECTORY(cdelfoldname)
	lmoved=lfmove(lcrpsfolder,cdelfoldname)
ENDIF

IF NOT lmoved
	gfmessage("Error deleteting scanned images. Contact IT department.")
	RETURN
ENDIF

********************************************************************************
PROCEDURE Delthumb
PARAMETERS cPAth
LOCAL oFs,lcFilename

lcFilename = ADDBS(cPAth) + "thumbs.db"

* Define constants for file attributes
#DEFINE FA_NORMAL 	0	&& Normal file. No attributes are set.
#DEFINE FA_READONLY  1	&& Read-only file.
#DEFINE FA_HIDDEN 	2	&& Hidden file.
#DEFINE FA_SYSTEM 	4	&& System file.
#DEFINE FA_ARCHIVE 	32	&& File has changed since last backup.

#DEFINE FA_VOLUME 	8 	&& Disk drive volume label. Attribute is read-only.
#DEFINE FA_DIRECTORY  16	&& Folder or directory. Attribute is read-only.
#DEFINE FA_ALIAS 	1024	&& Link or shortcut. Attribute is read-only.
#DEFINE FA_COMPRESSED 	2048	&& Compressed file. Attribute is read-only.

oFs = CREATEOBJECT("Scripting.FileSystemObject")
IF oFs.FileExists(lcFilename)
	oFile = oFs.GETFILE(lcFilename) && lcFile is the name of the file
* Flip hidden flag and delete
	oFile.ATTRIBUTES = BITXOR(oFile.ATTRIBUTES, FA_HIDDEN)
	oFs.DeleteFile(lcFilename)
ENDIF
RELEASE oFs

****************************************************
FUNCTION lfmove
PARAMETERS cDirEx,c_dirnew
lfmove = .F.
oFSO = CREATEOBJECT([Scripting.FileSystemObject])
*--move folder fails when going from one one drive to another. use copyfolder
*--the two paths can not end in the character "\". copy fails if either path has this ending character
oFSO.CopyFolder(cDirEx, c_dirnew, .T.)

IF DIRECTORY(c_dirnew)
	oFSO.DeleteFolder(cDirEx)
*!*		odir = oFSO.getfolder(cDirEx)
*!*		odir.DELETE
	lfmove = .T.
ELSE
	MESSAGE("could not move folder")
ENDIF

