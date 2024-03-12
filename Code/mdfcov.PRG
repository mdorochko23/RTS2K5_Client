************************************************************************
FUNCTION  MDFCov
** Prints a 'Court Filing' Cover Letter Page 1  for the MD set
** 04/22/2015 : added few additional  fields to a page
**04/06/2015 : initila release
************************************************************************
PARAMETERS d_send
PRIVATE c_Print
c_Print = ""

SET PROCEDURE TO TA_LIB ADDITIVE
IF TYPE ("d_send")="D" OR TYPE ("d_send")="T"
	IF  TYPE ("d_send")="T"
		d_send=TTOD(d_send)
	ENDIF
ELSE
	d_send=DATE()
ENDIF

d_send2 = gfChkDat( d_send + 1, .F., .F.) &&5/20/15 ADDED A DAY PER LIZ

DO printgroup WITH c_Print, "MDFCov"
DO printfield WITH c_Print, "Loc", pc_offcode
DO printfield WITH c_Print, "Date", DTOC( d_send2)
DO printfield WITH c_Print, "Id", pc_ScanSg
DO printfield WITH c_Print, "AMName", PROPER( pc_amgr_nm)
DO printfield WITH c_Print, "AMPhone", pc_amgr_ph

DO printgroup WITH c_Print, "Case"
DO printfield WITH  c_Print, "Plaintiff",ALLTRIM(PC_PLCAPTN)
DO printfield WITH  c_Print, "Defendant",ALLTRIM( pc_dfcaptn)
DO printfield WITH c_Print, "Docket", ALLTRIM(NVL(PC_DOCKET,""))

RETURN c_Print
