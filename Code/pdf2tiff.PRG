* Pdf to tiff converter

LPARAMETERS cPdffile,cTiffFile
LOCAL c_convert,c_drive,c_selected,c_temp
c_temp='Z.Z'


*cnewfile=(ADDBS(JUSTPATH(cfile))+JUSTSTEM(cfile)+'.TIF')

IF NOT FILE(cPdffile)
	RETURN
ENDIF

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

WAIT WINDOW 'Converting PDF file to Multi-page TIFF format.' NOWAIT NOCLEAR
c_selected="c:\temp\"+SYS(3)+".pdf"
COPY FILE (cPdffile) TO (c_selected)
c_drive=SYS(5)+SYS(2003)

LOCAL coutfile,npagecnt,nok,cCode

cCode=MLPriPro("R", "RTS.INI", "Data","Pdf2imagekey", "VERYPDF-PDF2IMAGE-1009018849")
SET DEFAULT TO 'C:\RTS'

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

*cCode= "VERYPDF-PDF2IMAGE-1009018849"
=PDFToImageSetCode(cCode)

*!*         =PDFToImageSetCode("VPEDRFXY2PIDMFAGEXYUXEJHYEXNVERYPDF")

npagecnt=PDFToImageGetPageCount(c_selected)

WAIT WINDOW "Converting PDF file to Tiff File: " + ALLTRIM(STR(npagecnt)) + " page(s)" NOWAIT NOCLEAR

nok = PDFToImageConverter(c_selected, cTiffFile ;
	,"", "", 200, 200, 1, 4, 70, 0, 1, -1, -1)

WAIT CLEAR

IF nok>0
	gfmessage("Failed to convert PDF file to Tiff file")
ENDIF

*-- clear use of files from the converter by calling with blank files
nok = PDFToImageConverter("", "","", "", 200, 200, 1, 4, 70, 0, 1, -1, -1)

CLEAR DLLS "PDFToImageConverter","PDFToImageGetPageCount","PDFToImageSetCode"

SET DEFAULT TO (c_drive)

IF FILE(c_selected)
	ERASE (c_selected)
ENDIF
