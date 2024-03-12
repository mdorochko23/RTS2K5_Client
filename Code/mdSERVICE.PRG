************************************************************************
FUNCTION  mdservice
** Prints a Notice of ServIce of Discovery page ( page 2 in the MD court set and last page in the Request set)
**04/07/2015
************************************************************************
PARAMETERS d_send, n_mode
PRIVATE c_Print, c_plAtty, c_atty, c_alias, c_email1
**n_mode =1 when issue is done - simpler form is needed and n_mode =2 when the Notice/Filings are done - more cpmplex form is needed
LOCAL  omed_i AS OBJECT
omed_i= CREATEOBJECT("generic.medgeneric")
STORE "" TO c_Print,  c_plAtty, c_atty,  c_alias, c_email1
c_alias=ALIAS()
c_plAtty=fixquote(pc_platcod)
c_atty=fixquote(pc_rqatcod)
pl_GetAt = .F.
DO gfatinfo WITH c_atty, "M"
&& Get Pl Attorney name
omed_i.closealias('PLname')
lc_PlAtty=omed_i.sqlexecute("select DBO.GetAttyFullName2('"+c_plAtty+"')", "PLname")
&& Get Requesting Attorney Type!!
lc_RqAtType = IIF( pl_plisrq, "Plaintiff", "Defendant")
omed_i.closealias('RqEmail1')
omed_i.sqlexecute("select dbo.GetNoticeAttyEmail ('" + c_atty + "',1) " , "RqEmail1")
IF USED('RqEmail1') AND NOT EOF()
	c_email1=NVL(RqEmail1.EXP,'')
ENDIF
SET PROCEDURE TO TA_LIB ADDITIVE
IF TYPE ("d_send")="D" OR TYPE ("d_send")="T"
	IF  TYPE ("d_send")="T"
		d_send=TTOD(d_send)
	ENDIF
ELSE
	d_send=DATE()
ENDIF

DO printgroup WITH c_Print,  IIF(n_mode=1, "MDService2", "MDService3")


DO printgroup WITH c_Print, "Case"
DO PrintField WITH  c_Print, "LRS", ""
DO PrintField WITH  c_Print, "Name", ""
DO PrintField WITH  c_Print, "Plaintiff",ALLTRIM(PC_PLCAPTN)&& ALLTRIM(pc_plnam)
DO PrintField WITH  c_Print, "Defendant",ALLTRIM( pc_dfcaptn)
&&use pliantiff's atty name

DO PrintField WITH c_Print, "AttyName",ALLTRIM(NVL(PLname.EXP,''))
DO PrintField WITH c_Print, "AttyType", IIF( lc_RqAtType = "Defendant", "D", "P")
DO PrintField WITH c_Print, "Court",""
DO PrintField WITH c_Print, "Term", ""
DO PrintField WITH c_Print, "Docket", ALLTRIM(NVL(PC_DOCKET,""))
lcPhone = pc_amgr_ph
DO printgroup WITH c_Print, "Contact"
DO PrintField WITH c_Print, "Name", IIF( NOT EMPTY(pc_amgr_nm), pc_amgr_nm, "RecordTrak Representative")
DO PrintField WITH c_Print ,"Phone", ""
lcFaxNo=""
lcFaxNo=pc_AtyFax
DO printgroup WITH c_Print, "Atty"
DO PrintField WITH c_Print, "Name_inv", ALLTRIM(pc_AtySign) + CHR(13) + ALLTRIM(NVL(pc_AtyFirm,''))
DO PrintField WITH c_Print, "Ata1",  ALLTRIM(PC_ATY1AD)
DO PrintField WITH c_Print, "Ata2",ALLTRIM(PC_ATY2AD)
DO PrintField WITH c_Print, "Ata3", ALLTRIM(pc_AtySign)
DO PrintField WITH c_Print, "Atacsz",ALLTRIM(PC_ATYCSZ)
DO PrintField WITH c_Print, "FaxNo", IIF( LEN( lcFaxNo) < 10, "", "Fax #: " + lcFaxNo)

d_send2 = gfChkDat( d_send + 1, .F., .F.) &&4/16/15 ADDED A DAY PER LIZ
DO PrintField WITH c_Print, "NoticeDate", DTOC( d_send2)

LOCAL c_listP AS STRING, c_listd AS STRING, c_client AS STRING
STORE"" TO    c_listP,  c_listd,  c_client
c_client =pc_clcode
c_listP=GetAttyList ( c_client , 'P', n_mode)
DO PrintField WITH c_Print, "PlAttyList", c_listP
c_listd=GetAttyList (pc_clcode, 'D' ,n_mode)
IF EMPTY(ALLTRIM(c_listd))
	DO PrintField WITH c_Print, "DefAttyList", ""
ELSE
	IF n_mode=1
		c_extra="On " +DTOC( d_send2) + " , a copy of this Notice of Service of Discovery along with copies of Defendants’ Notices to Take Records Depositions and accompanying subpoenas were mailed, postage prepaid to: "
	ELSE
		c_extra="and via first class mail to the following recipients:"
*DO PrintField WITH c_Print, "DefAttyList", c_listd
	ENDIF
	DO PrintField WITH c_Print, "DefAttyList",c_extra + CHR(13) +CHR(10)+ c_listd
ENDIF
DO PrintField WITH c_Print, "AtPhone", ALLTRIM(pc_AtyPhn)
DO PrintField WITH c_Print, "AtEmail", ALLTRIM(c_email1)

IF n_mode=2  && only form that prints with the notices/filings need that data
	DO PrintField WITH c_Print, "DayWeek",  CDOW(d_send2)
	DO PrintField WITH c_Print, "DayMonth",  DAY(d_send2)
	DO PrintField WITH c_Print, "Month",  WhatMonthIsIt( MONTH(d_send2))
	DO PrintField WITH c_Print, "Year", YEAR(d_send2)

**REMOVED SIGNATURE 6/8/15 PER LIZ and add deponents and other data
*DO PrintField WITH c_Print, "Id", pc_ScanSg
**4/15/15- added pl and def lists

	omed_i.closealias('ListTags')
	c_sql=" exec  dbo.MDTagsonServicePage '" + fixquote(pc_clcode) + "','" + DTOC(d_send) + "'"
	omed_i.sqlexecute(c_sql,'ListTags')
	IF USED('ListTags') AND NOT EOF()
		SELECT ListTags
		SCAN
			DO printgroup WITH c_Print, "Item"
			DO PrintField WITH c_Print, "Tag", "" && ALLTRIM( STR( ListTags.TAG))
			DO PrintField WITH c_Print, "Name",ALLTRIM( ListTags.TagName)
		ENDSCAN
	ENDIF
ENDIF &&n_mode=2

RELEASE omed_i
IF NOT EMPTY(c_alias)
	SELECT (c_alias)
ENDIF

RETURN c_Print
******************************************************
FUNCTION GetAttyList
PARAMETERS  c_cl,  c_type, n_set
LOCAL  omed_i AS OBJECT, c_alias AS STRING, c_attylist AS STRING
c_alias=ALIAS()
omed_i= CREATEOBJECT("generic.medgeneric")
omed_i.closealias ('LlistA')
c_attylist=""
IF n_set=1 && ISSUE/REPRINT
	omed_i.sqlexecute(" select [dbo].[getMdAttyList]('"+c_cl+"','" + c_type + "')", "ListA")
ELSE
	omed_i.sqlexecute(" select [dbo].[getMdAttyAddressList] ('"+c_cl+"','" + c_type + "')", "ListA")
ENDIF
IF USED('ListA')

	SELECT ListA
	SCAN
		c_attylist=NVL(ListA.EXP,'')

		SELECT  ListA
	ENDSCAN
	SELECT ListA
	USE
ENDIF


RELEASE omed_i
IF NOT EMPTY(c_alias)
	SELECT (c_alias)
ENDIF
RETURN  c_attylist

***************************************************************************
FUNCTION WhatMonthIsIt()
PARAMETERS nId
PRIVATE c_month AS STRING
c_month =''
c_month= laMonth[nId ]
RETURN c_month
***************************************************************************

