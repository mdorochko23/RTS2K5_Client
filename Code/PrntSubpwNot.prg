*PROCEDURE PrntSubpwNot
**03/20/12 -added new USDC FORM ( share it with KOP cases)
**7/15/09 - only print subpoenas (exclude authorizations)
*-- 11/15/2021 MD #256534   Added 'sn' in front of parameters to not interfer with public lcCL_Code and lnTag.
PARAMETERS snLCCL_CODE, snLNTAG, LDDEPDATE, LCDESCRIPT, LCMAILID_NO, ;
	LDDATE, LDDEPDATE, L_REGULAR
PRIVATE DBINIT, local OMED1 AS Object
DBINIT = SELECT()

WAIT WINDOW "Printing subpoena.." NOWAIT NOCLEAR

SELECT 0
_SCREEN.MOUSEPOINTER=11

IF TYPE('pc_deptype')<>"C"
	IF NOT ISDIGIT( LEFT( ALLT( LCMAILID_NO), 1))
		pc_deptype = LEFT( ALLT( LCMAILID_NO), 1)
	ELSE
		pc_deptype = "D"
	ENDIF
ENDIF

OMED1 = CREATEOBJECT("generic.medgeneric")

OMED1.SQLEXECUTE ("Exec [dbo].[GetSpecInsByClCodeTag]  '" + ;
	FIXQUOTE(snLCCL_CODE) + "', ' " + STR(snLNTAG) + "'", "Spec_ins")


L_REC=OMED1.SQLEXECUTE("EXEC DBO.GetSingleRequestRecord '" + FIXQUOTE(snLCCL_CODE) + "','" + STR(snLNTAG) + "'","Record")
WAIT WINDOW "Getting Deponent's information" NOWAIT NOCLEAR

IF RECCOUNT("Record")<1
	_SCREEN.MOUSEPOINTER=0
	USE IN SPEC_INS
	USE IN RECORD
	WAIT CLEAR
	SELECT (DBINIT)
	RETURN
ENDIF



IF RECORD.TYPE="S" THEN 

	L_MAIL=OMED1.SQLEXECUTE("exec dbo.GetDepInfoByMailIdDept '" + ALLTRIM(RECORD.MAILID_NO) +"','" ;
		+ IIF((ALLTRIM(spec_ins.dept)<>"Z" AND pc_deptype <>"H"),"Z",ALLTRIM(spec_ins.dept)) + "' ", "pc_DepoFile")
	=CURSORSETPROP("KeyFieldList", "Code, id_tbldeponents", "pc_DepoFile")


	_SCREEN.MOUSEPOINTER=0


	DO CASE
	*-- 02/10/2021 MD #224406
	*-- CASE ALLTRIM( MASTER.COURT) = "WCAB"
	CASE LEFT(ALLTRIM(UPPER(pc_court1)), 4) = "WCAB" and pl_ofcoaK 		
		DO SubWCAB IN Subp_CA WITH "1", SPEC_INS.SPEC_INST,LDDEPDATE, snLNTAG, convertToDate(RECORD.REQ_DATE) && 03/29/2021 #232338 MD add convertToDate 					
	*-- 02/10/2021 MD #224406			
	CASE LEFT( ALLTRIM(MASTER.court), 4) = "USDC"
		LOCAL l_COURT AS STRING, l_COURT2 AS STRING, l_AtName AS STRING, l_nameinv AS STRING, l_reqType AS STRING, l_county AS STRING, ;
			l_dep AS STRING, l_mid AS STRING
		STORE "" TO l_COURT , l_COURT2, l_AtName, l_nameinv , l_reqType , l_county,l_dep ,l_mid
* Generic US District Court subpoena
*!*			DO CAUSSUBP IN SUBP_CA WITH "", LCDESCRIPT, ;
*!*				LCMAILID_NO, LDDATE, LDDEPDATE, LNTAG


		l_COURT=pc_Court1
		l_COURT2=pc_Court2

		IF NOT EMPTY( pc_rqatcod)
			c_RqAtty=fixquote(pc_rqatcod)
			pl_GetAt = .F.
			DO gfatinfo WITH c_RqAtty, "M"

			l_AtName = Pc_AtyName
			l_nameinv = IIF ( LEFT( ALLTRIM(pc_court1), 4) = "USDC", pc_AtyFirm,pc_AtySign)
			mratadd1 = pc_Aty1Ad
			mratadd2 = pc_Aty2Ad
			mratcsz = pc_Atycsz
			mphone = pc_AtyPhn

		ENDIF


		l_reqType= ALLTRIM(NVL(RECORD.TYPE,'A'))
		l_county=pc_c1Cnty
		l_dep=LCDESCRIPT
		l_mid=LCMAILID_NO
		pc_tagdist=ALLTRIM(NVL(RECORD.District,""))
		pn_tag=snLNTAG
		IF TYPE('ldDueDate')="U"

			ldDueDate=LDDEPDATE
		ENDIF
		pd_Depsitn=ldDueDate
		DO subprint WITH snLNTAG, l_COURT, l_COURT2,  l_AtName, l_nameinv,  l_reqType,l_county, l_dep, l_mid

*!*		CASE LEFT( PC_COURT1, 4) = "USDC"
*!*	* US District Court subpoena for a specific district (e.g., "USDC-AL")
*!*			DO CAUSOTHR IN SUBP_CA WITH ALIAS(), PL_C1PRVDR, LCDESCRIPT, ;
*!*				LDDATE, LDDEPDATE, LNTAG

	OTHERWISE

		DO CADEPSUB IN SUBP_CA WITH SPEC_INS.SPEC_INST, ;
			ALLTRIM(RECORD.DESCRIPT), ALLTRIM(RECORD.MAILID_NO), RECORD.REQ_DATE, ;
			LDDEPDATE, snLNTAG
	ENDCASE

**Add attachment page
	IF L_REGULAR
		DO REATTCH WITH snLNTAG, LCDESCRIPT, LCMAILID_NO
	ENDIF
ENDIF &&7/15/09
**Add attachment page
SELECT RECORD
USE
SELECT SPEC_INS
USE
WAIT CLEAR
RELEASE OMED1
SELECT (DBINIT)
RETURN
