

PUBLIC  oform1 as Object

oForm1=NEWOBJECT("form1")  
oForm1.addproperty ('cPdfFileName') 
oform1.cPdfFileName =ALLTRIM(patemplist(1,3))+ ALLTRIM(patemplist(1,4))
oform1.ShowPdf()
oform1.txtPdfName.Value =ALLTRIM(patemplist(1,3))+ ALLTRIM(patemplist(1,4))
oForm1.icon ="C:\rts2k5\Client\Media\image.ico"
oForm1.Show()
RETURN
 
DEFINE CLASS form1 AS form 

 
	Autocenter = .T.
	Height = 520
	Width = 741
	Caption = "View PDF"
	Name = "Form1" 
	* How long to wait for PDF to load
	nPdfLoadTimeout = 95	
 
	ADD OBJECT txtpdfname AS textbox WITH ;
		Top = 471, Left = 108, Height = 23, Width = 499, ;
		ReadOnly = .T., Name = "txtPdfName"
 
	ADD OBJECT command1 AS commandbutton WITH ;
		Top = 469, Left = 623, Height = 27, Width = 84, ;
		Caption = "Exit", Name = "Command1"
 
	ADD OBJECT owb AS olecontrol WITH ;
		Top = 24, Left = 12, Height = 433, Width = 709, ;
		OleClass = "Shell.Explorer.2", Name = "oWB"
 
	ADD OBJECT label1 AS label WITH ;
		Height = 17, Left = 36, Top = 474, Width = 63, ;
		Caption = "PDF Name", Name = "Label1"
		

 
	PROCEDURE Refresh
		* Required in VFP8 and earlier to prevent an error
		NODEFAULT
	ENDPROC
 
	PROCEDURE ShowPdf
		LOCAL lnSeconds
		* Clear Web browser control by loading blank page
		Thisform.oWB.OBJECT.Navigate2("About:Blank")
		DOEVENTS
		* Wait for load to complete
		lnSeconds = SECONDS()
		DO WHILE (Thisform.oWB.OBJECT.Busy OR Thisform.oWB.OBJECT.ReadyState <> 4) ;
				AND (SECONDS() - lnSeconds) < This.nPdfLoadTimeout
			DOEVENTS
		ENDDO 
		FOR I = 1 TO 8 STEP 1
		NEXT I
		DOEVENTS
		* Load PDF
		WAIT WINDOW NOWAIT "Loading PDF ..."
		Thisform.oWB.OBJECT.Navigate2(Thisform.cPdfFileName)
		DOEVENTS
		* Wait for PDF to load
		lnSeconds = SECONDS()
		DO WHILE (Thisform.oWB.OBJECT.Busy OR Thisform.oWB.OBJECT.ReadyState <> 4) ;
				AND (SECONDS() - lnSeconds) < This.nPdfLoadTimeout
			DOEVENTS
		ENDDO
		FOR I = 1 TO 8 STEP 1
		NEXT I
		
		DOEVENTS
		WAIT CLEAR 
		* PDF display can be adjusted as shown in AdjustPdfView method 
 		*   Uncomment next line if you want to do that and add AdjustPdfView method to the form/class
		*This.AdjustPdfView()
 
	ENDPROC 
	PROCEDURE command1.Click
		* Get PDF file name
		&&Thisform.cPdfFileName = GETFILE("pdf")
				
		*DO ERRORCATCH IN viewpdf
		IF USED('TEMPLIST')
		SELECT 	TEMPLIST
		USE
		ENDIF
 		RELEASE oform1
 			
 		RELEASE oWB
		* Display the name in the textbox
*!*			Thisform.txtPdfName.Value = Thisform.cPdfFileName
*!*			IF NOT EMPTY(Thisform.cPdfFileName)
*!*				* Display PDF
*!*				Thisform.ShowPdf()
*!*			ENDIF
	ENDPROC
 
ENDDEFINE

PROCEDURE ERRORCATCH
LOCAL loLocator, loWMI, loProcesses, loProcess, llIsRunning
loLocator 	= CREATEOBJECT('WBEMScripting.SWBEMLocator')
loWMI		= loLocator.ConnectServer() 
loWMI.Security_.ImpersonationLevel = 3  		&& Impersonate
 
loProcesses	= loWMI.ExecQuery([SELECT * FROM Win32_Process ])
llIsRunning = .F.
c_Temp = ADDBS(MLPriPro("R", "RTS.INI", "Data","JTEMP", "\")) + "TEMP\"
C_TMP=c_Temp +ALLTRIM(pc_userid) +  ALLTRIM(STR(patemplist(1,1)))+"_"+ ALLTRIM(STR(patemplist(1,2))) + ".TXT"
IF FILE (  C_TMP)
	DELETE FILE (C_TMP)
ENDIF
n_Count=0
IF loProcesses.Count > 0
	FOR EACH loProcess in loProcesses
		n_Count=n_Count+1
		llIsRunning = .T.	
		StrToFile(STR(n_Count) + " - START     " ,C_TMP,1)  && To write to file
		StrToFile( loProcess.GETOBJECTTEXT_ ,C_TMP,1) && To write to file
		StrToFile(STR(n_Count) + " - END       " ,C_TMP,1)  && To write to file
		***loProcess.Terminate(0)	
	ENDFOR
ENDIF
RETURN llIsRunning
