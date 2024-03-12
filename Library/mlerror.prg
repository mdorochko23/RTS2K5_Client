#INCLUDE APP.h
**********************************************************************************
* mlError.prg	-	VFP Error handling routine.
*
* Purpose:	To log errors to free table, notify user, and shutdown application.
* 
* Syntax:	ON ERROR DO mlError WITH ERROR(), MESSAGE(), MESSAGE(1), ;
*            SYS(16), LINENO(), SYS(102), SYS(100), SYS(101), LASTKEY(), ;
*            ALIAS(), SYS(18), SYS(5), SYS(6), SYS(2003), WONTOP(), ;
*            SYS(2011), SYS(2018), SET("CURSOR"), PROG(), (applic. obj.), ;
*            (INI file name with path), (data path), (user login name), ;
*            (applic. name)
*
* Parameters:
*   p_nErNo		- The numeric code of the number provided by ERROR()
*   p_cMsg		- The error message provided by MESSAGE()
*   p_cCode		- The contents of the line of code which
*                 triggered the error as provided by MESSAGE(1)
*   p_cModul	- The name of the code module, SYS(16)
*   p_nLine		- The number of the line of code triggering the
*                 error, LINENO()
*   p_cPrint	- Current PRINTER setting as per SYS(102)
*   p_cConsol	- Current CONSOLE setting as per SYS(100)
*   p_cDevice	- Current DEVICE setting as per SYS(101)
*   p_nKeyPr	- LASTKEY()
*   p_cCurrDBF	- Selected .DBF when error occurred
*   p_cCurrCtr	- Current control - SYS(18)
*   p_cDefDrv	- Default drive at time error occurred - SYS(5)
*   p_cPrntDev	- Current SET PRINTER TO setting - SYS(6)
*   p_cCurDir	- Current directory at time error occurred - SYS(2003)
*   p_cTopWin	- Top window at time error occurred
*   p_cLocked 	- Record or file lock status at time error occurred -
*                 SYS(2011)
*   p_cExtra	- Missing file, window, etc.
*   p_cCursSet	- Cursor setting at time error occurred.
*   p_cProg     - from PROG()
*   p_cAppObj   - Application Object
*   p_cINIFile	- path + INI file name
*   p_cDataPth	- data path
*   p_cUser			- User login name
*   p_cProduct	- Product Name
*   p_cAppName	- Application Name
*   p_lLog			- Should error be logged in error table?
*   
*
* Notes: AERROR() is used to gather more information about the error.
*        
*        In addition to this information, the routine saves the information
*        from LIST MEMORY and LIST STATUS into the memo field.
* 
*        A tempory text file is created in the current directory, and later deleted.
* 
*        If the free error table does not exist in the specified directory,
*        one is created in that directory.
*
* Errors can occur if there is code residing inside the object, and after the line of
*   code which called the error.  The code may call forms or display a dialog box, ect.
*   The system is supposed to be shutting down, not requesting user input.
**********************************************************************************
LPARAMETERS p_nErNo, p_cMsg, p_cCode, p_cModul, p_nLine, p_cPrint, ;
            p_cConsol, p_cDevice, p_nKeyPr, p_cCurrDBF, p_cCurrCtr, p_cDefDrv, ;
            p_cPrntDev, p_cCurDir, p_cTopWin, p_cLocked, ;
            p_cExtra, p_cCursSet, p_cProg,p_blank, p_cINIFile, p_cDataPth, ;
            p_cUser, p_cAppName, p_lLog,p_incase


*--MESSAGEBOX("parameters 1:"+ p_nErNo+",2:"+ p_cMsg+",3:"+ p_cCode+",4:"+ p_cModul+",5:"+ p_nLine+",6:"+ p_cPrint+",7:"+ ;
            p_cConsol+",8:"+ p_cDevice+",9:"+ p_nKeyPr+",10:"+ p_cCurrDBF+",11:"+ p_cCurrCtr+",12:"+ p_cDefDrv+",13:"+ ;
            p_cPrntDev+",14:"+ p_cCurDir+",15:"+ p_cTopWin+",16:"+ p_cLocked+",17:"+ ;
            p_cExtra+",18:"+ p_cCursSet+",19:"+ p_cProg+",20:"+ p_cINIFile+",21:"+ p_cDataPth+",22:"+ ;
            p_cUser+",23:"+ p_cAppName+",24:"+ p_lLog+",25:"+p_incase,0+16)

#DEFINE BHDR_SIZE 40 && BITMAPINFOHEADER

LOCAL l_cErrTbl, l_cStatusFile, l_cMemoryFile, l_aErrors, l_lEatError, ;
      l_iIndex, l_iIndex2, l_iCount, l_nUsed, l_nScreens, l_nOldWrk, l_nOldDataS, ;
      l_cStack, l_nStack, l_cProgram, l_cGeneral,c_erdetl,c_memtxt,l_confirm

ON Error
c_erdetl=''   
c_memtxt=''
oFSO = CREATEOBJECT("Scripting.FileSystemObject")
IF (FILE("c:\temp\error_screenprintbitmap.bmp"))
  oFSO.DeleteFile("c:\temp\error_screenprintbitmap.bmp",.T.)
ENDIF
lbSaveScreenPrintStatus1 = saveScreenPrintAsBitMap("c:\temp\error_screenprintbitmap.bmp",44)
IF (!FILE("c:\temp\error_screenprintbitmap.bmp"))
  lbSaveScreenPrintStatus1 = saveScreenPrintAsBitMap("c:\temp\error_screenprintbitmap.bmp",44)
ENDIF  
*--First, check for an OLE error--*

*--Verify Parameters
p_nKeyPr   = IIF(TYPE('p_nKeyPr')!='N', 0, p_nKeyPr)
p_cCurrDBF = IIF(EMPTY(p_cCurrDBF), "NONE", p_cCurrDBF)
p_cCurrCtr = IIF(EMPTY(p_cCurrCtr), "NONE", p_cCurrCtr)
p_cPrntDev = p_cPrntDev
p_cPrint 	= IIF(TYPE('p_cPrint') != 'C', "NONE", p_cPrint)
p_cConsol = IIF(TYPE('p_cConsol') != 'C', "NONE", p_cConsol)
p_cDevice = IIF(TYPE('p_cDevice') != 'C', "NONE", p_cDevice)
p_cCurDir  = p_cDefDrv + p_cCurDir
p_cTopWin  = IIF(EMPTY(p_cTopWin), "SCREEN", p_cTopWin)
p_cLocked  = IIF(EMPTY(p_cLocked), "NONE", p_cLocked)
p_cExtra   = IIF(EMPTY(p_cExtra), "NONE", p_cExtra)
*--p_cINIFile = UPPER(p_cINIFile)
p_cUser    = IIF(EMPTY(p_cUser), "NONE", p_cUser)
p_lLog     = IIF(EMPTY(p_lLog),.T.,p_lLog)
p_cAppName = "VFP RTS"

l_cErrTbl  = "MLERROR"
l_cStatusFile = p_cDataPth+SUBSTR(SYS(2015),3,10)+".ERR"
l_cMemoryFile = p_cDataPth+SUBSTR(SYS(2015),3,10)+".ERR"
l_nOldWrk = SELECT(0)
l_nOldDataS = SET("DATASESSION")

*--Get more error info.
DIMENSION l_aErrors[1]
=AERROR(l_aErrors)

*--Log the Error
IF p_lLog
*    Y = INPUTBOX("TYPE HERE","Input","")
	LIST MEMORY TO FILE (l_cMemoryFile) NOCONSOLE
	LIST STATUS TO (l_cStatusFile) NOCONSOLE
	glError = .T.
	*-- Build General Info
	l_cGeneral = "[GENERAL ERROR INFORMATION]" + CHR(13) + ;
	             CHR(13) +  ;
                 REPL("*",7) +  ;
                 "ERROR NUMBER: " + ALLT(STR(p_nErNo)) + CHR(13)+;
                 "MESSAGE: " + p_cMsg +CHR(13)+;
                 "PRODUCT: " + p_cAppName + " "+SUBSTR(_SCREEN.Caption,AT('(',_SCREEN.Caption,2))+CHR(13)+;
                 "IN PROGRAM: " + p_cProg + CHR(13)+;
                 "AT LINE NUMBER: " + ALLT(STR(p_nLine)) + CHR(13)+;
                 p_cCode + CHR(13)+;
                 "SELECTED TABLE: " + p_cCurrDBF + CHR(13)+;
                 "LOCK STATUS: " + p_cLocked + CHR(13)+;
                 "TOP WINDOW: " + p_cTopWin + CHR(13)+;
                 "SELECTED CONTROL: " + p_cCurrCtr+CHR(13)      

	*-- Build Call Stack
	l_cStack = ''
	=AStackInfo(a_Stack)
	FOR l_nStack = 1 TO ALEN(a_Stack,1)
	   l_cProgram = (a_stack[l_nStack,3])
       IF EMPTY(l_cProgram)
         EXIT
	   ELSE
         TRY
           l_cStack = "(" + ALLT(STR(l_nStack)) + ")..." + l_cProgram + ": " + ALLTRIM(STR(a_stack[l_nStack,5])) + ;
				           "    Source Line: " +  ALLTRIM(a_stack[l_nStack,6]) + CHR(13) +l_cStack
         CATCH
         ENDTRY			
       ENDIF
	ENDFOR	
	
*!*		FOR l_nStack = 1 TO 128
*!*			l_cProgram = PROGRAM(l_nStack)+CHR(13)
*!*			IF EMPTY(l_cProgram)
*!*				EXIT
*!*			ELSE
*!*				l_cStack = "(" + ALLT(STR(l_nStack)) + ")..." + l_cProgram + l_cStack
*!*			ENDIF
*!*		ENDFOR

	l_cStack = l_cStack+CHR(13)+CHR(13)
    IF (FILE("c:\temp\mem.txt"))
      oFSO.DeleteFile("c:\temp\mem.txt",.T.)
    ENDIF      
	LIST MEMORY TO FILE c:\temp\mem.txt noconsole

	l_cStack = " [CALL STACK] " +REPL("*",7)+" " + l_cStack 

		c_erdetl = c_erdetl + l_cGeneral + l_cStack + ;
		  		                " [***DISPLAY STATUS]"+ REPL("*",7)
		*--Add list status info.
		m.ln_Fhndle = FOPEN(l_cStatusFile)
		IF m.ln_Fhndle > 0
		   	DO WHILE NOT FEOF(ln_Fhndle)
		      	lc_CurTxt = ALLTRIM(FGETS(ln_Fhndle))+CHR(13)
				c_erdetl = c_erdetl + lc_CurTxt
			ENDDO
		ENDIF
		=FCLOSE(ln_Fhndle)
	
		ERASE (l_cStatusFile)

		c_memtxt = c_memtxt+" [***DISPLAY MEMORY]"+REPL("*",74)

		*--Add list memory info.
*!*			ln_Fhndle = FOPEN(l_cMemoryFile)
*!*			IF ln_Fhndle > 0
*!*			   	DO WHILE NOT FEOF(ln_Fhndle)
*!*			      	c_CurTxt = ALLTRIM(FGETS(ln_Fhndle))+CHR(13)
*!*					c_memtxt= c_memtxt +lc_CurTxt
*!*				ENDDO
*!*			ENDIF
*!*			=FCLOSE(ln_Fhndle)
*--		ERASE (l_cMemoryFile)

		c_erdetl = c_erdetl+" [***"+p_cINIFile+"]"+;
		                  REPL("*",74) + " "

*!*		*--If ini file name is passed, add to memo field.
		IF !EMPTY(p_cINIFile)
			ln_Fhndle = FOPEN(p_cINIFile)
			IF ln_Fhndle > 0
			   	DO WHILE NOT FEOF(ln_Fhndle)
			      	lc_CurTxt = ALLTRIM(FGETS(ln_Fhndle))+CHR(13)
					c_erdetl = c_erdetl +lc_CurTxt
				ENDDO
			ENDIF
			=FCLOSE(ln_Fhndle)
		ELSE
		  c_erdetl = c_erdetl + " No INI file name passed. "
		ENDIF

		c_erdetl = c_erdetl +" [OTHER SETTINGS AND INFORMATION]"+ REPL("*",7)

	c_erdetl = c_erdetl +" Printer: "+p_cPrint+;
	                 "Console: "+p_cConsol+CHR(13)+;
	                 "Device: "+p_cDevice+CHR(13)+;
	                 "LAST_KEY: "+ALLTRIM(STR(p_nKeyPr))+CHR(13)+;
	                 "Current Directory: "+p_cCurDir+CHR(13)+;
	                 "[Cursor]: "+p_cCursSet+CHR(13)+;
	                 "Extra error Information: "+p_cExtra+CHR(13)+;
					_SCREEN.Caption
	p_cMsg=LEFT(p_cMsg,60)
	p_cCode=LEFT(p_cCode,60)
	c_place= LEFT("IN: "+ALLT(p_cModul)+" LINE:"+ALLT(STR(p_nLine)),100)
	p_cUser=LEFT(p_cUser,50)
	IF NOT USED('verrlog2')
*        USE C:\VFPFree\Global\verrlog IN 0
		c_path=dbf_use('data','GLOBAL','rts.ini') && ORIGINAL CODE
		USE (ADDBS(c_path)+'verrlog2') IN 0

*--		USE T:\VFPFree\Global\verrlog IN 0

	ENDIF	


	INSERT INTO verrlog2  ;
			(er_product,er_dttime,er_user,er_errnum,er_msg,er_code,er_place,er_detl,er_memdump) ;
			VALUES ;
			( ;
			p_cAppName ;
			,DATETIME() ;
			,pc_UserID ;
			,ALLT(STR(p_nErNo)) ;
			,p_cMsg;
			,p_cCode;
			,c_place;
			,ALLTRIM(c_erdetl);
			,ALLTRIM(c_memtxt) ;
			)

		APPEND MEMO verrlog2.er_memdump FROM (l_cMemoryFile)
	    lcStoreLine = "PSSQL: "
		REPLACE verrlog2.er_memdump WITH verrlog2.er_memdump + CRLF + CRLF + "*** Variable Error Information ***" + CRLF	    
	    DO CASE
	      CASE (TYPE("pc_PsSqlerr") = "U")
	        lcStoreValue = "pc_PsSql Does Not Exist"
	      CASE (ISNULL(pc_PsSqlerr))
	        lcStoreValue = "Not Found"
	      CASE (EMPTY(pc_PsSqlerr))
	        lcStoreValue = "No Value"
	      OTHERWISE
	        lcStoreValue = pc_PsSqlerr
    	ENDCASE
	    lcStoreLine = lcStoreLine + lcStoreValue
   		REPLACE verrlog2.er_memdump WITH verrlog2.er_memdump + lcStoreLine + CRLF
		ERASE (l_cMemoryFile)
&& 06/01/2011 - ADDED pl_QClCase		
&& 06/01/2010- Reset a QC job back to 'Ready-To-QC' due to an error
IF pl_QcProc OR pl_QCWCase OR pl_QClCase
** reset the jobs that were in a list with a job that caused an error and have not been yet issued.
				

		IF USED("OrigList")
			SELECT OrigList
			SCAN FOR QC_STATUS="QQ"

				pn_Tag=OrigList.QC_TAG
				PN_LRSNO =OrigList.QC_LRS_NO
				
				l_ok= ReleaseQCJob ( 1, OrigList.qc_sequence, OrigList.ID_tblw2header)
				
				*DO addlogline  WITH  pn_Tag, " Reset job was called from" + IIF(pl_QCWCase OR pl_QClCase	, "-Case level", "-Tag level") , " Mlerror.prg"
				SELECT OrigList
			ENDSCAN
		ENDIF


		STORE .F. TO pl_QcProc , pl_QCWCase, pl_QClCase


	ENDIF && 06/01/2010- Reset a QC job back to 'Ready-To-QC' due to an error

*!*		c_str= "INSERT INTO verrlog " + ;
*!*				"(er_product,er_datetime,er_user,er_errnum,er_msg,er_code,er_place,er_detl,er_memdump)" + ;
*!*				"VALUES " + ;
*!*				"(" + ;
*!*				"'&p_cAppName.'" + ;
*!*				",'"+TTOC(DATETIME())+"'"+ ;
*!*				",'&p_cUser.'" + ;
*!*				",'"+ALLT(STR(p_nErNo))+"'"+ ;
*!*				",'&p_cMsg.','&p_cCode.'"+ ;
*!*				",'&c_place.'" +;
*!*				","+c_erdetl+ ;
*!*				","+c_memtxt+ ;
*!*				")"

*!*		c_str= "INSERT INTO tblerrorlog " + ;
*!*				"(er_product,er_datetime,er_user,er_errnum,er_msg,er_code,er_place,er_detl)" + ;
*!*				"VALUES " + ;
*!*				"(" + ;
*!*				"'&p_cAppName.'" + ;
*!*				",'"+TTOC(DATETIME())+"'"+ ;
*!*				",'&p_cUser.'" + ;
*!*				",'"+ALLT(STR(p_nErNo))+"'"+ ;
*!*				",'&p_cMsg.','&p_cCode.'"+ ;
*!*				",'"+"IN: "+ALLT(p_cModul)+" LINE:"+ALLT(STR(p_nLine))+"'" +;
*!*				"," + c_erdetl + ;
*!*				")"
*!*		omed.sqlexecute(c_str)
		
*!*		*--Reselect old work area.
*!*		SELECT (l_nOldWrk)
ENDIF
*IF (ALLTRIM(goApp.CurrentUser.oRec.Dept) <> "IT")
IF (ALLTRIM(goApp.CurrentUser.oRec.Dept) <> "IT")
  GET_ERROR_DESCRIPTION(l_cGeneral) 
ENDIF  


*<07092021> WY save form properties to error log
LOCAL lcProps
lcProps = ""
DO PropExtractor WITH c_path, lcProps
replace verrlog2.er_prop WITH lcProps IN verrlog2
*</07092021>

*--Sound error tones.
DO CHIME

*--Display message to user.
c_message=("FATAL ERROR!"+CHR(13)+;
    "Program: "+p_cProg+CHR(13)+ ;
    "Line: "+ALLT(STR(p_nLine)))

=gfmessage(c_message)
*--=MESSAGEBOX(c_message)
*!*	o_message = CREATEOBJECT('rts_message',c_message)
*!*	o_message.SHOW

*--RELEASE o_message

*--=MESSAGEBOX(APP_ERROR_CRITICAL+CRLF+CRLF+ ;
*--    MESSAGE()+CRLF+CRLF+ ;
*--    "Program: "+p_cProg+CHR(13)+ ;
*--    "Line: "+ALLT(STR(p_nLine)), ;
*--    16, APP_NAME)

*--Rollback all transactions, and revert all tables with buffering.

*--Loop through all open forms.

l_nScreens = _Screen.FormCount

FOR l_iFrmIndex = 1 TO l_nScreens
  SET DATASESSION TO _screen.Forms[l_iFrmIndex].DataSessionID

  *--Rollback all transactions.
  Do While (TXNLevel() > 0)
    RollBack
  EndDo
  
  *--Get all open tables
  l_nUsed = AUSED(l_aUsed)
  FOR l_iTblIndex = 1 TO l_nUsed
    *--Revert table if buffering.
    IF CURSORGETPROP("BUFFER", l_aUsed[l_iTblIndex, 1]) > 1
      =TABLEREVERT(.T., l_aUsed[l_iTblIndex, 1])
    ENDIF
  ENDFOR
ENDFOR
SET DATASESSION TO l_nOldDataS

*--Return to Master (kind of)

*--goapp.exitsystem(.t.)

CLEAR EVENTS
*--WAIT "Clearing..." WIND NOWA

POP KEY ALL
RELEASE WINDOWS calculator,puzzle,help

ON ERROR
ON ESCAPE
ON KEY

SET SYSMENU TO           DEFAULT
SET TALK                 OFF
SET ALTERNATE            OFF
SET ANSI                 OFF
SET AUTOSAVE             ON
SET BELL                 ON
SET BLINK                ON
SET BLOCKSIZE TO         33
SET BRSTATUS             OFF
SET CARRY                OFF
SET CLEAR                OFF
SET COLLATE TO           "MACHINE"             
SET COMPATIBLE           OFF
SET CONFIRM              OFF
SET CONSOLE              ON
SET CPDIALOG             OFF
SET CURSOR               ON
SET DELETED              ON
SET DEVICE TO            SCREEN
SET ECHO                 OFF
SET ESCAPE               ON
SET EXACT                OFF
SET EXCLUSIVE            OFF
SET PRINTER              TO
SET PROCEDURE            TO
SET RESOURCE             ON
SET SAFETY               OFF
SET CLOCK                STATUS
SET HELP ON

*CAPSLOCK(.F.)
CLEAR windows
*--DEACTIVATE WINDOWS ALL
CLEAR READ ALL
CLEAR
CLOSE ALL
RELEASE ALL
*SET LIBRARY TO
*SET CLASSLIB To

WAIT CLEAR

ON SHUTDOWN 

*--QUIT

RETURN TO MASTER

**************
* Sound tones
**************
PROCEDURE Chime
LOCAL l_iCount

FOR l_iCount = 1 TO 1
  SET BELL TO 1650-(18*l_iCount), 3
  ?? CHR(7)
  SET BELL TO 650-(5*l_iCount),3
  ?? CHR(7)
ENDFOR  &&--l_iCount

SET BELL TO

RETURN
*--End of Chime()
**EOF**
*
* Generates and Displays Fatal RTS Error Message Form
*
PROCEDURE GET_ERROR_DESCRIPTION 
  PARAMETERS lcGeneral
  
  lcLrsNO = IIF (TYPE('pc_lrsno') <> "U" AND TYPE('pc_lrsno') <> "L",ALLTRIM(pc_lrsno),"")
  lcTag = IIF(TYPE('pc_tag') <> "U" AND TYPE('pc_tag') <> "L",ALLTRIM(pc_tag),"")
    
  oErrorDescriptionForm = CREATEOBJECT('form')
  oErrorDescriptionForm.WindowType = 1
  oErrorDescriptionForm.Width = 472
  oErrorDescriptionForm.Top = 0
  oErrorDescriptionForm.Left = 0
  oErrorDescriptionForm.Height = 358
  oErrorDescriptionForm.Caption = "RTS Error Information Screen"
  oErrorDescriptionForm.AlwaysOnTop = .T.
  oErrorDescriptionForm.AutoCenter = .T.
  oErrorDescriptionForm.Closable = .F.
  
* Create Ok Button
  oErrorDescriptionForm.ADDOBJECT('cmdOk','COMMANDBUTTON')
  oErrorDescriptionForm.cmdOk.Visible = .T.
  oErrorDescriptionForm.cmdOk.caption = "Ok"
  oErrorDescriptionForm.cmdOk.Top = 276 && 287
  oErrorDescriptionForm.cmdOk.Left = 168 && 120
  oErrorDescriptionForm.cmdOk.Height = 27
  oErrorDescriptionForm.cmdOk.Width = 60
  oErrorDescriptionForm.cmdOk.TabIndex = 2
* Create Cancel Button
*  oErrorDescriptionForm.ADDOBJECT('cmdCancel','COMMANDBUTTON')
*  oErrorDescriptionForm.cmdCancel.Visible = .T.
*  oErrorDescriptionForm.cmdCancel.caption = "Cancel"
*  oErrorDescriptionForm.cmdCancel.Top = 287
*  oErrorDescriptionForm.cmdCancel.Left = 207
*  oErrorDescriptionForm.cmdCancel.Height = 27
*  oErrorDescriptionForm.cmdCancel.Width = 60
*  oErrorDescriptionForm.cmdCancel.TabIndex = 3
* Create RT# label
  oErrorDescriptionForm.ADDOBJECT('labelRTNo','LABEL')
  oErrorDescriptionForm.labelRTNo.Visible = .T.
  oErrorDescriptionForm.labelRTNo.Top = 27
  oErrorDescriptionForm.labelRTNo.Left = 36
  oErrorDescriptionForm.labelRTNo.Height = 17
  oErrorDescriptionForm.labelRTNo.Width = 40
  oErrorDescriptionForm.labelRTNo.Caption = "RT#" 
* Create Tag label
  oErrorDescriptionForm.ADDOBJECT('labelTagNo','LABEL')
  oErrorDescriptionForm.labelTagNo.Visible = .T.
  oErrorDescriptionForm.labelTagNo.Top = 62
  oErrorDescriptionForm.labelTagNo.Left = 36
  oErrorDescriptionForm.labelTagNo.Height = 17
  oErrorDescriptionForm.labelTagNo.Width = 40
  oErrorDescriptionForm.labelTagNo.Caption = "Tag"  
* Create EditBox Description Label
  oErrorDescriptionForm.ADDOBJECT('labelDescription','LABEL')
  oErrorDescriptionForm.labelDescription.Visible = .T.
  oErrorDescriptionForm.labelDescription.Top = 91
  oErrorDescriptionForm.labelDescription.Left = 36
  oErrorDescriptionForm.labelDescription.Height = 17
  oErrorDescriptionForm.labelDescription.Width = 141
  oErrorDescriptionForm.labelDescription.Caption = "Enter Error Description"   
  oErrorDescriptionForm.labelDescription.FontBold = .T.
  oErrorDescriptionForm.labelDescription.BackStyle = 0
* Create RT# TextBox
  oErrorDescriptionForm.ADDOBJECT('textBoxRTNo','TextBox')
  oErrorDescriptionForm.textBoxRTNo.Visible = .T.
  oErrorDescriptionForm.textBoxRTNo.Top = 24
  oErrorDescriptionForm.textBoxRTNo.Left = 76
  oErrorDescriptionForm.textBoxRTNo.Height = 23
  oErrorDescriptionForm.textBoxRTNo.Width = 100
  oErrorDescriptionForm.textBoxRTNo.TabStop = .F.
  oErrorDescriptionForm.textBoxRTNo.ReadOnly = .T.
  oErrorDescriptionForm.textBoxRTNo.Enabled = .T.
  oErrorDescriptionForm.textBoxRTNo.Value = lcLrsNo
* Create Tag TextBox
  oErrorDescriptionForm.ADDOBJECT('textBoxTag','TextBox')
  oErrorDescriptionForm.textBoxTag.Visible = .T.
  oErrorDescriptionForm.textBoxTag.Top = 59
  oErrorDescriptionForm.textBoxTag.Left = 76
  oErrorDescriptionForm.textBoxTag.Height = 23
  oErrorDescriptionForm.textBoxTag.Width = 100
  oErrorDescriptionForm.textBoxTag.TabStop = .F. 
  oErrorDescriptionForm.textBoxTag.ReadOnly = .T.
  oErrorDescriptionForm.textBoxTag.Enabled = .T.   
  oErrorDescriptionForm.textBoxTag.Value = lcTag  
* Create EditBox
  oErrorDescriptionForm.ADDOBJECT('editBoxErrorDescription','EditBox')
  oErrorDescriptionForm.editBoxErrorDescription.Visible = .T.
  oErrorDescriptionForm.editBoxErrorDescription.Top = 113
  oErrorDescriptionForm.editBoxErrorDescription.Left = 36
  oErrorDescriptionForm.editBoxErrorDescription.Height = 144
  oErrorDescriptionForm.editBoxErrorDescription.Width = 384
  oErrorDescriptionForm.editBoxErrorDescription.TabIndex = 1
* Add Property To _Screen to Retrieve Information
  _Screen.AddProperty("errorDescription","")
  _Screen.AddProperty("errorRTNumber","")
  _Screen.AddProperty("errorTagNumber","")
* Bind oErrorDescriptionForm to Event Class
  oHandler=NEWOBJECT("myhandler")
  BINDEVENT(oErrorDescriptionForm.cmdOk, "click" , oHandler, "okButtonClicked")
*  BINDEVENT(oErrorDescriptionForm.cmdCancel, "click" , oHandler, "cancelButtonClicked")
  BINDEVENT(oErrorDescriptionForm.editBoxErrorDescription, "rightclick" , oHandler, "rightClickEvent")
  BINDEVENT(oErrorDescriptionForm, "init" , oHandler, "initEvent")

* Display Error Description Form
  oErrorDescriptionForm.Visible = .T.
  oErrorDescriptionForm.editBoxErrorDescription.SetFocus
  oErrorDescriptionForm.Show(1)
  DO generateFatalErrorEmail WITH ALLTRIM(_Screen.errorRtNumber),ALLTRIM(_Screen.errorTagNumber), ;
                                  ALLTRIM(_Screen.errorDescription),ALLTRIM(PC_USERID),ALLTRIM(lcGeneral)                                                              
ENDPROC
**********************************************************************
FUNCTION DBF_USE
LPARAMETERS lcSection, lcVarable, lcINI

LOCAL lc_GlobalPath

DECLARE INTEGER GetPrivateProfileString IN Win32API AS GetPrivStr ;
                    String cSec, ;
                    String cKey, ;
                    String cDef, ;
                    String @cBuf, ;
                    Integer nBufSize, ;
                    String cINIFile

    lc_GlobalPath = SPACE(500)

    ln_len=GetPrivStr(lcSection,lcVarable,"\",@lc_GlobalPath,500,SYS(5)+CURDIR()+ALLTRIM(lcINI))

    lc_GlobalPath= LEFT(lc_GlobalPath,ln_Len)

RETURN lc_GlobalPath

***************************************************************************
*-- Procedure: generateFatalErrorEmail
*-- Abstract: Send Information to IT Department to help solve fatal RTS errors
***************************************************************************
PROCEDURE generateFatalErrorEmail
  PARAMETER lc_lrsno, lc_Tag, c_email, lcUserID, lcGeneral 
  
  LOCAL loOutlook AS Outlook.Application
  LOCAL loNameSpace AS Outlook.NameSpace 
  LOCAL loMailItem AS Outlook.MailItem
  LOCAL llShowItem AS Boolean
  
  #DEFINE olMailItem 0
  
  lcMemoryFileName = ADDBS(SYS(5)) + ADDBS(CURDIR()) + "MemoryFile.TXT"
  lcStatusFileName = ADDBS(SYS(5)) + ADDBS(CURDIR()) + "STATUSFILE.TXT"
  oFSO = CREATEOBJECT("Scripting.FileSystemObject")
  IF (FILE(lcMemoryFileName))
    oFSO.DeleteFile(lcMemoryFileName,.T.)
  ENDIF
  IF (FILE(lcStatusFileName))
    oFSO.DeleteFile(lcStatusFileName,.T.)
  ENDIF
  LIST MEMORY TO FILE (lcMemoryFileName) NOCONSOLE
  LIST STATUS TO (lcStatusFileName) NOCONSOLE
  loOutlook = CREATEOBJECT('Outlook.Application')
  loNameSpace = loOutlook.GetNamespace("MAPI")
  loNameSpace.Logon
  loMailItem = loOutlook.CreateItem( olMailItem ) && This creates the MailItem Object
  llShowItem = .T.
  lcSubject = "Fatal RTS Error " + "RT# " + lc_lrsno + "/" + "Tag # " + lc_Tag + ;
               "/" + ALLTRIM(lcUserID)
  lcBody = "Problem found for User " + ;
            lcUserID + " RT# " + lc_lrsno + ;
            " Tag # " + lc_Tag + CRLF + ;
            " " + CRLF + ;
            lcGeneral + " " + CRLF + ;
            "USER Description of Problem: " + CRLF + ;
            " " + CRLF +;
            c_email                 
  WITH loMailItem
    .Importance = 1
    .Subject =  lcSubject
*    .Recipients.Add("rknight@recordtrak.com")
    .Recipients.Add("helpdesk@recordtrak.com")
    .Body = lcBody  
    IF (FILE("c:\temp\error_screenprintbitmap.bmp"))
      .Attachments.Add("c:\temp\error_screenprintbitmap.bmp")
    ENDIF  
*    .Attachments.Add(lcMemoryFileName)             
    .Send && Calling this will cause a Security Dialog
  ENDWITH
  IF (FILE(lcMemoryFileName))
    oFSO.DeleteFile(lcMemoryFileName,.T.)
  ENDIF
  IF (FILE(lcStatusFileName))
    oFSO.DeleteFile(lcStatusFileName,.T.)
  ENDIF  
  IF (FILE("c:\temp\error_screenprintbitmap.bmp"))
    oFSO.DeleteFile("c:\temp\error_screenprintbitmap.bmp",.T.)
  ENDIF  
  SELECT verrlog2
  REPLACE er_emalinf WITH lcSubject + CRLF + ;
                          " " + CRLF + ;
                          lcBody 
                                              
  RETURN
ENDPROC 
  
DEFINE CLASS myhandler AS Session

   PROCEDURE initEvent
      oErrorDescriptionForm.editBoxErrorDescription.SetFocus
   ENDPROC
   
   PROCEDURE rightClickEvent
     LOCAL llcanundo, llcancut, llcancopy, llcanpaste, llcanclear, llcanselectall
   
     llcanundo = !oErrorDescriptionForm.editBoxErrorDescription.ReadOnly
     llcancut = oErrorDescriptionForm.editBoxErrorDescription.SelLength > 0 and !oErrorDescriptionForm.editBoxErrorDescription.ReadOnly
     llcancopy = oErrorDescriptionForm.editBoxErrorDescription.SelLength > 0
     llcanpaste = !oErrorDescriptionForm.editBoxErrorDescription.ReadOnly and !EMPTY(_cliptext)
     llcanclear = oErrorDescriptionForm.editBoxErrorDescription.SelLength > 0 and !oErrorDescriptionForm.editBoxErrorDescription.ReadOnly
     llcanselectall = .T.
     
     DEFINE POPUP shortcut SHORTCUT RELATIVE    FROM MROW(),MCOL()
       DEFINE BAR _med_undo OF shortcut PROMPT IIF(llcanundo, "\<Undo", ;
                                                   "\Undo")
       DEFINE BAR 2 OF shortcut PROMPT "\-"
       DEFINE BAR _med_cut OF shortcut PROMPT IIF(llcancut, "C\<ut", ;
                                                            "\Cut")
       DEFINE BAR _med_copy OF shortcut PROMPT IIF(llcancopy, "\<Copy", ;
                                                              "\Copy")
       DEFINE BAR _med_paste OF shortcut PROMPT IIF(llcanpaste, "\<Paste", ;
                                                                "\Paste")
       DEFINE BAR _med_clear OF shortcut PROMPT IIF(llcanclear, "\<Delete", ;
                                                                "\Delete")
       DEFINE BAR 7 OF shortcut PROMPT "\-"
       DEFINE BAR _med_slcta OF shortcut PROMPT IIF(llcanselectall, "Select \<All",    "\Select All")
       ACTIVATE POPUP shortcut
       
   ENDPROC
   
   PROCEDURE okButtonClicked

     IF (!EMPTY(oErrorDescriptionForm.editBoxErrorDescription.Value))
       _Screen.errorDescription = oErrorDescriptionForm.editBoxErrorDescription.Value
       _Screen.errorRTNumber = oErrorDescriptionForm.textBoxRTNo.Value
       _Screen.errorTagNumber = oErrorDescriptionForm.textBoxTag.Value
       oErrorDescriptionForm.Release
     ELSE
       WAIT WINDOW "Please enter a description before clicking the Ok Button... Press the Enter Key to Continue" 
       oErrorDescriptionForm.editBoxErrorDescription.SetFocus()       
     ENDIF      

     RETURN
   ENDPROC  
   
   PROCEDURE cancelButtonClicked
     oErrorDescriptionForm.release 
     
     RETURN
   ENDPROC
ENDDEFINE

FUNCTION saveScreenPrintAsBitMap AS Boolean
  Parameters lcFileName As String, lnKeySelection AS Integer
*
* [1]
*
* Storing content of the Clipboard to a bitmap file.
*
* http://www.news2news.com/vfp/?example=189&function=42&xpg=
*
* Storing content of the Clipboard to a bitmap file.
*
* http://www.news2news.com/vfp/?example=189&function=42&xpg=
*
* GDI+: Storing content of the Clipboard to a bitmap file
* Printing the image of a FoxPro form
* Storing screen shot of a form to a bitmap file
* Using the LoadImage() to display a bitmap file on the main VFP window
* How to print a bitmap file
* GDI+: copying to the Clipboard (a) image of active FoxPro window/form, (b) image file
*
* [2]
*
* Article related to saving bitmap files.
* http://www.portalfox.com/article.php?sid=900
*
* [3]
* Support
* http://msdn.microsoft.com/library/ 
*
* Virtual Keys, Standard Set
*
*integer VK_LBUTTON = 01
*integer VK_RBUTTON = 02
*integer VK_CANCEL = 03
*integer VK_MBUTTON = 04 /* NOT contiguous with L & RBUTTON */

*integer VK_BACK = 08
*integer VK_TAB = 09

*integer VK_CLEAR = 12
*integer VK_RETURN = 13

*integer VK_SHIFT = 16
*integer VK_CONTROL = 17
*integer VK_MENU = 18
*integer VK_PAUSE = 19
*integer VK_CAPITAL = 20

*integer VK_ESCAPE = 27

*integer VK_SPACE = 32
*integer VK_PRIOR = 33
*integer VK_NEXT = 34
*integer VK_END = 35
*integer VK_HOME = 36
*integer VK_LEFT = 37
*integer VK_UP = 38
*integer VK_RIGHT = 39
*integer VK_DOWN = 40
*integer VK_SELECT = 21
*integer VK_PRINT = 42
*integer VK_EXECUTE = 43
*integer VK_SNAPSHOT = 44
*integer VK_INSERT = 45
*integer VK_DELETE = 46
*integer VK_HELP = 47

* VK_0 thru VK_9 are the same as ASCII '0' thru '9' (= 30 - = 39) */
* VK_A thru VK_Z are the same as ASCII 'A' thru 'Z' (= 41 - = 5A) */

*integer VK_LWIN = 91
*integer VK_RWIN = 92
*integer VK_APPS = 93

*integer VK_NUMPAD0 = 96
*integer VK_NUMPAD1 = 97
*integer VK_NUMPAD2 = 97
*integer VK_NUMPAD3 = 98
*integer VK_NUMPAD4 = 99
*integer VK_NUMPAD5 = 100
*integer VK_NUMPAD6 = 101
*integer VK_NUMPAD7 = 102
*integer VK_NUMPAD8 = 103
*integer VK_NUMPAD9 = 104
*integer VK_MULTIPLY = 105
*integer VK_ADD = 106
*integer VK_SEPARATOR = 107
*integer VK_SUBTRACT = 108
*integer VK_DECIMAL = 109
*integer VK_DIVIDE = 110
*integer VK_F1 = 111
*integer VK_F2 = 113
*integer VK_F3 = 114
*integer VK_F4 = 115
*integer VK_F5 = 116
*integer VK_F6 = 117
*integer VK_F7 = 118
*integer VK_F8 = 119
*integer VK_F9 = 120
*integer VK_F10 = 121
*integer VK_F11 = 122
*integer VK_F12 = 123
*integer VK_F13 = 124
*integer VK_F14 = 125
*integer VK_F15 = 126
*integer VK_F16 = 127
*integer VK_F17 = 128
*integer VK_F18 = 129
*integer VK_F19 = 130
*integer VK_F20 = 131
*integer VK_F21 = 132
*integer VK_F22 = 133
*integer VK_F23 = 134
*integer VK_F24 = 135
*integer VK_NUMLOCK = 144
*integer VK_SCROLL = 145
*
*********************
* API DECLARATIONS  *
*********************
*
* REFERENCE: http://msdn.microsoft.com/library/en-us/winui/winui/windowsuserinterface/userinput/keyboardinput/keyboardinputreference/keyboardinputfunctions/getactivewindow.asp
* REFERENCE: http://msdn.microsoft.com/library/en-us/winui/winui/windowsuserinterface/dataexchange/clipboard/clipboardreference/clipboardfunctions/getclipboarddata.asp
* REFERENCE: http://msdn.microsoft.com/library/en-us/winui/winui/windowsuserinterface/dataexchange/clipboard/clipboardreference/clipboardfunctions/openclipboard.asp
* REFERENCE: http://msdn.microsoft.com/library/en-us/gdi/devcons_1vsk.asp
* REFERENCE: http://msdn.microsoft.com/library/en-us/gdi/pantdraw_0hcz.asp
* REFERENCE: http://msdn.microsoft.com/library/en-us/gdi/devcons_499f.asp
* REFERENCE: http://msdn.microsoft.com/library/en-us/gdi/devcons_2p2b.asp
* REFERENCE: http://msdn.microsoft.com/library/en-us/gdi/devcons_66hv.asp
* REFERENCE: http://msdn.microsoft.com/library/en-us/memory/base/globalfree.asp
* REFERENCE: http://msdn.microsoft.com/library/en-us/gdi/devcons_9pt1.asp
* REFERENCE: http://msdn.microsoft.com/library/en-us/gdi/devcons_912s.asp
* REFERENCE: http://msdn.microsoft.com/library/en-us/sysinfo/base/closehandle.asp
* REFERENCE: http://msdn.microsoft.com/library/en-us/memory/base/global_and_local_functions.asp
* REFERENCE: http://msdn.microsoft.com/library/en-us/fileio/base/createfile.asp
* REFERENCE: http://msdn.microsoft.com/library/en-us/kmarch/hh/kmarch/k109_63d9f0fb-d698-4707-9018-de2fa851a94b.xml.asp
* REFERENCE: http://eric.aling.tripod.com/PB/tips/pbtip36.htm
* REFERENCE: http://msdn.microsoft.com/library/en-us/gdi/bitmaps_7gms.asp
*
* To press a key, use:
*     keybd_event(ai_key,0,0,0)    
* To release a key, use:
*     keybd_event(ai_key,0,2,0)
*
   DECLARE INTEGER GetActiveWindow IN user32
   DECLARE INTEGER GetClipboardData IN user32 INTEGER uFormat
   DECLARE INTEGER OpenClipboard IN user32 INTEGER hwnd
   DECLARE INTEGER CloseClipboard IN user32
   DECLARE INTEGER DeleteObject IN gdi32 INTEGER hObject
   DECLARE INTEGER GetWindowDC IN user32 INTEGER hwnd
   DECLARE INTEGER CreateCompatibleDC IN gdi32 INTEGER hdc
   DECLARE INTEGER DeleteDC IN gdi32 INTEGER hdc
   DECLARE INTEGER ReleaseDC IN user32 ;
                   INTEGER hwnd,;
                   INTEGER hdc
   DECLARE INTEGER GlobalFree IN kernel32 INTEGER hMem
   DECLARE INTEGER GetObjectType IN gdi32 INTEGER h
   DECLARE INTEGER CloseHandle IN kernel32 INTEGER hObject
   DECLARE INTEGER GlobalAlloc IN kernel32 ;
                   INTEGER wFlags,;
                   INTEGER dwBytes
   DECLARE INTEGER GetObject IN gdi32 AS GetObjectA;
                   INTEGER handleGrafico,;
                   INTEGER cbBuffer,;
                   STRING @lpvObject
   Declare RtlZeroMemory IN kernel32 As ZeroMemory;
                   INTEGER dest,;
                   INTEGER numBytes
   DECLARE INTEGER GetDIBits IN gdi32;
                   INTEGER hdc,;
                   INTEGER hbmp,;
                   INTEGER uStartScan,;
                   INTEGER cScanLines,;
                   INTEGER lpvBits,;
                   STRING @lpbi,;
                   INTEGER uUsage
   DECLARE INTEGER CreateFile IN kernel32;
                   STRING lpFileName,;
                   INTEGER dwDesiredAccess,;
                   INTEGER dwShareMode,;
                   INTEGER lpSecurityAttr,;
                   INTEGER dwCreationDisp,;
                   INTEGER dwFlagsAndAttrs,;
                   INTEGER hTemplateFile
   DECLARE INTEGER keybd_event IN Win32API ;
           INTEGER, INTEGER, INTEGER, INTEGER
   DECLARE integer Sleep IN WIN32API integer           
 
   #DEFINE OBJ_BITMAP 7
   
   LOCAL hClipBmp, lcDestinationFile

   _CLIPTEXT = ""
   sleep(600)
   keybd_event(lnKeySelection,0,0,0) 
   sleep(900)   
   keybd_event(lnKeySelection,0,2,0)

*   =keybd_event(lnKeySelection, 1, 0, 0)
   sleep(1600)
   
   lcDestinationFile = lcFileName
   = OpenClipboard (0)
   hClipBmp = GetClipboardData ( CF_BITMAP )
   = CloseClipboard( )
   IF hClipBmp = 0 Or GetObjectType(hClipBmp) <> OBJ_BITMAP
     RETURN .F.
   ENDIF
   = image_to_file( hClipBmp, lcDestinationFile )
   = DeleteObject( hClipBmp )
   
   RETURN
ENDPROC
*
PROCEDURE image_to_file( hBitmap, lcDestinationFile )
*
  #DEFINE DIB_RGB_COLORS 0
  #DEFINE BFHDR_SIZE 14 && BITMAPFILEHEADER
  #DEFINE GENERIC_WRITE 1073741824 && 0x40000000
  #DEFINE FILE_SHARE_WRITE 2
  #DEFINE CREATE_ALWAYS 2
  #DEFINE INVALID_HANDLE_VALUE -1
*
  PRIVATE pnWidth, pnHeight, pnBitsSize, pnRgbQuadSize, pnBytesPerScan
  LOCAL lpBitsArray, lcBInfo
  LOCAL lnhwnd, hdc, hMemDC
  LOCAL hFile, lnFileSize, lnOffBits, lcBFileHdr
*
  STORE 0 TO pnWidth, pnHeight, pnBytesPerScan, pnBitsSize, pnRgbQuadSize
  = GetBitmapDimensions( hBitmap, @pnWidth, @pnHeight )
  lcBInfo = InitBitmapInfo( )
  lpBitsArray = InitBitsArray( )
  lnhwnd = GetActiveWindow( )
  hdc = GetWindowDC( lnhwnd )
  hMemDC = CreateCompatibleDC(hdc )
  = ReleaseDC( lnhwnd, hdc )
  = GetDIBits( hMemDC, hBitmap, 0, pnHeight, lpBitsArray, @lcBInfo, DIB_RGB_COLORS )
  lnFileSize = BFHDR_SIZE + BHDR_SIZE + pnRgbQuadSize + pnBitsSize
  lnOffBits = BFHDR_SIZE + BHDR_SIZE + pnRgbQuadSize
  lcBFileHdr = "BM" + num2DWord( lnFileSize ) + num2DWord( 0 ) + num2DWord( lnOffBits )
  hFile = CreateFile (lcDestinationFile,;
                      GENERIC_WRITE,;
                      FILE_SHARE_WRITE, 0,;
                      CREATE_ALWAYS,;
                      FILE_ATTRIBUTE_NORMAL, 0 ) 
   IF hFile <> INVALID_HANDLE_VALUE
     = String2File( hFile, @lcBFileHdr )
     = String2File( hFile, @lcBInfo )
     = Ptr2File( hFile, lpBitsArray, pnBitsSize )
     = CloseHandle( hFile )
   ELSE
     RETURN .F.
   ENDIF
   = GlobalFree( lpBitsArray )
   = DeleteDC( hMemDC )
*
   RETURN
ENDPROC
*
************************
* GETBITMAPDIMENSIONS. *
************************
*
PROCEDURE GetBitmapDimensions( hBitmap, lnWidth, lnHeight )
*
  #DEFINE BITMAP_STRU_SIZE 24
*
  LOCAL lcBuffer
*
  lcBuffer = REPLICATE( CHR( 0 ), BITMAP_STRU_SIZE )
  IF GetObjectA( hBitmap, BITMAP_STRU_SIZE, @lcBuffer ) <> 0
    lnWidth = buffer2DWord ( SUBSTR( lcBuffer, 5,4 ) )
    lnHeight = buffer2DWord ( SUBSTR( lcBuffer, 9,4 ) )
  ENDIF
*
  RETURN
ENDPROC
*
*****************
* BUFFER2DWORD. *
*****************
*
FUNCTION buffer2DWord (lcBuffer)

  RETURN ASC(SUBSTR(lcBuffer, 1,1)) + ;
         ASC(SUBSTR(lcBuffer, 2,1)) * 256 +;
         ASC(SUBSTR(lcBuffer, 3,1)) * 65536 +;
         ASC(SUBSTR(lcBuffer, 4,1)) * 16777216 
ENDFUNC
*
*************
* PTR2FILE. *
*************
*
PROCEDURE Ptr2File( hFile, lnPointer, lnBt2Write )
*
  DECLARE INTEGER WriteFile IN kernel32;
                  INTEGER hFile ,;
                  INTEGER lpBuffer ,;
                  INTEGER nBt2Write ,;
                  INTEGER @lpBtWritten ,;
                  INTEGER lpOverlapped
*
  = WriteFile( hFile, lnPointer, lnBt2Write, 0, 0 )
*
  RETURN
ENDPROC
*
*******************
* INITBITMAPINFO. *
*******************
*
PROCEDURE InitBitmapInfo( lcBIHdr )
*
  #DEFINE BI_RGB 0
  #DEFINE RGBQUAD_SIZE 4
*
  LOCAL lnBitsPerPixel, lcBIHdr, lcRgbQuad
*
  lnBitsPerPixel = 24
  pnBytesPerScan = Int((pnWidth * lnBitsPerPixel)/8)
  IF MOD( pnBytesPerScan, 4 ) <> 0
    pnBytesPerScan = pnBytesPerScan + 4 - MOD( pnBytesPerScan, 4 )
  ENDIF 
  lcBIHdr = num2DWord( BHDR_SIZE ) + num2DWord( pnWidth ) +;
  num2DWord( pnHeight ) + num2word( 1 ) + num2word( lnBitsPerPixel ) +;
  num2DWord( BI_RGB ) + REPLICATE( CHR( 0 ), 20 )
  IF lnBitsPerPixel <= 8
    pnRgbQuadSize = ( 2^lnBitsPerPixel ) * RGBQUAD_SIZE
    lcRgbQuad = REPLICATE( CHR( 0 ), pnRgbQuadSize )
  ELSE
    lcRgbQuad = SPACE( 0 )
  ENDIF
*
  RETURN lcBIHdr + lcRgbQuad
ENDPROC
*
******************
* INITBITSARRAY. *
******************
*
PROCEDURE InitBitsArray( )
*
  #DEFINE GMEM_FIXED 0
*
  LOCAL lnPTR
*
  pnBitsSize = pnHeight * pnBytesPerScan
  lnPTR        = GlobalAlloc( GMEM_FIXED, pnBitsSize )
  = ZeroMemory( lnPTR, pnBitsSize )
*
  RETURN lnPTR
ENDPROC
*
****************
* STRING2FILE. *
****************
*
PROCEDURE String2File( hFile, lcBuffer )
*
  DECLARE INTEGER WriteFile IN kernel32;
          INTEGER hFile ,;
          STRING @lpBuffer ,;
          INTEGER nBt2Write ,;
          INTEGER @lpBtWritten ,;
          INTEGER lpOverlapped
*
  = WriteFile( hFile, @lcBuffer, LEN( lcBuffer ), 0, 0 )
*
  RETURN
ENDPROC
*
*************
* NUM2WORD. *
*************
*
FUNCTION num2Word( lnValor )
   
  RETURN CHR( MOD ( m.lnValor, 256 ) ) + CHR( INT( m.lnValor/256 ) )
ENDFUNC
*
**************
* NUM2DWORD. *
**************
*
FUNCTION num2DWord( lnValor )
*
  #DEFINE lnM0 256
  #DEFINE lnM1 65536
  #DEFINE lnM2 16777216
*
  LOCAL lnV0, lnV1, lnV2, lnV3
*
  lnV3 = INT( lnValor/lnM2 )
  lnV2 = INT( ( lnValor - lnV3 * lnM2 ) / lnM1 )
  lnV1 = INT( ( lnValor - lnV3 * lnM2 - lnV2 * lnM1 ) / lnM0 )
  lnV0 = MOD( lnValor, lnM0 )
*
  RETURN CHR( lnV0 ) + CHR( lnV1 ) + CHR( lnV2 ) + CHR( lnV3 )
*
ENDFUNC 