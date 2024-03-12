**6/8/09 Parameters: Folder Name, RT and Tag
***********************************

PARAMETERS c_folder,n_RT, n_tagauth
lcnow=SYS(5) +SYS(2003)

*c_path=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","API_FOLDER_IMG", "\")))
c_path="K:\sharedwp\awko\20090529\" + c_folder
SET DEFAULT TO (c_path)

nla = ADIR(la, '*.pdf')

SUSPEND

FOR nCount = 1 TO nla
	DO TagImage WITH la(nCount,1), n_RT, n_tagauth, c_path
	
ENDFOR


SET DEFAULT TO (lcnow)
return

***********************************
PROCEDURE TagImage
PARAMETERS cfilename,nRT, ntagauth, cpath
PRIVATE c_FileNew as String
&&c_TPath="T:\PCX\"
c_TPath="K:\sharedwp\awko\20090529\" && test , use pcx in production
c_TPath=cpath

	c_FileNew= gettifname(nRT,ntagauth)
	*c_filen=ALLTRIM(STR(nRT)) +"_2.tif"
	c_path=cpath
	c_file =c_path+"\" + cfilename 
	
	IF FILE(c_file) 
		c_TIFfile =c_TPath+"\"+c_FileNew
		c_file="'" + c_file + "'"
		COPY FILE &c_file TO &c_TIFfile
		l_done=.T.
	ELSE
				
		l_done=.f.
	ENDIF

********************************************************************************************************************
FUNCTION gettifname
PARAMETERS NLRSNO, nPtag


F_PCX1="T:\PCX\" 
n_Lastnum1=1
lcFile =ALLTRIM(STR(NLRSNO))+"A*."+PADL(ALLTRIM(STR(nPtag)), 3, "0")
n_Files = ADIR(a_files, F_PCX1 +ALLTRIM(UPPER(lcFile)))
IF n_Files > 0
	=ASORT(a_files)
	n_Lastnum1 =getnumber(a_files(ALEN(a_files,1), 1), LEN(ALLTRIM(STR(NLRSNO))))
ENDIF
c_newfile=ALLTRIM(STR(NLRSNO))+"A"+ALLTRIM(STR(n_Lastnum1+1)) + "." + PADL(ALLTRIM(STR(nPtag)), 3, "0")
RETURN c_newfile

*****************************************************************************************
FUNCTION getnumber
PARAMETER c_Document, n_Lencase
LOCAL n_Pos , c_Num
n_Pos = AT( ".", c_Document)
n_Lencase = n_Lencase + 2
c_Num = SUBSTR(c_Document, n_Lencase, n_Pos - n_Lencase)
RETURN VAL(c_Num)

