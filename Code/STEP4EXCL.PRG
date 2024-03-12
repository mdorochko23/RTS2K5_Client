
PARAMETERS  n_headerId, n_locId, c_folder
**n_headerId WEB ORDER ID id_tblw2header, n_locId LOCATION ID id_tblw2location and a Folder where RTS use stored ;
client's images received with an excel orders ( qc_SetUpExcelPreprocess table has it)
LOCAL c_CurArea AS STRING,  c_Default AS STRING, c_sql AS STRING, l_ok AS Boolean, n_id_tblw2header AS INTEGER
** pre-process client's images
*DO step4excl WITH 100089190,4978,"W:\QCExcel\qctest\"
STORE "" TO c_Default, c_CurArea, c_sql
LOCAL omedExc4 AS OBJECT
STORE .F. TO l_ok
IF n_locId=0  OR EMPTY(ALLTRIM(c_folder))&& no location record with a excel order or no folder with images was picked
	RETURN l_ok
ENDIF
SET SAFETY OFF
c_CurArea=ALIAS()

omedExc4=CREATEOBJECT("medrequest")
omedExc4.closealias("ImgData")
c_sql= " Exec [dbo].[qc_GetExclImagesInfo] '" + STR(n_headerId) + "','" +STR(n_locId) + "'"
omedExc4.SQLEXECUTE( c_sql,"ImgData")
SELECT ImgData
IF NOT EOF()
	F_PCX=goApp.pcxpath
	F_PCXARCH=goApp.pcxarchpath
	l_ok= movefiletopcx ( ALLTRIM(STR(ImgData.qc_Lrs_No)), ImgData.qc_Tag, c_folder)
ENDIF

IF NOT EMPTY(c_CurArea)
	SELECT (c_CurArea)
ENDIF
SET SAFETY ON
RELEASE omedExc4
RETURN  l_ok



*****************************************************************************************************************
FUNCTION movefiletopcx
PARAMETERS  cRTNum,  nTagAuth, c_ImgPath
PRIVATE l_done AS Boolean, lcDest AS STRING, lcPath AS STRING
l_done=.F.
STORE "" TO lcDest, lcPath
SELECT ImgData
**	If a [Use Specific Authorization] is 'Yes' and a [Autho File Name] <>''  then an image file will be stored at the PCX folder as an authorization file;
**	If  a [Use Case Documents] is 'Yes' and a [Case Documents File Name] <>''  then an image file will be stored at the PCX folder as an case level image;
**	If a [Use Base Authorization] is 'Yes' and a [Autho File Name] <>''  then an image file will treated as a base document

lcDest= F_PCX
IF NVL(ImgData.qc_ExcCaseDocs,.F.) AND !EMPTY(ALLTRIM(NVL(ImgData.qc_CaseDocsName, "")))
**case level	(C)	
	IF !EMPTY(ALLTRIM(NVL(ImgData.qc_CaseDocsName, "")))
		lcPath=Converfile_bypage(ADDBS(c_ImgPath), ALLTRIM(ImgData.qc_CaseDocsName),cRTNum,  nTagAuth,   UPPER(RIGHT(ALLTRIM(ImgData.qc_CaseDocsName),4)), "C")
	ENDIF
ENDIF
IF NVL(ImgData.qc_ExcSpecAuth,.F.)
** store as an authorization file (A)
	IF !EMPTY(ALLTRIM(NVL(ImgData.qc_AuthFileName,"")))
		lcPath=Converfile_bypage(ADDBS(c_ImgPath), ALLTRIM(ImgData.qc_AuthFileName),cRTNum,  nTagAuth,   UPPER(RIGHT(ALLTRIM(ImgData.qc_AuthFileName),4)), "A")
	ENDIF
ENDIF


RELEASE fso_img
RETURN .T.
***************************************************************************************
**05/8/2015 -CONVERT MULTIPAGE PDFS INTO MULTIPAGE TIFFS
***************************************************************************************
PROCEDURE Converfile_bypage
LPARAMETERS lcPath, lcFileName,cRTNum, ntagnum, lc_ext, lc_ImgType
LOCAL lcCurDir, lcLine, lcInFile, lcOutFile
LOCAL fso_img AS Object
fso_img = CREATEOBJECT("Scripting.FileSystemObject")
lcCurDir=SYS(5)+SYS(2003)
cPdffile=ADDBS(ALLTRIM(NVL(lcPath,"")))+ALLTRIM(NVL(lcFileName,""))
lcInFile2="c:\temp\"+ALLTRIM(lcFileName)
lcOutFile2="c:\temp\"+JUSTSTEM(lcFileName)+".TIF"
cTiffFile=ADDBS(ALLTRIM(NVL(lcPath,"")))+JUSTSTEM(lcFileName)+".TIF"
*----------new way
LOCAL c_convert,c_drive,c_selected,c_temp
c_temp='Z.Z'
IF NOT FILE(cPdffile)
	RETURN
ENDIF
IF  UPPER(lc_ext)=".PDF"
	WAIT WINDOW 'Converting PDF file to Multi-page TIFF format.' NOWAIT NOCLEAR
	c_selected=lcInFile2
	COPY FILE (cPdffile) TO (c_selected)
	SET DEFAULT TO 'C:\RTS'
	IF !FILE("pdf2image.dll")
		DO copydlls
	ENDIF
	DECLARE LONG PDFToImageConverter IN "c:\rts\pdf2image.dll" ;
		STRING szPDFFileName , STRING szOutputName, ;
		STRING szUserPassword,STRING szOwnPassword, ;
		LONG xresolution,LONG YRESOLUTION,LONG bitcount, ;
		LONG compression, LONG quality,INTEGER grayscale, ;
		INTEGER multipage,LONG firstPage,LONG lastPage

	DECLARE LONG PDFToImageGetPageCount  IN "c:\rts\pdf2image.dll" ;
		STRING szPDFFileName

	DECLARE PDFToImageSetCode IN "c:\rts\pdf2image.dll" ;
		STRING szRegcode

	LOCAL coutfile,npagecnt,nok

	=PDFToImageSetCode("VPEDRFXY2PIDMFAGEXYUXEJHYEXNVERYPDF")

	npagecnt=PDFToImageGetPageCount(cPdffile)
	nok = PDFToImageConverter(cPdffile, cTiffFile ,"", "", 200, 200, 1, 4, 70, 0, 0, -1, -1)
***
ENDIF  &&pdf
*IF npagecnt>1
IF nok=0
SET DEFAULT TO (lcPath)
n_len=LEN(cTiffFile)
c_search=LEFT(cTiffFile, n_len-4)
nla = ADIR(la, c_search + '*.tif')

FOR nCount = 1 TO nla
	STORE "" TO c_name, c_PCXfile
	c_PCXfile= getimgname ( ALLTRIM(cRTNum), ntagnum,lc_ImgType)
	c_name=ADDBS( lcPath)+ALLTRIM(la(nCount,1))
	IF !EMPTY(c_PCXfile)
		fso_img.CopyFile( c_name, ADDBS(lcDest)+ c_PCXfile  )
		IF  fso_img.FileExists(c_name )
			fso_img.DELETEFile( c_name, .T. )
		ENDIF
		
	ENDIF
ENDFOR
*ENDIF
ELSE

	gfmessage("Failed to convert PDF file to Tiff file")


ENDIF
***



WAIT CLEAR



CLEAR DLLS "PDFToImageConverter","PDFToImageGetPageCount","PDFToImageSetCode"

SET DEFAULT TO (lcCurDir)
RETURN cTiffFile

****************************************************************************
FUNCTION getimgname
PARAMETERS cPagert, nPagetag, cType

n_Lastnum1=0
n_Lastnum1 =getimages(cPagert,nPagetag, cType)
c_newfile=cPagert+cType+ALLTRIM(STR(n_Lastnum1+1)) + "." + IIF(cType="C", "TIF",PADL(ALLTRIM(STR(nPagetag)), 3, "0"))

RETURN c_newfile
*****************************************************************************
FUNCTION getimages
PARAMETERS cPagert, nPagetag, cType


LOCAL  n_Lastnum, n_Lastnum1, n_Lastnum2, n_Lastnum3, n_Lastnum4,lcFile
STORE 0 TO n_Lastnum, n_Lastnum1, n_Lastnum2, n_Lastnum3, n_Lastnum4
lcFile=""

DO CASE

CASE cType="C"
	lcFile=cPagert+"C*.TIF"
OTHERWISE
	lcFile=cPagert+"A*."+PADL(ALLTRIM(STR(nPagetag)), 3, "0")

ENDCASE
* CA PCX path
n_Files = ADIR(a_files, ADDBS(goApp.capcx)+ALLTRIM(UPPER(lcFile)))
IF n_Files > 0
	=ASORT(a_files)
	n_Lastnum1 = getnumber(a_files(ALEN(a_files,1), 1), LEN(cPagert)	)
ENDIF
* CA Archive PCX path
n_Files = ADIR(a_files, ADDBS(goApp.capcxarch)+RIGHT(cPagert,1) +"\"+;
	ALLTRIM(UPPER(lcFile)))
IF n_Files > 0
	=ASORT(a_files)
	n_Lastnum2 = getnumber(a_files(ALEN(a_files,1), 1), LEN(cPagert))
ENDIF
* KOP PCX path
n_Files = ADIR(a_files, ADDBS(goApp.pcxpath)+ALLTRIM(UPPER(lcFile)))
IF n_Files > 0
	=ASORT(a_files)
	n_Lastnum3 = getnumber(a_files(ALEN(a_files,1), 1), LEN(cPagert))
ENDIF
* KOP Archive PCX path
n_Files = ADIR(a_files, ADDBS(goApp.pcxarchpath)+RIGHT(cPagert,1) +"\"+;
	ALLTRIM(UPPER(lcFile)))
IF n_Files > 0
	=ASORT(a_files)
	n_Lastnum4 = getnumber(a_files(ALEN(a_files,1), 1), LEN(cPagert))
ENDIF
n_Lastnum = MAX(n_Lastnum1, n_Lastnum2, n_Lastnum3,n_Lastnum4)

RETURN n_Lastnum

*****************************************************************************************
FUNCTION getnumber
PARAMETER c_Document, n_Lencase
LOCAL n_Pos , c_Num
n_Pos = AT( ".", c_Document)
n_Lencase = n_Lencase + 2
c_Num = SUBSTR(c_Document, n_Lencase, n_Pos - n_Lencase)
RETURN VAL(c_Num)
********************


***************************************************************************************
**04/27/2011 -use new converter: DO NOT USE AS 5/8/15 - SPLIT TIFF INTO SINGLE PAGES NOW 
***************************************************************************************
PROCEDURE Converfile_new
LPARAMETERS lcPath, lcFileName
LOCAL lcCurDir, lcLine, lcInFile, lcOutFile

lcCurDir=SYS(5)+SYS(2003)
cPdffile=ADDBS(ALLTRIM(NVL(lcPath,"")))+ALLTRIM(NVL(lcFileName,""))
lcInFile2="c:\temp\"+ALLTRIM(lcFileName)
lcOutFile2="c:\temp\"+JUSTSTEM(lcFileName)+".TIF"
cTiffFile=ADDBS(ALLTRIM(NVL(lcPath,"")))+JUSTSTEM(lcFileName)+".TIF"
*----------new way
LOCAL c_convert,c_drive,c_selected,c_temp
c_temp='Z.Z'

IF NOT FILE(cPdffile)
	RETURN
ENDIF

WAIT WINDOW 'Converting PDF file to Multi-page TIFF format.' NOWAIT NOCLEAR
c_selected=lcInFile2
COPY FILE (cPdffile) TO (c_selected)
SET DEFAULT TO 'C:\RTS'

IF !FILE("pdf2image.dll")
	DO copydlls
ENDIF

DECLARE LONG PDFToImageConverter IN "c:\rts\pdf2image.dll" ;
	STRING szPDFFileName , STRING szOutputName, ;
	STRING szUserPassword,STRING szOwnPassword, ;
	LONG xresolution,LONG YRESOLUTION,LONG bitcount, ;
	LONG compression, LONG quality,INTEGER grayscale, ;
	INTEGER multipage,LONG firstPage,LONG lastPage

DECLARE LONG PDFToImageGetPageCount  IN "c:\rts\pdf2image.dll" ;
	STRING szPDFFileName

DECLARE PDFToImageSetCode IN "c:\rts\pdf2image.dll" ;
	STRING szRegcode

LOCAL coutfile,npagecnt,nok

=PDFToImageSetCode("VPEDRFXY2PIDMFAGEXYUXEJHYEXNVERYPDF")

nok = PDFToImageConverter(cPdffile, cTiffFile ,"", "", 200, 200, 1, 4, 70, 0, 1, -1, -1)



WAIT CLEAR

IF nok>0
	gfmessage("Failed to convert PDF file to Tiff file")
ENDIF

CLEAR DLLS "PDFToImageConverter","PDFToImageGetPageCount","PDFToImageSetCode"

SET DEFAULT TO (lcCurDir)
RETURN cTiffFile

*** copy the dlls if they are not there
************************************************************************************************
PROCEDURE copydlls
LOCAL ndlls,ncnt,d_TxtTiff,n_TxtTif,C_STRING


ndlls=ADIR(a_dlls,"\\sanstor\image\Release\vfp\RTS\Dlls\pdf2image.dll")

FOR ncnt=1 TO ALEN(a_dlls,1)
	IF INLIST(UPPER(JUSTEXT(a_dlls[ncnt,1])),"DLL")
		IF NOT FILE("c:\rts\"+ALLTRIM(a_dlls[ncnt,1]))
			WAIT WINDOW "Copying required startup file. Please wait..." NOWAIT NOCLEAR
			COPY FILE ("\\sanstor\image\Release\vfp\RTS\Dlls\"+ALLTRIM(a_dlls[ncnt,1])) ;
				TO ("c:\rts\"+ALLTRIM(a_dlls[ncnt,1]))
*!*				IF NOT "CIMAGE.DLL" $ UPPER(ALLTRIM(a_dlls[ncnt,1]))
*!*					c_string="regsvr32 "+"c:\rts\"+ALLTRIM(a_dlls[ncnt,1])
*!*					RUN &c_string
*!*				ENDIF
			WAIT CLEAR
		ENDIF
	ENDIF
NEXT
********************************************************************************************
