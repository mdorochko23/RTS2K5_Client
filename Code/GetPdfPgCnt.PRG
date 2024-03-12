**********************************************************************************
*** get the page count of a PDF file
**********************************************************************************

FUNCTION GetPdfPgCnt
LPARAMETERS cPdffile
LOCAL c_drive,npagecnt,cCode
c_drive=SYS(5)+SYS(2003)
nPageCnt = 0
*// check for updated DLLs
ndlls=ADIR(a_dlls,"\\sanstor\image\Release\vfp\rts\dlls\pdf2image\*.*")
FOR ncnt=1 TO ALEN(a_dlls,1)
	IF NOT FILE("c:\rts\"+ALLTRIM(a_dlls[ncnt,1]))
		WAIT WINDOW "Copying required startup file. Please wait..." NOWAIT NOCLEAR
		COPY FILE ("\\sanstor\image\Release\vfp\rts\dlls\pdf2image\"+ALLTRIM(a_dlls[ncnt,1])) ;
			TO ("c:\rts\"+ALLTRIM(a_dlls[ncnt,1]))
		WAIT CLEAR

	ELSE
*// check date of user file                            d_TxtTiff = a_dlls[ncnt,3]
		n_TxtTiff = ADIR(a_txtTiff,"c:\rts\"+ALLTRIM(a_dlls[ncnt,1]))
		d_TxtTiff = a_dlls[ncnt,3]
		IF (n_TxtTiff > 0) AND (d_TxtTiff > a_txtTiff[1, 3])
			WAIT WINDOW "Updating required startup file. Please wait..." NOWAIT NOCLEAR

			COPY FILE ("\\sanstor\image\Release\vfp\rts\dlls\pdf2image\"+ALLTRIM(a_dlls[ncnt,1])) ;
				TO ("c:\rts\"+ALLTRIM(a_dlls[ncnt,1]))
		ENDIF
	ENDIF
NEXT
*--activate the DLLs
cCode=MLPriPro("R", "RTS.INI", "Data","Pdf2imagekey", "VERYPDF-PDF2IMAGE-1009018849")
SET DEFAULT TO 'C:\RTS'

DECLARE LONG PDFToImageGetPageCount  IN "c:\rts\pdf2image.dll" ;
	STRING szPDFFileName
DECLARE PDFToImageSetCode IN "c:\rts\pdf2image.dll" ;
	STRING szRegcode
=PDFToImageSetCode(cCode)

*--get the page count
try
	npagecnt=PDFToImageGetPageCount(cPdffile)
CATCH
	nPageCnt = 0
ENDTRY

SET DEFAULT TO (c_drive)

RETURN nPageCnt