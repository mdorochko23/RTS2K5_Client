
*************************************************************************************************
**10/06/2009 - EF - Check Reveision folders for the reprints at SECOND
**09/01/2009 - EF - Check if an First Issue PDF exists.
PROCEDURE getorigpdf
**************************************************************************************************

PARAMETERS n_rtno, n_tagno, l_orig, cSortDate	&& 3/15/2021, ZD #230064, JH
**PARAMETERS n_rtno, n_tagno, l_orig			&& 3/15

LOCAL l_continue AS Boolean, l_continue2 AS Boolean, l_continue3 AS Boolean
STORE .F. TO l_continue, l_continue2, l_continue3
PUBLIC ARRAY laList(1,5)
PUBLIC Pc_tempFile AS STRING
Pc_tempFile=""
SELECT 0

**REPELACE CURSOR WITH A TABLE
*Pc_tempFile =SYS(5)+'\temp\TEMPLIST.DBF'

IF USED('TEMPLIST')
	SELECT 	TEMPLIST
	USE
ENDIF
*!*	IF FILE(Pc_tempFile )
*!*		DELETE FILE (Pc_tempFile )
*!*	ENDIF
*!*	CREATE TABLE &Pc_tempFile (lrs_no N(6), TAG N(3), filepath CHAR(100), filename CHAR(25), foldername CHAR (15))
CREATE CURSOR  TEMPLIST (lrs_no N(6), TAG N(3), filepath CHAR(100), filename CHAR(25), foldername CHAR (15))

SELECT 0

*IF l_orig													&& 3/15/2021, ZD #230064, JH
*	l_continue= getpdf(n_rtno, n_tagno, "FIRST", ".pdf")
*ELSE
*	l_continue= getpdf(n_rtno, n_tagno, "FIRST", ".pdf")
*	l_continue2= getpdf(n_rtno, n_tagno, "REPRINT", ".pdf")
*	l_continue3= getpdf(n_rtno, n_tagno, "SECOND", ".pdf")
*ENDIF														&& 3/15

IF l_orig													&& 3/15/2021, ZD #230064, JH
	l_continue= getpdf(n_rtno, n_tagno, "FIRST", ".pdf", cSortDate)
ELSE
	l_continue= getpdf(n_rtno, n_tagno, "FIRST", ".pdf", cSortDate)
	l_continue2= getpdf(n_rtno, n_tagno, "REPRINT", ".pdf", cSortDate)
	l_continue3= getpdf(n_rtno, n_tagno, "SECOND", ".pdf", cSortDate)
ENDIF														&& 3/15

RELEASE laList

RETURN IIF(l_continue OR l_continue2 OR l_continue3,.T.,.F.)

**************************************************************************************************
FUNCTION getpdf
**************************************************************************************************

PARAMETERS N_RT, n_tag, c_Folder, c_File, cSortDate		&& 3/15/2021, ZD #230064, JH
*PARAMETERS N_RT, n_tag, c_Folder, c_File				&& 3/15

LOCAL l_retval AS Boolean, c_path AS STRING
PUBLIC lcSearch AS STRING, nCount AS INTEGER,  ln_lastone AS INTEGER
lcSearch=""
ln_lastone=1
lcCurDir=SYS(5)+SYS(2003)
lcrpsdocs=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","RpsPdfPath", "\")))
lcSearch=lcrpsdocs+ PADL(ALLTRIM(STR(N_RT)),6,"0")+"\"+PADL(ALLTRIM(STR(n_tag)),3,"0") +"\" + c_Folder+ "\"
fso = CREATEOBJECT("Scripting.FileSystemObject")
IF  NOT fso.FolderExists(lcSearch)
	RETURN .F.
ENDIF
nCount=1
IF NOT EMPTY(lcSearch)
	SET DEFAULT TO &lcSearch
*WAIT WINDOW "Looking for a file at " + lcSearch
	lcSearch1=""
	c_path=""
	l_retval=.F.

	DO CASE
	CASE ALLTRIM(UPPER(c_Folder))="FIRST"

		IF ADIR(laList,ADDBS(ALLTRIM(lcSearch))+"*.pdf")<>0
***only show the last one
			ln_lastone=ADIR(laList, ALLTRIM(lcSearch)+"*.pdf")
			lcSearch1=lcSearch
			IF laList(1,3) >={09/30/2009}  && exculed PDF files that had been created before 9/30/09 as they may have a spec handling
				l_retval=.T.
			ENDIF

		ENDIF
	CASE ALLTRIM(UPPER(c_Folder))="REPRINT"

		IF ADIR(laList,ADDBS(ALLTRIM(lcSearch))+"*.pdf")<>0
***only show the last one
			ln_lastone=ADIR(laList, ALLTRIM(lcSearch)+"*.pdf")
			lcSearch1=lcSearch
			l_retval=.T.

		ENDIF
	CASE ALLTRIM(UPPER(c_Folder))="SECOND"


**Check the SECOND forlder first
		IF ADIR(laList,ADDBS(ALLTRIM(lcSearch))+"*.pdf")<>0
***only show the last one
			ln_lastone=ADIR(laList, ALLTRIM(lcSearch)+"*.pdf")
			lcSearch1=lcSearch
			IF laList(1,3) >={09/30/2009}
				l_retval=.T.
			ENDIF
		ENDIF
**Check the SECOND/revision forlders second

		FOR nCount = 1 TO 99

			c_path =ADDBS(ALLTRIM(lcSearch))+ "REV" + IIF(nCount<=9,"0","") + ALLTRIM(STR(nCount)) + "\"
			IF  fso.FolderExists( c_path)

				lcSearch1=c_path
				IF ADIR(laList,ADDBS(ALLTRIM(lcSearch1))+"*.pdf")<>0
***only show the last one
					ln_lastone=ADIR(laList, ALLTRIM(lcSearch1)+"*.pdf")
					l_retval=.T.
				ENDIF
			ELSE
				EXIT

			ENDIF
		NEXT

	ENDCASE
ELSE
	WAIT WINDOW "A search location is empty. Contact IT dept."

ENDIF

IF l_retval
	IF cSortDate			&& 3/15/2021, ZD #230064, JH
*--10/1/21: use datetime for the sort [252880]
		*--ASORT(laList,3)
		*--create new array with a datetime elemnt
		DIMENSION laFiles(ln_lastone, 2)
		FOR lnI = 1 TO ln_lastone
			laFiles(lnI, 1) = laList(lnI, 1)  && filename
			laFiles(lnI, 2) = CTOT( transform(laList(lnI, 3)) + " " + laList(lnI, 4))   && datetime
		ENDFOR
		*--sort on the datetime element
		ASORT(laFiles,2)
		INSERT INTO TEMPLIST VALUES (n_rtno,n_tagno,lcSearch1, laFiles(ln_lastone,1), c_Folder )
	ELSE
		INSERT INTO TEMPLIST VALUES (n_rtno,n_tagno,lcSearch1, laList(ln_lastone,1), c_Folder )
	ENDIF					&& 3/15

*--INSERT INTO templist VALUES (n_rtno,n_tagno,lcSearch1, LALIST(ln_lastone,1), c_Folder )
ENDIF

SET DEFAULT TO &lcCurDir


RETURN  l_retval

