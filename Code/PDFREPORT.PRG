*!*	*----------------------*****-----------------------------------------------

*!*		SET PRINTER TO NAME laPrinters[lnDefaultPrinter,1]

*!*		To set PDF Printer location 
*!*		1.	open printer and faxes 
*!*		2.	select "port" tab
*!*		3.	add new port "c:\temp\*.pdf"
*!*		4.	set as default
*!*		5.	select "advanced" tag
*!*		6.	select "printing defaults"
*!*		7.	un-check "view Adobe PDF results"
*!*		8.	un-check "Prompt for Adobe PDF filename"

*!*		the output will be in c:\temp\ the file name will be exactly same as the report form name.

*!*	*----------------------*****-----------------------------------------------

PARAMETERS creportform,ctable
LOCAL lcreport

IF PCOUNT()<1
	RETURN 
ENDIF
IF PCOUNT()<2
	ctable=''
ENDIF

lnCurArea=SELECT()
IF NOT EMPTY(ctable)
	SELECT ctable
ENDIF
lcComm=""
llPrinter=.F. 
lnDefaultPrinter=1
lcDefaultPrinter=SET("printer",2)
=APRINTERS(laPrinters)
FOR lnii=1 TO ALEN(laPrinters,1)
    IF ALLTRIM(UPPER(laPrinters[lnII,1]))=="ADOBE PDF"
       llPrinter=.T.       
    ENDIF 
    IF ALLTRIM(UPPER(lcDefaultPrinter))$ALLTRIM(UPPER(laPrinters[lnII,1]))
       lnDefaultPrinter=lnII
    ENDIF 
NEXT
IF llPrinter=.F.
   gfmessage("To continue you need to have Adobe PDF installed on your computer.  Please notify IT Department.")   
   RETURN .F.
ENDIF  

*thisform.MousePointer= 11
*thisform.Enabled=.F.
SET PRINTER TO NAME "ADOBE PDF" 
lcreport="c:\temp\"+ALLTRIM(creportform)+".pdf"

REPORT FORM (creportform) TO PRINT NOCONSOLE 

*\\ Delay program to wait while PDF file is created
llExit=.F.  
DO WHILE llExit=.F. 
   IF FILE(lcReport)
      llExit=.T. 
   ENDIF 
ENDDO    
llExit=.F.  
lnExit=0
DO WHILE llExit=.F.    
   lnExit=lnExit+1
   IF lnExit>1000000
  llExit=.T. 
   ENDIF 
ENDDO    

SELECT (lnCurArea)

IF LEFT(ALLTRIM(laPrinters[lnDefaultPrinter,1]),2)=="\\"
	SET PRINTER TO NAME (laPrinters[lnDefaultPrinter,1])
ELSE 
	SET PRINTER TO (laPrinters[lnDefaultPrinter,1])
ENDIF 

RETURN .T.