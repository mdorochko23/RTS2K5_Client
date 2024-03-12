*************************************************
* PROGRAM: GFSENDDS
* Date: 07/21/04
* Abstract: check if DS NRS should be sent
*
* Modifications:
*	10/3/05 kdl Convert to use SQL Server tables in VFP	   
* 	9/01/04 kdl Added check for "no DS jobs" rule
*************************************************
PARAMETER c_atcode, c_Stat
LOCAL l_ds, c_status, omed, c_sql
IF PARAMETERS() > 1
	c_Status = c_Stat
ELSE
	c_status = pc_Status
ENDIF
* -----------07/07/2015 md - added to set C_Status in case it still .F.--------
IF TYPE("c_status")="L"
	IF TYPE("c_stat")="C"
		c_status=c_Stat
	ELSE
		c_status="R"
	ENDIF
ENDIF
**--------------------------------------------------------------------------	
n_Curarea = SELECT()
l_ds = .T.

omed=CREATEOBJ("medgeneric")
*c_sql = "SELECT * FROM tblCovrCtrl WHERE at_code = '"+fixquote(c_atcode)+"' AND Active=1"
c_sql=""
c_sql="exec  [dbo].[GetAtCovrCtrlRecord] '" +ALLTRIM(fixquote(c_atcode))+"'"
omed.sqlexecute( c_sql, 'Attyrulz')  

IF RECCOUNT('Attyrulz') > 0
	SELECT AttyRulz
	SCAN
		IF attyrulz.no_dsnrs AND c_Status = "N"
			l_ds = .F.
			EXIT
		ENDIF
		IF attyrulz.no_dsjob
			l_ds = .F.
			EXIT
		ENDIF
	ENDSCAN
ENDIF
USE IN Attyrulz
SELECT(n_Curarea)
RETURN (l_ds)
