***************************************************************************************************************************
*FUNCTION chkCourt
PARAMETERS c_court
LOCAL o_medCOURT AS Object
o_medCOURT=CREATEOBJECT("medmaster")
&& Check if all info on case is available!!
SELECT MASTER
IF NOT courtval( c_court) AND NOT pl_ofcHous

	gfmessage("Invalid court: " + ALLT( c_court) +"! Select new court from list.")

*!*		IF ALLTRIM(goApp.CurrentUser.orec.pc_UserOfc) = "T" &&-- Texas courts
*!*				rtncursor = goApp.OpenForm("TxCourt.frmTxCourtSearch", "M", NULL, NULL)
*!*		ELSE
			rtncursor = goApp.OpenForm("Court.frmCourtSearch", "M", NULL, NULL)
*!*		ENDIF
		IF TYPE( "c_Action") = "U"
			c_Action = IIF(pc_IssType="A","8","7")
		ENDIF
		IF c_Action = "7"  AND ;
				(!TYPE("rtncursor.court") = "C" OR EMPTY(ALLTRIM(NVL(rtncursor.court,""))))
		llExit=.F.
		DO WHILE llExit=.F.
				gfmessage("Please select valid court from list.")
*!*					IF ALLTRIM(goApp.CurrentUser.orec.pc_UserOfc) = "T" &&*-- Texas courts
*!*						rtncursor = goApp.OpenForm("TxCourt.frmTxCourtSearch", "M", NULL, NULL)
*!*					ELSE
					rtncursor = goApp.OpenForm("Court.frmCourtSearch", "M", NULL, NULL)
*!*					ENDIF
				IF TYPE("rtncursor.court") = "C" AND !EMPTY(ALLTRIM(NVL(rtncursor.court,"")))
					llExit=.T.
				ENDIF
			ENDDO
	ENDIF

	IF TYPE("rtncursor.court") = "C"
		c_court = rtncursor.court
		IF !EMPTY(ALLTRIM(c_court))
			lcSQLLine="update tblMaster set court='"+ALLTRIM(c_court)+"' "+;
				"where id_tblMaster='"+MASTER.id_tblMaster+"'"
			o_medCOURT.sqlexecute(lcSQLLine)
		ENDIF
	ENDIF

	IF EMPTY(c_court)
		c_court = pc_Court1
	ELSE
		SELECT MASTER
		REPLACE court WITH c_court
	ENDIF
ENDIF

RELEASE o_medCOURT

RETURN c_court