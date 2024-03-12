PARAMETERS nlrs,ntag
LOCAL c_padlrs,c_padtag,c_basefolder,ofiles,ofolders,fc,frt,ftag,;
c_datefolder,ortfolders,rtfolder,otagfolders,tagfolder,c_tagfolder,;
f1,f2

c_padlrs=PADL(ALLTRIM(STR(nlrs)),8,'0')
c_padtag=PADL(ALLTRIM(STR(ntag)),3,'0')
*--3/12/15: switch to server name
c_basefolder="\\imagesvr\rtdocs\brayton"
*--c_basefolder="\\192.168.1.22\rtdocs\brayton"
ofiles = CREATEOBJECT("Scripting.FileSystemObject")
*\\ date folder level
ofolders = ofiles.GetFolder(c_basefolder)
fc = ofolders.SubFolders
FOR EACH f1 IN fc
	sbfolder = f1.NAME
*\\ case folder level
	c_datefolder=ADDBS(c_basefolder)+ALLTRIM(sbfolder)
	ortfolders = ofiles.GetFolder(c_datefolder)
	frt = ortfolders.SubFolders
	FOR EACH f2 IN frt
		rtfolder = f2.NAME
		IF c_padlrs=rtfolder
*\\ tag folder level
			c_casefolder=ADDBS(c_datefolder)+ALLTRIM(rtfolder)
			otagfolders = ofiles.GetFolder(c_casefolder)
			ftag = otagfolders.SubFolders
			FOR EACH f2 IN ftag
				tagfolder = f2.NAME
				IF c_padtag=tagfolder
					c_tagfolder=ADDBS(c_casefolder)+ALLTRIM(tagfolder)
					RETURN (c_tagfolder)
				ENDIF
			NEXT
		ENDIF
	NEXT
NEXT
RETURN "NONE"



