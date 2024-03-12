Lparameters Sender, SenderName, Recipient,Cclist, Bcclist, Subject, Message, Attachment
Local lcMailServer, llReturn
lcMailServer=Alltrim(MLPriPro("R", "RTS.INI", "Data","EMAILSERVER", "\"))
llReturn=.T.
*
***********************************************
****** wwipstuff needed to send e-mails out -
****** If missing copy DLL to machine
***********************************************
*


**04/13/2016 : 	Windows 10/64 bit doe not have a privalage for  c:\windows: use c:\rts instead #38712

If pl_Is64bit
	If (!File('c:\RTS\WWIPSTUFF.DLL'))
		Copy File T:\Release\vfp\RTS\rtsDLL\WWIPSTUFF.Dll To C:\RTS\WWIPSTUFF.Dll
	Endif
Else
	If ( !File('c:\WINDOWS\SYSTEM32\WWIPSTUFF.DLL'))
		Copy File T:\Release\vfp\RTS\rtsDLL\WWIPSTUFF.Dll To C:\Windows\SYSTEM32\WWIPSTUFF.Dll
	Endif
Endif

oMail =  Createobj('wwipstuff.wwipstuff' , Iif (pl_Is64bit, 'C:\RTS\',''))

oMail.cMailServer  = lcMailServer
oMail.cSenderEmail = Sender
oMail.cSenderName  = SenderName
oMail.cRecipient   = Recipient
oMail.cCclist      = Cclist				&&& comma delinited carbon copy list
oMail.cBcclist     = Bcclist			&&& comma delinited blind  copy list
oMail.cSubject     = Subject
oMail.cMessage     = Message
oMail.cAttachment  = Attachment			&&& comma delinited attachment list

If Not oMail.SendMail()    				&& Send message and return immediately w/o result
	llReturn=.F.
Endif

Release oMail
Return llReturn

