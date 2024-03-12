**EF 5/10/06 -added to the vfp project
***********************************************************
*** EF 08/02/04 - use public variables and delete tmp file
*** EF 9/28/99
*** CourtCer.prg - Reprint court's certificates
*** Called by Plaintiff.prg.
*** Calls TheCerti
***********************************************************
PARAMETERS c_rtnum
PRIVATE  c_temp, c_proced, oMast 

c_temp=SYS(5) +"\" +SYS(3)
SET PROCEDURE TO ta_lib ADDITIVE
IF GetCourtCert(c_rtnum) = 0
	gfmessage("No Certificate to print!")
	RETURN
ENDIF
WAIT CLEAR
oMast=CREATEOBJECT("medmaster")

_SCREEN.MOUSEPOINTER=11
c_str="exec  [dbo].[GetMasterbyRTNumber]  '" + c_rtnum + "'"
l_Master=oMast.Sqlexecute(c_str , "Master")
SELECT MASTER
pl_GotCase=.F.
WAIT WINDOW "Getting Case's information" NOWAIT NOCLEAR 
DO gfgetcas
_SCREEN.MOUSEPOINTER=0
WAIT CLEAR 
IF NOT l_Master OR EOF()
	gfmessage("Could not find a case. Try again.")
	RETURN
ELSE


	SELECT courtc
	GO TOP
	
	DEFINE WINDOW WCertif FROM 6,17 TO 26,84 COLOR SCHEME 10
	ACTIVATE WINDOW WCertif
	BROWSE FIELDS ;
		SELECTED:H="(F/T)", ;
		DATE:R : W=.F., ;
		ReqAtty:R :25 :W=.F., ;
		TAG:R :W=.F. FREEZE SELECTED;
		TITLE " Court Certificate: <CTRL+W> to confirm, <ESC> to cancel " ;
		NOAPPEND NODELETE COLOR SCHEME 10

	SCATTER MEMVAR

	DEACTIVATE WINDOW WCertif
	RELEASE WINDOW WCertif
	IF LASTKEY()=27
		CLEAR READ
		RELEASE WINDOW WCertif
	ELSE
		DELETE FOR NOT SELECTED
	ENDIF

	***09/26/13 *mail date ( send-date ) 
		oMast.closealias("MailDate")
		c_sql = " SELECT [dbo].[GetTagMailDate] ('" +FIXQUOTE(master.CL_CODE) + "','" +STR(m.Tag) +"')"
		l_ok=oMast.sqlexecute (c_sql,"MailDate")

		IF l_ok AND NOT EOF()
			d_Maild =CTOD(LEFT(DTOC(MailDate.EXP),10))		
		ENDIF
		IF TYPE("d_Maild") <>"D"
			d_Maild=M.DATE
		ENDIF
	****
	
	DO TheCerti WITH m.tag, d_Maild, c_temp
	IF NOT EMPTY(c_temp)
		SELECT (c_temp)
		USE
		DELETE FILE &c_temp+".DBF"
	ENDIF
	RETURN

	RELEASE mv
	WAIT WINDOW "Printing is done." NOWAIT NOCLEAR 
ENDIF
WAIT CLEAR 
RELEASE oMast
	RETURN
************************************************************************
&& procedure to hold all court certificates to print
FUNCTION GetCourtCert
	PARAMETERS c_rt
IF USED ('courtc')
SELECT courtc
USE
ENDIF
	PRIVATE lnTally, oMedCrt

	WAIT WINDOW "Retrieving certificates. Please wait." NOWAIT NOCLEAR 
	oMedCrt = CREATEobject("generic.medgeneric")


	c_sql="Exec dbo.GetCourtCerts '" +  c_rt + "'"
	oMedCrt.Sqlexecute(c_sql,'CourtCert')	
	SELECT DISTINCT .F. AS SELECTED, DTOC(Txn_date) AS DATE, RT, ;
		ALLTRIM(ReqAtty) AS ReqAtty, TAG, Cl_code AS Cl_code FROM CourtCert ;
		INTO TABLE (c_temp) ;
		ORDER BY Txn_date, TAG
	lnTally = _TALLY
	USE
	USE (c_temp) ALIAS courtc
	WAIT CLEAR
   RELEASE oMedCrt
	RETURN lnTally
