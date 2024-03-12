LPARAMETERS lnLRS, lnTag
LOCAL lnCurArea, lcInvoicePath, lnTifFile, lnPdfFile, lcFile, lcCurDir, lcInvoiceFile, lcNewFolder, loMed
lnCurArea=SELECT()
loMed=CREATEOBJECT("generic.medgeneric")
lcInvoicePath=MLPriPro("R", "RTS.INI", "Data","RogsPath", "\")
lcInvoicePath=ADDBS(ALLTRIM(lcInvoicePath))+PADL(ALLTRIM(STR(lnLRS)),8,"0")
lnTifFile=ADIR(laTif,ALLTRIM(lcInvoicePath)+"\006\"+PADL(ALLTRIM(STR(lnTag)),3,"0")+"\*.tif") 
IF lnTifFile>0
   =ASORT(laTif,3)
ENDIF 
lnPdfFile=ADIR(laPdf,ALLTRIM(lcInvoicePath)+"\006\"+PADL(ALLTRIM(STR(lnTag)),3,"0")+"\*.pdf")
IF lnPdfFile>0
    =ASORT(laPdf,3)
ENDIF  
IF lnTifFile=0 AND lnPdfFile=0   && check STC folder and move selected file to Invoice folder
   lcCurDir=SYS(5)+SYS(2003) 
   lcInvDir=ALLTRIM(lcInvoicePath)+"\004\"+PADL(ALLTRIM(STR(lnTag)),3,"0")+"\"
   IF DIRECTORY(lcInvDir)
   		SET DEFAULT TO &lcInvDir
   		lcFile=GETFILE("tif","Select Invoice File")
   		SET DEFAULT TO &lcCurDir
   		IF !EMPTY(ALLTRIM(lcFile))
   		    lcNewFolder=ALLTRIM(lcInvoicePath)+"\006\"+PADL(ALLTRIM(STR(lnTag)),3,"0")+"\"
   		    IF !DIRECTORY(lcNewFolder)
   		       MD &lcNewFolder
   		    ENDIF 
      		lcInvoiceFile=ALLTRIM(lcInvoicePath)+"\006\"+PADL(ALLTRIM(STR(lnTag)),3,"0")+"\"+JUSTFNAME(lcFile)
      		COPY FILE &lcFile TO &lcInvoiceFile
      		DELETE FILE &lcFile
      		lcSQLLine="exec [dbo].[addRogRecord] "+ALLTRIM(STR(lnLrs))+","+ALLTRIM(STR(lnTag))+", 6, "+;
      		"'(STC)"+ALLTRIM(goApp.CurrentUser.ntlogin)+"'"
      		loMed.sqlexecute(lcSQLLine)
   		ENDIF 
   		lnTifFile=ADIR(laTif,ALLTRIM(lcInvoicePath)+"\006\"+PADL(ALLTRIM(STR(lnTag)),3,"0")+"\*.tif")
   		IF lnTifFile>0
      		=ASORT(laTif,3)
   		ENDIF 
   		lnPdfFile=ADIR(laPdf,ALLTRIM(lcInvoicePath)+"\006\"+PADL(ALLTRIM(STR(lnTag)),3,"0")+"\*.pdf")
   		IF lnPdfFile>0
     		 =ASORT(laPdf,3)
   		ENDIF 
   ELSE 
      IF gfmessage("Can't find Invoice Folder for RT# - "+ALLTRIM(STR(lnLRS))+;
      "; Tag - "+ALLTRIM(STR(lnTag))+". "+CHR(13)+;
      " Continue to print STC?",.T.)=.F.
         RELEASE loMed
         SELECT (lnCurArea)
         RETURN "XX"
      ENDIF 
   ENDIF 
ENDIF 
lcFile=""
DO CASE 
   CASE lnTifFile>0 AND lnPdfFile=0		&& only tif file exists
        lcFile=ALLTRIM(lcInvoicePath)+"\006\"+PADL(ALLTRIM(STR(lnTag)),3,"0")+"\"+ALLTRIM(laTif[lnTifFile,1])		&& the latest                       
   CASE lnTifFile=0 AND lnPdfFile>0		&& only pdf file exists		
        lcFile=ALLTRIM(lcInvoicePath)+"\006\"+PADL(ALLTRIM(STR(lnTag)),3,"0")+"\"+ALLTRIM(laPdf[lnPdfFile,1])       	&& the latest                    
   CASE lnTifFile>0 AND lnPdfFile>0							&& both files exist; take the latest
        IF laTif[lnTifFile,3]>=laPdf[lnPdfFile,3]
            lcFile=ALLTRIM(lcInvoicePath)+"\006\"+PADL(ALLTRIM(STR(lnTag)),3,"0")+"\"+ALLTRIM(laTif[lnTifFile,1])
        ELSE 
            lcFile=ALLTRIM(lcInvoicePath)+"\006\"+PADL(ALLTRIM(STR(lnTag)),3,"0")+"\"+ALLTRIM(laPdf[lnPdfFile,1])
        ENDIF          
  OTHERWISE 
        * no Invoice file, nothing to print
ENDCASE 
RELEASE loMed
SELECT (lnCurArea)
RETURN lcFile
        
         
       


