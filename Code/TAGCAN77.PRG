*PROCEDURE tagcan77
** called from Deponent Option/Cancel Tag #53843
*****************************************************************************************************************
PARAMETERS  c_cl, n_tg
LOCAL oMedBill AS OBJECT, lcAlias AS STRING, 	lnTg as Integer
oMedBill= CREATEOBJ("generic.medgeneric")
lcAlias= ALIAS()

LOCAL l_77_rq AS Boolean, l_77_pl AS Boolean, o_mg AS OBJECT, n_77_fee AS CURRENCY, c_SQL AS STRING, c_Atty AS STRING
STORE .F. TO l_77_rq , l_77_pl
n_77_fee=0
STORE "" TO c_SQL, c_Atty

** 1) Rq atty only
o_mg = CREATEOBJECT('rts_message_yes_no',"Would you like to bill the requesting attorney?")
o_mg.SHOW
l_77_rq=IIF(o_mg.exit_mode="YES",.T.,.F.)
o_mg.RELEASE


IF l_77_rq
	c_Atty=NVL(PC_RQATCOD,'')
	n_77_fee=gfcanfee(c_cl, n_tg, c_Atty)
	

	c_SQL="Exec dbo.Addtxn77byTagCancel '" + ALLTRIM(UPPER(c_cl)) + "','" + ALLTRIM(STR(n_tg)) + "','" + ;
		ALLTRIM(goApp.CurrentUser.ntlogin)+"','" + c_Atty+ "'," + ALLTRIM(STR(n_77_fee,10,4))
	oMedBill.sqlexecute(c_SQL, "TsId")

ENDIF
** 2) Plaintiff attys only
o_mg = CREATEOBJECT('rts_message_yes_no',"Would you like to bill all Procurement rate buyers?")
o_mg.SHOW
l_77_pl=IIF(o_mg.exit_mode="YES",.T.,.F.)
o_mg.RELEASE
IF l_77_pl
	STORE "" TO c_SQL, c_Atty
	n_77_fee=0
	IF  getAtlist ( c_cl, n_tg)
		IF USED( "Atlist") AND !EOF()
			SELECT  ATLIST
			SCAN
			c_Atty=NVL(ATLIST.at_code,'')
				IF !EMPTY(c_Atty)

					n_77_fee=gfcanfee(c_cl, n_tg, c_Atty)

					c_SQL="Exec dbo.Addtxn77byTagCancel  '" + ALLTRIM(UPPER(c_cl)) + "','" + ALLTRIM(STR(N_TG)) + "','" + ;
						ALLTRIM(goApp.CurrentUser.ntlogin)+"','" +c_Atty+ "'," + ALLTRIM(STR(n_77_fee,10,4))
					oMedBill.sqlexecute(c_SQL, "TsId")
					SELECT  ATLIST
				ENDIF
			ENDSCAN

		ENDIF
	ENDIF
ENDIF


RELEASE oMedBill

IF !EMPTY(lcAlias)
	SELECT (lcAlias)
ENDIF

RETURN

****
PROCEDURE getAtlist
PARAMETERS c_client, n_tag
LOCAL l_RetVal AS Boolean, l_done AS Boolean, C_STR AS STRING, oMedBill AS OBJECT
oMedBill= CREATEOBJ("generic.medgeneric")
STORE .F. TO l_RetVal, l_done

oMedBill.closealias('Atlist')
C_STR="exec [dbo].[GetAty77] '" +  fixquote(c_client) + "','" + STR(n_tag) + "'"

l_done=oMedBill.sqlexecute(C_STR, "Atlist")
IF l_done THEN
	l_RetVal=.T.
	=CURSORSETPROP("KeyFieldList", "AT_code", "Atlist")
	INDEX ON  at_code TAG Atty ADDITIVE

ENDIF
RELEASE oMedBill
RETURN l_RetVal

