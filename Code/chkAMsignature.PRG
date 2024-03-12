******************************************************************************
**FUNCTION chkAMsignature
**EF 08/23/11 - see if we can print the supporting docs-as they need a sign 
******************************************************************************
LOCAL l_ok as Boolean, c_Alias as String
l_ok =.t.
c_alais=ALIAS()

IF  pl_ofcOak
RETURN l_ok
ENDIF

IF   EMPTY(ALLTRIM(pc_ScanSg)) AND NOT EMPTY( pc_amgr_id)
	IF TYPE("oMedGen")!="O" OR ISNULL(oMedGen)=.T.
		oMedGen=CREATEOBJECT("generic.medgeneric")
	ENDIF
	oMedGen.sqlexecute("exec dbo.GetUserCtrlByLogin '" + ;
	fixquote(ALLTRIM( pc_amgr_id)) + "', '" + MASTER.id_tblmaster + "'", "UserCtrl")
	SELECT UserCtrl

*	IF UserCtrl.Login = pc_amgr_id									&& 7/17/2020
	IF UPPER(ALLTRIM(UserCtrl.Login)) = UPPER(ALLTRIM(pc_amgr_id))	&& 7/17/2020, ZD #179058, JH.
		pc_ScanSg = ALLT( UserCtrl.SigFile)
		pl_ScanSig = UserCtrl.ScannedSig
	ENDIF
	RELEASE oMedGen
ENDIF


IF  EMPTY(ALLTRIM(pc_ScanSg)) AND pc_isstype="S" AND ALLTRIM(pc_litcode) ="C"
	l_ok=.f.
ENDIF 
RETURN l_ok
