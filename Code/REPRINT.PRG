Procedure Reprint
*** Reprint.prg - Reprint notices program
*******************************************
** EF 01/30/06 - added to the VFP RTS Code
*******************************************************************************
** Calls TheNotic, TxNotice
* kdl 09/21/04 - Restore parameter call to TheNotic
* 07/16/04  EF   Fix a bug ( see below)
* 03/24/04  EF   Add a new parameter to call to Thenotic
* 10/20/03  DMA  Auto-size window based on number of notices
* 10/16/03  DMA  Eliminate internal subroutines; use public global variables
* 07/26/02  DMA  Remove MODAL clause from selection window
* 11/12/01  EF   Texas Notices now stored in a separate DB
* 02/01/00  DMA  Remove gly2k references
* 10/20/99  DMA  Expand window for 4-character years in Y2K dates
*********************************************************************************
Parameters c_RTNum
Local l_cancel As Boolean, l_gotReq As Boolean, oMed1 As Object, ll_ok As Boolean
Store .F. To l_cancel, l_gotReq , ll_ok
* Turn on global "Notices being reprinted" flag
pl_RepNotc = .T.
pl_PdfReprin=.F.
Store .F. To pl_SpecRpsSrv,pl_StopPrtIss
pc_BatchRq=""
If Type("mv") = "U"
	Public mv
	mv = ""
Endif
&& Display notices so user can select which to print!!
NtcList = 1

Wait Window "Retrieving notices. Please wait." Nowait Noclear

*** get Request table
oMed1 = Createobject("generic.medgeneric")
C_STR=" exec  [dbo].[GetRequestByMasterId]  '" + c_RTNum + "'"

l_gotReq=oMed1.sqlexecute(C_STR,"Request")

If Not l_gotReq
	Wait Clear
	gfmessage(" Cannot open tblRequest to print Notices. Contact IT dept.")
	Return
ENDIF
**09/21/2017 : Released the TX docs/ removed test mode 
&&08/21/2017 Added TX notice
*!*	If checktest("TXDOCS")=.F. And Nvl(pl_txcourt,.F.)
If   Nvl(pl_txcourt,.F.)
	If  OpenTxNotice(c_RTNum )
		Select PickNotc
	Endif
Else
	If  OpenNotice(.F.)
		Select PickNotc
	Endif
Endif


Wait Clear
If Eof()
	gfmessage("There are no subpoenas or authorizations to print!")
	Return
Endif
If pl_Zicam
	gfmessage("Notices cannot be reprinted for cases in the Zicam litigation." + ;
		+ Chr(13) + " Contact Client Representative for assistance. ")
	Return
Endif
PUBLIC markNoticesAsPrinted
markNoticesAsPrinted=.T.
l_cancel=goApp.OpenForm("issued.frmPickNotic", "M", Master.id_tblMaster, Master.id_tblMaster)
Select PickNotc
Locate For Dtoc(TXN_DATE) =PickNotc2.TXN_DATE
If l_cancel
	Return
Endif
_Screen.MousePointer= 11

*!*	IF pl_ofcHous

*!*		DO txnotice WITH   IIF(ISNULL(TXN_DATE),{  /  /    },CTOD(TXN_DATE))
*!*		DO txnotice WITH .T., ALLTRIM( user_code), IIF(ISNULL(TXN_DATE),{  /  /    },CTOD(TXN_DATE))
*!*	ELSE
Local c_lrsno As String, dRun As Date
c_lrsno=""
** 09/16/15: re-print form the originals_ start

If Type ("MASTER.lrs_no")="C"
	c_lrsno=Alltrim(Master.lrs_no)
Else
	c_lrsno=Alltrim(Str(Master.lrs_no))
Endif
If Empty(c_lrsno) && no case is found/selected
	Return
Endif
** Check if an active job is in a queue : "RepOrigNot" with the statusid <4
oMed1.closealias("ChkRps")
C_STR=" select  dbo.CheckActiveRepOrigNot  ('" + c_lrsno + "','" + Dtoc(Date()) + "')"
l_gotReq=oMed1.sqlexecute(C_STR,"ChkRps")
If  Used('ChkRps')
	Select ChkRps
	If !Eof()
		n_activerps= ChkRps.Exp
	Endif
Endif
If  n_activerps=0
	Do Case
	Case Type("PickNotc.txn_date")="C"
		dRun=	Ctod(PickNotc.TXN_DATE)
	Case  Type("PickNotc.txn_date")="T"
		dRun=	Ttod(PickNotc.TXN_DATE)
	Case  Empty(Isnull( PickNotc.TXN_DATE ))
		dRun={  /  /    }
	Otherwise && date already
		dRun=	PickNotc.TXN_DATE
	Endcase


***02/18/2016: added a choice to do a new set - reprin trhe notices with a new data
	Local l_doit As Boolean
	l_doit=.F.
	lc_msg = "Do you want to generate a Notices Set with the edited (latest) RTS data?"
	O_MSSG = Createobject('rts_message_yes_no',lc_msg )
	O_MSSG.Show
	l_doit =Iif(O_MSSG.EXIT_MODE="YES",.T.,.F.)
	O_MSSG.Release

	If  l_doit
		ll_ok=.F.
	Else
		ll_ok= rpsnotice ( c_lrsno,dRun)
	Endif

** 09/16/15: re-print form the originals_ end
Else
** try later when an active jobs is done
	gfmessage("There is an active 'Reprint Notice' job in the RPS. Please wait till it is done and try again. See IT.")

Endif

*ENDIF
LOCAL lcSQLString
Select PickNotc
If !ll_ok
	DO CASE 
	CASE pl_txcourt
**08/21/2017 Added TX Notices
		Do Ztxnotice With  Iif(Type("txn_date")="C",Ctod(TXN_DATE),Ctod(Dtoc(TXN_DATE))), .T., pn_lrsNo		
	*-- 11/13/2020 MD added CA reprint	#186387
	CASE ALLTRIM(UPPER(pc_offcode))=="C"
	    DO ca_notice WITH "C", c_lrsno, Iif(Type("txn_date")="C",Ctod(TXN_DATE),Ctod(Dtoc(TXN_DATE)))		
	OTHERWISE 
		Do thenotic With .T.,Alltrim( user_code), Iif(Isnull( TXN_DATE),{  /  /    },;
			IIF(Type("txn_date")="C",Ctod(TXN_DATE),Ctod(Dtoc(TXN_DATE)))), .F.
	ENDCASE 
	*-- 01/08/21 MD #210073
	IF markNoticesAsPrinted=.T. AND !EMPTY(dRun)		  
		  lcSQLString="exec dbo.updateNoticesAsPrinted '"+ALLTRIM(c_RTNum)+"','"+Dtoc(dRun)+"','"+fixquote(ALLTRIM(goApp.CurrentUser.ntlogin))+"'"
		  oMed1.sqlexecute(lcSQLString)
	ENDIF 
	*-- 01/08/21 MD #210073
Endif
*!*	ENDIF
_Screen.MousePointer=0
Release mv, arntc
* Turn off global "Notices being reprinted" flag
pl_RepNotc = .F.
pl_noticng=.F.
gfmessage("Done!")
Release oMed1
Return
******************************************************************************************
Procedure OpenNotice
Parameters l_TXOffice
Local l_RetVal As Boolean, l_done As Boolean, C_STR As String, c_Alias As String
c_Alias=Alias()

omast=Createobject('medmaster')
omast.getitem(c_RTNum)
c_Clcode="'" + FIXQUOTE(Master.CL_CODE) + "'"
Store .F. To l_RetVal, l_done

c_Table =Iif(l_TXOffice, "tblTxNotice", "tblPsnotice")

C_STR="SELECT * " ;
	+ " FROM " + c_Table + "  with (nolock) " ;
	+ " where " + c_Table + ".Cl_Code =" + c_Clcode ;
	+ " and active =1 ORDER BY txn_date"

l_done=omast.sqlexecute(C_STR, "PickNotc")
If l_done Then
	l_RetVal=.T.
	=CursorSetProp("KeyFieldList", "Cl_code, USER_CODE", "PickNotc")
	Index On Alltrim(user_code)+Alltrim(CL_CODE) For .Not.PRINTED Tag TOPRINT Additive
	Index On Alltrim(user_code)+Alltrim(CL_CODE) Tag Reprint Additive
	Index On CL_CODE Tag CL_CODE Additive

Endif
Store .F. To pl_GotCase
*** Get case's vars
Do gfGetCas
Release omast
Select (c_Alias)
Return l_RetVal

******************************************************************************************
Procedure OpenTxNotice
Parameters lc_RTKEY
Local l_RetVal As Boolean, l_done As Boolean, C_STR As String, c_Alias As String
c_Alias=Alias()
omast=Createobject('medmaster')
Store .F. To l_RetVal, l_done
omast=Createobject('medmaster')
omast.getitem(lc_RTKEY)
C_STR= "exec dbo.GetTXNoticesbyRT  '" +lc_RTKEY+ "'"

l_done=omast.sqlexecute(C_STR, "PickNotc")
If l_done Then
	l_RetVal=.T.
	=CursorSetProp("KeyFieldList", "Cl_code, USER_CODE", "PickNotc")
*INDEX ON ALLTRIM(user_code)+ALLTRIM(CL_CODE) FOR .NOT.PRINTED TAG TOPRINT ADDITIVE
	Index On Alltrim(user_code)+Alltrim(CL_CODE) Tag Reprint Additive
	Index On CL_CODE Tag CL_CODE Additive

Endif
Store .F. To pl_GotCase
*** Get case's vars
Do gfGetCas
Release omast
Select (c_Alias)
Return l_RetVal

