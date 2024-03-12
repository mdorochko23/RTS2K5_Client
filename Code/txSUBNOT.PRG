*Function txsubnot
******************************************************************************
**08/17/2017: Texas Notice (end day set) and Reprint Notices
******************************************************************************
PARAMETERS c_cl, d_date, c_at , l_reprint, c_SendType, d_DueDate
LOCAL mv_not AS STRING
mv_not =""
PRIVATE c_nameinv, c_nameinvp, c_ratadd1, c_ratadd1p,  c_clcode,  c_cty, ;
	c_ratadd2, c_ratadd2p, c_ratcszP, c_ratcsz, c_date1, c_roloname, c_sign

dbInit = ALIAS()
ots = CREATEOBJECT("medtimesheet")
_SCREEN.MOUSEPOINTER=11

IF NOT USED('UserCtrl')
	c_sql=" EXEC DBO.[GetUserByLogin] '" +ALLTRIM(pc_amgr_id) + "'"
	omed.sqlexecute(c_sql, "UserCtrl ")
ENDIF
contname= UserCtrl.FULLNAME &&pc_UserNam
contphone= UserCtrl.DirectDial&& pc_UserPhn
IF EMPTY(contphone)
	contphone = "(800) 355-7400"                 && Direct dial phone number
ENDIF

c_FaxCode="P"
IF ALLTRIM(pc_litcode) ="C"
	l_AMFaxCode= GetAMFaxCode (pc_amgr_id)
	IF l_AMFaxCode
		c_FaxCode=IIF(ISNULL(AMFax.RpsAMFaxCode) OR EMPTY(AMFax.RpsAMFaxCode), 'P', AMFax.RpsAMFaxCode)
	ELSE
		c_FaxCode= "P"
	ENDIF
ELSE
	c_FaxCode=pc_offcode
ENDIF

lc_BarNum=NVL(pc_BarNo,"")

*-------------------------------------------------------------------
**DO PrintGroup WITH mv_not, "TXZNotice" && txznot.doc
  DO PrintGroup WITH mv_not, "2_TXZNotice" && 2_txznot.doc		&& 	 11/30/2022, ZD #294986, JH
*-------------------------------------------------------------------
	DO PrintField WITH mv_not, "Loc", "P"
	DO PrintField WITH mv_not, "FaxLoc",	c_FaxCode
	**11/28/2017:  Judicial vs. County court  #70136
	*c_cty=fixquote(NVL(pc_c1Cnty,''))  
	mv_cap2=""
	mv_cap2= txcourtcap()
	IF EMPTY(mv_cap2)
		Wait Window 'Error in court caption.'
		Return
	ENDIF
	mv_not=mv_not+mv_cap2
**11/28/2017:  Judicial vs. County court	 
*!*		DO PrintField WITH mv_not, "CrtType", ALLTRIM(pc_txCrtType)	
*!*		DO PrintField WITH mv_not, "County", UPPER(c_cty)
*!*		DO PrintField WITH mv_not, "Suffix", NVL(pc_Suffix,"")
	DO PrintField WITH mv_not, "DueDate", d_DueDate
	DO PrintField WITH mv_not, "RT",	ALLTRIM(pc_lrsno)

STORE "" TO c_nameinv, c_nameinvp, c_ratadd1p, c_ratadd2p, c_ratcszP, ;
	c_AttyInfo, c_ratadd1, c_ratadd2, c_ratcsz, c_Pltcap, c_AtName, c_EmailAdd, c_AtyFax
IF NOT EMPTY( c_at)
	pl_GetAt = .F.
	DO AtyMixed WITH fixquote(c_at), "M", .T.
	c_AtName = pc_AtyName
	c_nameinv = pc_AtySign
	c_ratadd1 = pc_Aty1Ad
	c_ratadd2 = pc_Aty2Ad
	c_ratcsz = pc_Atycsz
	c_phone = pc_AtyPhn
	c_Firm = pc_Atyfirm
	c_AtyFax=pc_AtyFax
	c_EmailAdd= ""&&TxRqemail(0,pc_rqatcod)
ENDIF

**Atty info
DO PrintGroup WITH mv_not, "Atty"
DO PrintField WITH mv_not ,"Name_inv", c_AtName &&c_nameinv
DO PrintField WITH mv_not, "Ata1",  c_ratadd1 + IIF(EMPTY(c_ratadd2),"",  CHR(13)  + c_ratadd2)
DO PrintField WITH mv_not, "Ata2", "" &&c_ratadd2
DO PrintField WITH mv_not, "Atacsz", c_ratcsz
DO PrintField WITH mv_not, "Phone", c_phone
DO PrintField WITH mv_not, "Ata3", 	c_Firm
DO PrintField WITH mv_not, "Attn", c_EmailAdd
DO PrintField WITH mv_not, "FaxNo", c_AtyFax
**Case info
DO PrintGroup WITH mv_not, "Case"
DO PrintField WITH mv_not, "Plaintiff", pc_plcaptn
DO PrintField WITH mv_not, "Defendant", pc_dfcaptn
DO PrintField WITH mv_not, "Docket", pc_docket
DO PrintField WITH mv_not, "AttyType", IIF( pl_plisrq, "P", "D")

IF TYPE('pd_pldob')<>"C"
	pd_pldob=DTOC(pd_pldob)
ENDIF
**get Rq atty's signature
ots.CLOSEALIAS("AttySign")
l_Ok=ots.sqlexecute("select dbo.convert2Proper( [dbo].[AttySignature] ( '" + fixquote(pc_rqatcod) + "'))", "AttySign")
c_attysign=""
IF NOT l_Ok
	c_attysign=""
ELSE
	c_attysign=fixquote(AttySign.EXP)
ENDIF
DO PrintField WITH mv_not, "AttyName", PROPER(ALLTRIM(c_attysign))
DO PrintField WITH mv_not, "BirthDate", pd_pldob
DO PrintField WITH mv_not, "SSN", pc_plssn
DO PrintField WITH mv_not, "Term", pd_term
**11/28/2017:  Judicial vs. County court   #70136
*DO PrintField WITH mv_not, "Dist", UPPER(ALLT( pc_distrct))
*DO PrintField WITH mv_not, "Area", UPPER(c_cty)

Do PrintField With mv_not, "PertainTo", UPPER(pc_plnam) 		&& 11/30/2022, ZD #294986, JH

**get tags and blurbs
	ots.closealias('TxTags')
	c_sql=" exec  dbo.TXTags4Notice '" + fixquote(c_cl) + "','" + DTOC( d_date) + "'"
	ots.sqlexecute(c_sql,'TxTags')
	IF USED('TxTags') AND NOT EOF()
		SELECT TxTags
		=CURSORSETPROP("KeyFieldList", "Tag", "TxTags")
		INDEX ON STR(TAG) TAG tagOrd ADDITIVE
		SET ORDER TO tagOrd 
		SCAN
		
		PN_TAG=TxTags.TAG
		** print only for newly issued tags
		IF oldIssue (Master.lrs_no,TxTags.TAG)
			LOOP
		ENDIF
	
			c_info=""
			c_info= GETSPECINSFORTAG(TxTags.TAG)		

			DO printgroup WITH mv_not, "Item"
			DO PrintField WITH mv_not, "Tag", ALLTRIM( STR( TxTags.TAG))
			DO PrintField WITH mv_not, "Name", + "__" + ALLTRIM( TxTags.TagName)
			DO PrintField WITH mv_not, "InfoText", ALLTRIM(c_info)
			IF ! l_reprint
			*** mark as printed 
			MarkPrinted ( c_cl, TxTags.tag)
			*** mark as printed 
			ENDIF 
			SELECT TxTags
		ENDSCAN
	ENDIF

**contact info

DO PrintGroup WITH mv_not, "Contact"
DO PrintField WITH mv_not, "Name", contname
DO PrintField WITH mv_not, "Phone", contphone


***now add to RPS***************************************************************
c_Addr=""
c_fax = STRTRAN( c_AtyFax ," ", "")
c_temp = STRTRAN( c_fax, "-", "")
c_temp2 = STRTRAN( c_temp, "(", "")

lc_FaxNum = "1"+ STRTRAN( c_temp2, ")", "")

IF  LEN(lc_FaxNum )<10
	lc_FaxNum=""
ENDIF
 
IF LEN(ALLTRIM(lc_FaxNum))=11 AND  INLIST(ALLTRIM(STRTRAN( c_temp2, ")", "")),'1111111111','2222222222','3333333333','4444444444','5555555555','6666666666','7777777777','8888888888','9999999999','0000000000')
	lc_FaxNum =""
ENDIF
 
** get email and RPS class to a notice set
IF l_reprint &&pl_RepNotc
	mclass = "RepNot"
ELSE
** email first
	l_gotemail=.F.
	l_gotemail=oTS.sqlexecute("select dbo.GetNoticeAttyEmail ('" + c_at+ "'," +STR(1)+ " )","EmailAddr")
	IF l_gotemail
		pc_EmailAdd=IIF(ISNULL(ALLTRIM(EmailAddr.EXP)),"",ALLTRIM(EmailAddr.EXP))
	ENDIF
	** 09/29/2017: sent all TX notices to email : TX Waiver notices [RT number].  
	pc_EmailAdd="cs@recordtrak.com"
	IF !EMPTY(pc_EmailAdd)
		lc_SendType ="E"
		mclass="ETxNotice"
	ELSE
** now we try to fax and then print
		lc_SendType = ALLTRIM( c_SendType)
	ENDIF


	DO CASE
	CASE  lc_SendType="F" AND pl_NoFaxNotice=.F.
		mclass="FaxNotice"

		pc_EmailAdd=""
		c_Addr=IIF (LEN(ALLTRIM(lc_FaxNum))<10,"",lc_FaxNum)
		c_fax = STRTRAN( c_Addr, " ", "")
		c_temp = STRTRAN( c_fax, "-", "")
		c_temp2 = STRTRAN( c_temp, "(", "")
		c_Addr = STRTRAN( c_temp2, ")", "")

	CASE  EMPTY(ALLTRIM(pc_EmailAdd))
		mclass="Notice"
	ENDCASE


ENDIF  && reprint vs. original print


DO PrtEnQa IN ta_lib WITH mv_not, mclass, 	"2", c_Addr

_SCREEN.MOUSEPOINTER=11
SELECT ( dbInit)
RELEASE ots
WAIT CLEAR

RETURN

*****************************************************************************************************************************
PROCEDURE MarkPrinted
*****************************************************************************************************************************
PARAMETERS c_clCode, n_tg

		LOCAL L_OK as Boolean
		L_OK=.f.
				L_OK= oMed.sqlexecute("EXEC dbo.UpdateKopNoticeToPrinted '" + fixquote(c_clcode)+ "','" +  ALLTRIM(STR(n_tg))+ "','" + "TXNot" +"'", "")

			IF NOT L_OK
				gfmessage("Cannot Update TX Notice. ")
			ENDIF

RETURN 

