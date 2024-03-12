**********************************************************************************
* PROGRAM: FLPROC.PRG
* Date: 6/19/03
* Programmer: kdl
*
* Abstract: first-look procedures
* Modifications:
* 04/07/06 kdl - converted base 1st-look procesing to VFP
* 01/23/06 kdl - Convert chkorder procedure to SLQ
* 11/23/04 kdl - Modify distodo image table definition
* 11/09/04 kdl - Added new image system release
* 09/24/04 kdl - Added process to set shipment methods when case/tag is released from
*                first-look
* 09/08/04 kdl - set l_incoming varaiable for use in lfprnbar method
* 04/12/04 kdl - save the 1st look delivery and due dates to recspec.dbf
* 04/02/05 kdl - added chkorder prcedure to pull order data out of order table
* 01/15/04 kdl - Added error trap for missing GEN file in tag release process
* 01/09/04 kdl - Added call to external VFP application that sets tiff file
*	properties for tiff page substitutions
* 09/25/03 kdl - Update remove fields in disttodo.dbf instead of deleting record
*                when deleting a first-look 88 transaction
* 09/12/03 kdl - Added error check before updateinf record.distrib column
*              - Add check for multiple IDX files
*              - Add check for bad modified Gen files
* 09/04/03 kdl - Added update process for the txttiff.exe program
* 08/29/03 kdl - Added function to modify GEN file when moving images
*  to for production upload.  Function changes LOOK directorry to
*  redact directory in gen file tif paths.
* 08/20/03 kdl - switch from dos move for better error reporting
*
**********************************************************************************
**********************************************************************************
* Procedure: FlookLit
* Calls: gfuse.prg, gfunuse.prg
* Abstract: get flook variables
* Called by: caseinst.prg
**********************************************************************************
PROCEDURE FlookLit
PARAMETERS c_Lit
PRIVATE l_fllit, n_Curarea
n_Curarea = SELECT()
l_fllit = gfuse("fllit")
SET ORDER TO CODE IN fllit
pl_CFlook = .F.                                 && default setting for case level 1st look
pn_Fldays = 0
pc_Fltype = ""
pc_Flatty = ""

IF SEEK(c_Lit, "fllit")
	IF EMPTY(fllit.office) OR pc_UserOfc $ fllit.office
		pl_CFlook = .T.
		pn_Fldays = fllit.fl_days
		pc_Fltype = fllit.flday_type
		pc_Flatty = pc_platcod                    && set default to plaintiff attny code
	ENDIF
ENDIF
=gfunuse("fllit", l_fllit)
SELECT (n_Curarea)

**********************************************************************************
* Procedure: Fltagset
*
* Abstract: User interface to reset individual tag 1st look flags when case
*  1st look flag is reset
* Called by: inst1lk.spr
**********************************************************************************
PROCEDURE Fltagset
PARAMETER l_Flook, c_field
LOCAL n_Curarea, l_Userec, c_Msg1, c_Heading,l_Change
n_Curarea = SELECT()

c_Msg1 = IIF( c_field = "first_look", ;
	"Apply case's changed first-look setting to existing tags?", ;
	"Apply case's changed first-look attorney to existing tags?")

o_message = CREATEOBJECT('rts_message_yes_no',c_Msg1)
o_message.SHOW
l_Change=IIF(o_message.exit_mode="YES",.T.,.F.)			&&THISFORM.return_value1=1
o_message.RELEASE
IF l_Change
	IF c_field = "first_look"
**10/01/18 SL #109598
*",id_tblrequests FROM tblrequest WITH (nolock,INDEX (ix_tblrequests_2)) " +
		c_sql = "SELECT cl_code, tag, descript, CASE first_look WHEN 1 THEN 'Y' ELSE 'N' END AS First_look " + ;
			",id_tblrequests FROM tblrequest WITH (nolock) " + ;
			"WHERE cl_code='"+MASTER.cl_code+"' AND tblrequest.status IN ('W','A','T') AND active=1 AND DELETED IS NULL ORDER BY tag"
	ELSE
**10/01/18 SL #109598
*",id_tblrequests FROM tblrequest WITH (nolock,INDEX (ix_tblrequests_2))" +
		c_sql = "SELECT cl_code,tag,descript,'Y' AS First_look " + ;
			",id_tblrequests FROM tblrequest WITH (nolock)" + ;
			"WHERE cl_code='"+MASTER.cl_code+"' AND tblrequest.status IN ('W','A','T') AND tblrequest.first_look=1 AND active=1 AND DELETED IS NULL ORDER BY TAG"
	ENDIF
	omed=CREATEOBJECT('cntdataconn')
*omed=CREATEOBJECT('medgeneric')
	omed.sqlpassthrough(c_sql,'tmpTags')

	IF RECCOUNT('tmpTags') > 0			&&_TALLY > 0
		c_Heading = IIF( c_field = "first_look", ;
			"First Look", ;
			"Chg Attny")

		oflbrow=CREATEOBJECT('frmfltagreset')
		oflbrow.grd.Column1.Header1.CAPTION=c_Heading
		oflbrow.SHOW
		IF oflbrow.exit_mode='OK'
			o_message = CREATEOBJECT('rts_message_yes_no',"Are you sure you want to save these changes?")
			o_message.SHOW
			l_Change=IIF(o_message.exit_mode="YES",.T.,.F.)			&&THISFORM.return_value1=1
			o_message.RELEASE
			IF l_Change		&& gfNo_Yes('Are you sure you want to save these changes?', 'Y')
				WAIT WINDOW "Updating records.  Please wait..." NOWAIT NOCLEAR
				c_dtoday=DTOC(DATE())
				SELECT tmpTags
				SCAN
					IF c_field = "first_look"
						c_sql="UPDATE tblrequest SET first_look="+IIF(tmpTags.first_look='Y','1','0')+;
							",fl_Atty="+omed.cleanstring(IIF(tmpTags.first_look='Y',caseinstruct.flookatty,''))+",editedby='&pc_userid.',edited='&c_dtoday.' "+;
							"WHERE id_tblrequests='"+tmpTags.id_tblrequests+"' AND active=1 AND DELETED IS NULL"
					ELSE
						c_sql="UPDATE tblrequest SET fl_Atty="+omed.cleanstring(IIF(tmpTags.first_look='Y',caseinstruct.flookatty,''))+ ;
							",editedby='&pc_userid.',edited='&c_dtoday.' "+;
							"WHERE id_tblrequests='"+tmpTags.id_tblrequests+"' AND active=1 AND DELETED IS NULL"
					ENDIF
					omed.sqlpassthrough(c_sql)

				ENDSCAN
				WAIT CLEAR
			ENDIF
		ENDIF

		oflbrow.RELEASE
	ENDIF
*--	=gfunuse("record", l_Userec)
ENDIF

IF (NOT l_Flook)
	o_message = CREATEOBJECT('rts_message_yes_no',"Update the ship methods of first-look attorney's orders?")
	o_message.SHOW
	l_Change=IIF(o_message.exit_mode="YES",.T.,.F.)			&&THISFORM.return_value1=1
	o_message.RELEASE
	IF l_Change
		pc_clcode=MASTER.cl_code
		pc_Flatty=caseinstruct.flookatty
		pc_Flship = IIF( EMPTY(caseinstruct.flshiptype), ;
			"H", caseinstruct.flshiptype)
		DO lpshtype
	ENDIF
ENDIF

SELECT (n_Curarea)
**********************************************************************************
* Procedure: Lpflag
*
* Abstract: User interface to reset individual tag 1st look flags when case
*  1st look flag is reset
* Called by: inst1lk.spr
**********************************************************************************
PROCEDURE Lpflag
PARAMETER c_Level, l_type, c_field
IF PARAMETERS() < 3
	c_field = "first_look"
ENDIF
PRIVATE n_TmpArea, c_Curtag
DO CASE
CASE c_Level = "TAG"
	IF first_look ="Y"
		REPLACE first_look WITH 'N'
	ELSE
		REPLACE first_look WITH 'Y'
	ENDIF
	KEYBOARD '{ctrl+w}'
	RETURN
CASE c_Level = "ALL"
	SCAN
		IF first_look ="Y"
			REPLACE first_look WITH 'N'
		ELSE
			REPLACE first_look WITH 'Y'
		ENDIF
	ENDSCAN
	GO TOP
	KEYBOARD '{ctrl+w}'
	RETURN
CASE c_Level = "SAVE"
*--Confirm that the changes before updating record table
	IF gfNo_Yes('Are you sure you want to save these changes?', 'Y')
		DO waitscr WITH "Updating records.  Please wait..."
		n_TmpArea = SELECT()
		SELECT RECORD
		c_Curtag = ORDER()
		SET ORDER TO cltag IN RECORD
		SELECT (n_TmpArea)
		SCAN
			IF SEEK(cl_code+"*"+STR(TAG), "record")
				IF c_field = "first_look"
					l_firstlk = IIF( first_look = 'Y', .T., .F.)
					SELECT RECORD
					DO WHILE NOT RLOCK()
					ENDDO
					REPLACE RECORD.first_look WITH l_firstlk, ;
						fl_atty WITH IIF( l_firstlk, pc_Flatty, "")
					UNLOCK
					DO GlobUpd WITH "RECORD", RECNO()
					SELECT (n_TmpArea)
				ELSE
					IF first_look = 'Y'
						SELECT RECORD
						DO WHILE NOT RLOCK()
						ENDDO
						REPLACE fl_atty WITH pc_Flatty
						UNLOCK
						DO GlobUpd WITH "RECORD", RECNO()
						SELECT (n_TmpArea)
					ENDIF
				ENDIF
			ENDIF
		ENDSCAN
		DO waitclr
	ENDIF
CASE c_Level = "CANCEL"
	IF gfNo_Yes('Are you sure you want to cancel these changes?', 'N')
		RETURN
	ENDIF
*--do nothing with the temp file
ENDCASE
KEYBOARD '{escape}'
RETURN

**************************************************************************************
* FUNCTION: Partatty
*
* Abstract: Builds popup of participating attorneys for a case and
* returns user selection
* Called by: flcov1.spr, procedure atcode
* Calls:
**************************************************************************************
FUNCTION partatty
PARAMETERS c_Type, c_Flatcode

IF PARAMETERS() < 2
	c_Flatcode = ""
ENDIF

PRIVATE c_Tmp, n_Curarea, l_Usetab, c_atcode, c_Code, n_Ncnt, ;
	l_Select, l_NotFnd
l_NotFnd = .F.                                  && used for validation of user input at code

IF PARAMETERS() = 0
	c_Type = "LIST"
	l_Select = .T.                               && indicates call to select of atty from popup list
ELSE
	l_Select = .F.
ENDIF

n_Curarea = SELECT()
l_Usetab = gfuse("tabills")
l_usetaa = gfuse("taatty")
*--selection process for 1st look attny, from participating attnys
*--build array of participating attroney info
SELECT Tabills
SET ORDER TO
SET RELATION TO at_code INTO taatty
CREATE CURSOR curPart (at_code c(8), NAME c(40))

SELECT at_code FROM Tabills INTO ARRAY a_Attny ;
	WHERE cl_code = pc_clcode AND invoice_no = 0

IF _TALLY > 0
*--make sure plaintiff attney is in the list
	IF ASCAN(a_Attny, pc_platcod) = 0
		DIMENSION a_Attny(ALEN(a_Attny)+1)
		a_Attny(ALEN(a_Attny)) = pc_platcod
	ENDIF
	FOR n_Ncnt = 1 TO ALEN(a_Attny)
		IF SEEK(a_Attny(n_Ncnt),"taatty")
			IF pl_CAVer
				c_name = ALLTRIM(taatty.firm)
			ELSE
				IF NOT EMPTY(taatty.newlast)
					c_name = ALLTRIM(taatty.newlast) + ", " + ;
						ALLTRIM(taatty.newfirst)
				ELSE
					c_name = ALLTRIM(taatty.firm)
				ENDIF
			ENDIF

		ELSE
			m.name = ""
		ENDIF
		m.name = c_name
		m.at_code = a_Attny(n_Ncnt)
		INSERT INTO curPart FROM MEMVAR
	ENDFOR
ENDIF

*--if call is to validate user input atty code
IF c_Type = "VALID"
	IF ASCAN(a_Attny, c_Flatcode) = 0
		l_NotFnd = .T.
		= gfmsg("ERROR: Code not for a participating attorney.")
		c_Flatcode = ""
	ENDIF
ENDIF

IF l_Select OR l_NotFnd
*--now display the popup list for the user
	DEFINE POPUP popPart PROMPT FIELD NAME ;
		FROM 9,4 TO 17,50 SCROLL SHADOW;
		TITLE " Participating Attorneys " ;
		FOOTER " Select new attorney. <ESC> to cancel. "
	ON SELECTION POPUP popPart DEACTIVATE POPUP popPart
	ACTIVATE POPUP popPart

	IF NOT LASTKEY() = 27
		c_Flatcode = curPart.at_code
		IF c_Flatcode <> pc_Flatty
			c_Flship = ""
			DO lpAtShip WITH c_Flatcode
			m.flshiptype = c_Flship
			c_Flship = IIF(c_Flship = "E", "Electronic", ;
				IIF(c_Flship = "C", "CD", "Hard Copy"))
		ENDIF
	ENDIF
ENDIF

USE IN curPart
=gfunuse("tabills",l_Usetab)
=gfunuse("taatty",l_usetaa)
SELECT (n_Curarea)
RETURN c_Flatcode

**************************************************************************************
* Procedure: LpAtship
* Abstract: Returns the attorney's default ship-to method
* Called by: procedure partatty, tabills.prg
**************************************************************************************
PROCEDURE lpAtShip
PARAMETER c_atcode
LOCAL c_sql
c_Flship='H'
omed=CREATEOBJECT('cntdataconn')
*omed=CREATEOBJECT('medgeneric')
**10/01/18 SL #109598
*c_sql="SELECT flshiptype FROM tbldefendant WITH (nolock,INDEX (ix_tbldefendant_1)) WHERE at_code='&c_atcode.' AND active=1 AND deleted IS null"
c_sql="SELECT flshiptype FROM tbldefendant WITH (nolock) WHERE at_code='&c_atcode.' AND active=1 AND deleted IS null"
omed.sqlpassthrough(c_sql,'curtemp')
IF RECCOUNT('curtemp')>0
	c_Flship=IIF( NOT EMPTY(curtemp.flshiptype), curtemp.flshiptype, c_Flship)
ENDIF
IF USED('curtemp')
	USE IN curtemp
ENDIF

**************************************************************************************
* Procedure: LpAtname
*
* Abstract: Returns the attorney's name from the associated code. defaults to
* the name first, goes to firm if no last name
*
* Called by: inst1lk.spr
**************************************************************************************
PROCEDURE lpAtname
PARAMETERS lcAtcode, c_FLtship
IF PCOUNT() < 2
	c_FLtship = ""
ENDIF
LOCAL c_Flatty
c_Flatty = ''
PRIVATE lcName
omed=CREATE('cntdataconn') &&"medgeneric")
c_atcodeclean=omed.cleanstring(lcAtcode)
omed.sqlpassthrough("select dbo.gfAtName(&c_atcodeclean.) AS atname", "rtncursor")
IF RECCOUNT("rtncursor")>0
	c_Flatty = rtncursor.atname
ENDIF
**10/01/18 SL #109598
*omed.sqlpassthrough("select flshiptype AS flshiptype from tbldefendant WITH (nolock,INDEX (ix_tbldefendant_1)) WHERE at_code="+c_atcodeclean, "rtncursor")
omed.sqlpassthrough("select flshiptype AS flshiptype from tbldefendant WITH (nolock) WHERE at_code="+c_atcodeclean, "rtncursor")
IF RECCOUNT("rtncursor")>0
	c_FLtship = rtncursor.flshiptype
ENDIF

IF PCOUNT() < 2
	RETURN c_Flatty
ELSE
	RETURN (c_Flatty + ", " + c_FLtship)
ENDIF

**************************************************************************************
* Procedure: FLINCOME
*
* Abstract: Alert user that tag is flagged as 1st look and call processing screens
* Called by: depopts.prg
* Calls: flproc1.spr, POSTREV, Add88txn, gfAtname.prg, lpAtname
**************************************************************************************
PROCEDURE FLIncome
PARAMETER n_1lklvl,FRMref_depotions
LOCAL c_Flatty, lnOk, n_Action,onrs,omedfl, ;
	c_Attfirm, n_Attphone, d_deliv, d_return, n_numdays, c_typeday,n_tag,n_lrsno
n_Attphone = 0                                  && atty phone number
c_Attfirm = ""                                  && atty firm

omedfl=CREATEOBJECT('cntdataconn')
*omedfl=CREATEOBJECT('medgeneric')

**10/01/18 SL #109598
*c_sql= "SELECT * FROM tblrequest WITH (nolock,INDEX (ix_tblrequests_2)) WHERE cl_code='"+pc_clcode+"' AND tag="+
c_sql= "SELECT * FROM tblrequest WITH (nolock) WHERE cl_code='"+pc_clcode+"' AND tag="+;
	STR(pn_tag)+" AND active=1 AND deleted IS null"
omedfl.sqlpassthrough(c_sql,'record')


*--08/25/21 kdl: added pl_Oak_FL_Type - flag to identify Oakland fist-look login path (based on requesting atorney) [247599]
*-- use this to also trigger inserting the fL sign-off pages.
pl_Oak_FL_Type=.F.
n_curarea = SELECT()
omedfl.sqlpassthrough("exec [dbo.getOakFlLoginType] " + ALLTRIM(STR(pn_lrsno)), 'fltype')
IF USED("fltype")
	pl_Oak_FL_Type = NVL(fltype.bresult,.F.)
	USE IN "fltype"
ENDIF
SELECT (n_curarea)

IF RECCOUNT('record') = 1
	IF RECORD.first_look
*--Determine current 1st look status
		n_1lklvl = gflkStat("LEVEL", RECORD.first_look, RECORD.STATUS, RECORD.TAG)
	ELSE
		n_1lklvl = 0                              && not 1st look
	ENDIF
ENDIF

IF n_1lklvl >= 1
	DO CASE
	CASE n_1lklvl = 1
		c_StatTxt = "WAIT"
	CASE n_1lklvl = 2
		c_StatTxt = "PRE-REVIEW"
	CASE n_1lklvl = 3
		c_StatTxt = "ATTY. REVIEW/POST-REVIEW"
	CASE n_1lklvl = 4
		c_StatTxt = "RECEIVED"
	CASE n_1lklvl = 5
		c_StatTxt = "RELEASED FOR DISTRIBUTION"
	CASE n_1lklvl = 6
		c_StatTxt = "ORDER-FULFILLMENT"
	ENDCASE
	lnOk = 0
	c_Flatty = ""
	n_Action = 0
	onrs=CREATEOBJECT('depdisposition.frmflproc1',pc_plnam,pn_lrsno,pc_Descrpt,pn_tag,pc_mailid,pc_Tflatty,;
		c_StatTxt,n_1lklvl,FRMref_depotions)
	onrs.SHOW
	IF TYPE("onrs")="O"
		n_Action=onrs.n_Action
	ELSE
		n_Action = 4
	ENDIF

	DO CASE
	CASE n_Action = 1                         && pre-review procesing
		n_1lklvl = IIF( n_1lklvl > 2, 2, n_1lklvl)
		onrs.RELEASE
		RELEASE onrs
		RETURN

	CASE n_Action = 2                         && print cover docs
		n_1lklvl = 3
*--adj delivery date based on new buisiness rule of 1 calender
*--day from received date for electronic, 2 for paper
		IF NOT ALLTRIM(NVL(pc_offcode,'P'))=='C'
			c_sql="SELECT * FROM tblflentry WITH (nolock) WHERE cl_code='"+pc_clcode+"' AND tag="+;
				STR(pn_tag)+" AND txn_code=1 AND active=1 AND deleted IS null"
			omedfl.sqlpassthrough(c_sql,"flentry")
			IF RECCOUNT("flEntry")>0 AND ;
					NOT EMPTY(flentry.txn_date)
				d_recieved = IIF(TYPE('flentry.txn_date')='T',TTOD(flentry.txn_date),flentry.txn_date)
			ELSE
				d_recieved = DATE()
			ENDIF
*--override of recieved date if more than 3 days after said date
			IF (DATE() - d_recieved) >= 3
				d_recieved = DATE()
			ENDIF
			*--7/27/22 kdl: remove 1 day delay for electronic delivery [267860]
			n_numdays = IIF( pc_Flship = "E", 0, 2)
			*--n_numdays = IIF( pc_Flship = "E", 1, 2)

			d_deliv = gfChkDat( d_recieved + n_numdays, .F., .F.)
&&  atty is 3 business days from today
			n_numdays = IIF( EMPTY(pn_Fldays), 0, pn_Fldays) && Review period in days
			c_typeday = IIF( EMPTY(pc_Fltype), "C", pc_Fltype) && type of days, Business or Calendar
			l_Has88 = .F.                          && flag for existence of 88 transaction record for the tag
			DO Add88txn IN flprint WITH l_Has88, d_deliv, n_numdays, c_typeday
		ELSE
			n_tag=pn_tag
			n_lrsno=pn_lrsno
			DO OakFlook IN Flproc WITH n_lrsno,n_tag
		ENDIF
	CASE n_Action = 3                         && post-review processing
		DO Postrev &&WITH onrs
		IF pl_Distrib = .T.
*--update the deponent summary screen
			DO upd_depsum WITH FRMref_depotions
		ENDIF

	CASE n_Action = 4                         && cancel
	ENDCASE

	onrs.RELEASE

	RELEASE onrs,omedfl
	omedfl=.NULL.
	onrs=.NULL.
*--prevent incoming program from being activated
	n_1lklvl = -1
	RETURN
ELSE
	RETURN
ENDIF

**********************************************
** *--update the deponent summary screen

**********************************************
PROCEDURE upd_depsum
PARAMETERS frm_ref
LOCAL c_statusname,c_sql,omedfl,c_qual
omedfl=CREATEOBJECT('cntdataconn')
*omedfl=CREATEOBJECT('medgeneric')
**10/01/18 SL #109598
*c_sql="SELECT * FROM tblrequest WITH (nolock,INDEX (pk_tblrequests))  WHERE id_tblrequests='"+frm_ref.FRMdepsummary_request.id_tblrequests+"'"
c_sql="SELECT * FROM tblrequest WITH (nolock)  WHERE id_tblrequests='"+frm_ref.FRMdepsummary_request.id_tblrequests+"'"
omedfl.sqlpassthrough(c_sql,"thisrequest")
c_statusname = ''
IF pl_Distrib
	FOR n_scnt=1 TO 2
		IF n_scnt=1
			c_statusname = IIF(thisrequest.STATUS='R','RCVD','')
		ENDIF
		IF n_scnt=2 AND thisrequest.nrs
			c_statusname = IIF(EMPTY(c_statusname),'NRS'+IIF(NOT EMPTY(thisrequest.nrs_code),+'-'+thisrequest.nrs_code,'') ;
				,c_statusname+'+NRS')
		ENDIF
	ENDFOR
	c_qual=IIF(NOT thisrequest.inc,"FL_REC","FL_INC")
ELSE
	c_statusname = 'FRST-LK'
	c_qual= "ATTY-R"
ENDIF

frm_ref.FRMdepsummary_request.STATUS=thisrequest.STATUS
frm_ref.FRMdepsummary_request.statusname=c_statusname
frm_ref.FRMdepsummary_request.qualif=c_qual
frm_ref.FRMdepsummary_request.fin_date=DTOC(d_today)
frm_ref.FRMdepsummary_request.PAGES=thisrequest.PAGES
frm_ref.FRMdepsummary_requestupdate
USE IN thisrequest

**************************************************************************************
* PROCEDURE: CHG1ATTY
* Abstract: Confirms chnage of 1st look attny, performs change, calls tag update process
* Called by: Tabills.prg
* Calls:
**************************************************************************************
PROCEDURE Chg1atty
PARAMETER c_Attcode,c_stype
c_stype=NVL(c_stype,'H')
LOCAL c_CurOrd,n_Curarea,l_UseInst,l_Confirm,c_sql
n_Curarea = SELECT()
omed=CREATEOBJECT('cntdataconn')
*omed=CREATEOBJECT('medgeneric')
o_message = CREATEOBJECT('rts_message_yes_no',"Change the first-look attorney for this case?")
o_message.SHOW
l_Confirm=IIF(o_message.exit_mode="YES",.T.,.F.)
o_message.RELEASE
IF l_Confirm
**10/01/18 SL #109598
*c_sql="SELECT * FROM tblinstruct WITH (nolock,INDEX (ix_tblinstruct_1)) WHERE cl_code='&pc_clcode.' AND active=1 AND deleted IS null"
	c_sql="SELECT * FROM tblinstruct WITH (nolock) WHERE cl_code='&pc_clcode.' AND active=1 AND deleted IS null"
	omed.sqlpassthrough(c_sql,'instruct')
	IF RECCOUNT('instruct')>0
		c_sql="UPDATE tblinstruct SET Flookatty='&c_Attcode.',FlShipType='&c_stype.' " + ;
			"WHERE cl_code='&pc_clcode.' AND active=1 AND deleted IS null"
		omed.sqlpassthrough(c_sql)
	ELSE
		o_message = CREATEOBJECT('rts_message',"First-look Atty can not be saved until instructions are created.")
		o_message.SHOW
		RELEASE o_message
	ENDIF
ENDIF
SELECT (n_Curarea)

**************************************************************************************
* PROCEDURE: POSTREV
* Abstract: Main 1st-look post review procesing procedure
* Called by: flproc1.spr
* Calls: flpost.spr
**************************************************************************************
PROCEDURE Postrev
*LPARAMETERS o_callingform
LOCAL  opost,lrelease
PRIVATE n_Curarea, c_CurOrd, c_TiffFile, c_DirEx, c_DirNew, c_Comm, ;
	c_DirBase, c_DirRed, c_DirDone, l_Used, n_Check, a_Check, l_Files, ;
	l_Redacted, c_DirArch, c_ImageDb, l_Redactok,l_Noimages
l_Noimages = .F. 	&& flag to trak tags that have no RSS images (they just have a PDF file)
l_Redacted = .F.                                && redacted flag
n_Curarea = SELECT()
l_Redactok = .T.
l_Files=.F.
c_DirBase = "T:\KOPFLOOK\"
c_DirBase =  ADDBS(c_DirBase)                   && base image directory
c_DirRed  = c_DirBase + TRANS(pn_lrsno,"@L 99999999")+"\"+ ;
	TRANS(pn_tag,"@L 99999999") + "\Redact\"     && redacted image directory

WAIT WINDOW "Locating first-look image files" NOWAIT NOCLEAR

c_DirEx=lffindfold(TRANS(pn_lrsno,"@L 99999999")+"\"+ ;
	TRANS(pn_tag,"@L 999"))
WAIT CLEAR
*--5/30/19: [87505]
LOCAL lpdf,cextension,cskeleton,cjustext
lpdf= IIF(ALLTRIM(UPPER(NVL(pc_ScanDocType,"")))=="PDF", .T.,.F.)

*--12/3/19: need to use upper case file extension [153281]
cextension = IIF(lpdf, ".PDF",".TIF")
*--cextension = IIF(lpdf, ".pdf",".tif")

cskeleton = IIF(lpdf, "*.pdf","*.tif")
cjustext= IIF(lpdf, "PDF","TIF")

*--11/30/17: accomodate large page counts [74609]; does not appear that array a_files is used anywhere but here, so no need to write to it
IF NOT EMPTY(c_DirEx) AND DIRECTORY(NVL(c_DirEx,""))
	c_DirEx=ADDBS(ALLTRIM(c_DirEx))
	fso=CREATEOBJECT("scripting.filesystemobject")
	fld=fso.getfolder(c_DirEx).FILES
	n_Cnt = 0
	IF fld.COUNT > 0
		WAIT WINDOW "Collecting page data for first-look release. Please wait..." NOWAIT
		FOR EACH fil IN fld

*--5/30/19: [87505]
			IF UPPER(JUSTEXT(fil.NAME))==(cjustext)
*--IF UPPER(JUSTEXT(fil.NAME))=="TIF"
				n_Cnt = n_Cnt + 1
				DIMENSION a_Files[n_Cnt,2]
				a_Files[n_Cnt, 1] = fil.NAME                && file id
				a_Files[n_Cnt, 2] = PADL(ALLTRIM(STR(n_Cnt)),8,"0")+cextension && bates number, page id, always start at 0
*--a_Files[n_Cnt, 2] = PADL(ALLTRIM(STR(n_Cnt)),8,"0")+".TIF" && bates number, page id, always start at 0
			ENDIF
		NEXT
		WAIT CLEAR

	ELSE
		gfmessage("No first-look images found for this tag.")
		RETURN
	ENDIF
*--5/30/19: programmers note - for PDF format inbound documents, the RSS images are in a multi-page PDF: file count will be "1" [87505]
	l_Files=IIF(n_Cnt > 0,.T.,.F.)

*!*		l_Files=IIF(ALEN(a_Files,1) > 0,.T.,.F.)
*!*		n_Len = ADIR(a_dir, (c_DirEx + "P" + "*.tif"))

*!*		IF n_Len>0
*!*			l_Files=.T.
*!*		ELSE
*!*			gfmessage("No first-look images found for this tag.")
*!*			RETURN
*!*		ENDIF

*!*		FOR n_Cnt = 1 TO n_Len
*!*			DIMENSION a_Files[n_Cnt,2]
*!*			c_file = ALLTRIM(a_dir[ n_cnt, 1])
*!*			a_Files[n_Cnt, 1] = c_file                && file id
*!*			a_Files[n_Cnt, 2] = PADL(ALLTRIM(STR(n_Cnt)),8,"0")+".TIF" && bates number, page id, always start at 0
*!*		ENDFOR

*--if redacted, and there are files, make sure redacted directory has been
*--created
	IF (pl_Redacted OR pl_flimgmod) AND l_Files
		DO lpMakeRd WITH c_DirEx,c_DirRed
	ENDIF

ELSE
	c_sql = "exec dbo.GetFlnoimages '&pc_litcode.','&pc_area.'"
	oConn=CREATEOBJECT('cntdataconn')
	oConn.sqlpassthrough(c_sql,'flimages')
	IF RECCOUNT('flimages')>0
		l_Noimages = .T.
		l_Redactok = .F.
	ENDIF
	IF USED("flimages")
		USE IN flimages
	ENDIF
	RELEASE oConn
	IF l_Noimages = .F.
		gfmessage("No first-look images found for this tag.")
		RETURN
	ENDIF
ENDIF

*--the post processing screen
opost=CREATEOBJECT("depdisposition.frmflpost",pc_plnam,pn_lrsno,pc_Descrpt,pn_tag,pc_mailid,n_1lklvl,l_Files,l_Redactok)
opost.SHOW
lrelease=opost.flrelease

SELECT (n_Curarea)
RELEASE opost 		&& 07/22/2009 MD
opost=NULL

IF lrelease
	DO flreceiv WITH l_Noimages
ENDIF

RELEASE n_Curarea, c_CurOrd, c_TiffFile, c_DirEx, c_DirNew, c_Comm, ;
	c_DirBase, c_DirRed, c_DirDone, l_Used, n_Check, a_Check, l_Files, ;
	l_Redacted, c_DirArch, c_ImageDb, l_Redactok, a_dir, a_Files

RETURN


**************************************************************************************
* PROCEDURE: LPMAKERD
* Abstract: Make the redaction directory and copy files into it
* Called by: procedure postrev
* Calls:
**************************************************************************************
PROCEDURE lpMakeRd
PARAMETER cDirEx,cDirRed
LOCAL a_tmp, n_Cnt, c_DirNew, c_String
c_DirNew =cDirRed

*--always check that the directory does not already exist
IF NOT DIRECTORY(c_DirNew)
	WAIT WINDOW "Preparing redaction image folder. Please wait." NOWAIT NOCLEAR
	MKDIR &c_DirNew
*--5/30/19: for PDF RSS format, need to split the multi-page PDF into single-page PDFs [87505]
	IF ALLTRIM(UPPER(NVL(pc_ScanDocType,"")))=="PDF"
		LOCAL cPdf
		cPdf = ADDBS(cDirEx) + "rs-" + PADL(ALLTRIM(pc_lrsno),8,"0") + "-" + PADL(ALLTRIM(pc_tag),3,"0") + ".pdf"
		IF FILE(cPdf)
			cParam = "SYSID|rtslpMakeRd SPLIT4RSS " + cPdf + " " + c_DirNew + " p"
			RUN /N "T:\Release\Net\AmyProcesses\AmyuniProcesses.exe " &cParam
			DO WHILE isrunning("AmyuniProcesses.exe")
				LOOP
			ENDDO
		ELSE
		ENDIF
	ELSE
		c_Comm = ADDBS(cDirEx) + "*.tif " + c_DirNew
		COPY FILE (ADDBS(cDirEx) + "*.tif") TO (ADDBS(c_DirNew) + "*.tif")
	ENDIF

	WAIT CLEAR
ENDIF
RETURN

**************************************************************************************
* PROCEDURE: REDACT
* Abstract: Redact user specified pages
* Called by: flpost.spr
* Calls: procedures pagesub, gfparse.  waitscr.prg, waitclr.prg
**************************************************************************************
PROCEDURE Redact
PARAMETERS c_Pages,c_Redtxt,n_startbate
PRIVATE laPages, n_count,nbates

nbates=IIF(PCOUNT()<3,0000,n_startbate)

DIMENSION laPages[1]

WAIT WINDOW "Redacting page(s).  Please wait..." NOWAIT NOCLEAR
*--DO waitscr WITH "Redacting page(s).  Please wait..."

DO gfparse WITH c_Pages,laPages

lcAction = "REDACT"                             && lcPage is either Redact (for a Redacted Page) or the actual path to another page.
lcSub = ""
FOR n_count = 1 TO ALEN(laPages,1)              && For each page
	DO PageSub WITH c_DirBase, pn_lrsno, pn_tag, laPages[n_Count], c_Redtxt, lcSub,.F.,nbates
ENDFOR

WAIT CLEAR
*--DO waitclr

**************************************************************************************
* PROCEDURE: PAGESUB
* Abstract: PageSub.prg - Substitute a page (Image) in a Directory with
*           another page (either Redacted Page or user selected Page)
* Called by: flpost.spr
* Calls: procedure newpage, gfmsg.prg
**************************************************************************************
PROCEDURE PageSub
** PageSub.prg - Substitute a page (Image) in a Directory with
** another page (either Redacted Page or user selected Page)

PARAMETERS lcDir, lnRt, lnTag, lnPage, lcAction, lcSub, llTest,nstartbates

PRIVATE lnTiffMade, n_Errors, h_Time, n_Time,nresult,cp
LOCAL c_sizefont
n_Errors = 0
lnTiffMade = 0
IF PCOUNT() <= 6
	llTest = .F.
ENDIF
IF PCOUNT() < 7
	nstartbates=0
ENDIF

** Explanation of Parameters:

** lcDir = The Directory where substitution is to be made
** lnRt  = The Rt Number of the Image
** lnTag = The Tag of the Image
** lnPage = The Page number to substitute
** lcAction = Action to take (REDACT - Create a redacted page, TEXT - Convert a given Text file (lcSub) to Tiff
** lcSub  = The Page to substitute with ("Redacted" or full page Text name w/Path)
** llTest = Whether only a test is being carried out, or the actual operation.

lcTiffOut = c_DirRed + Lffilenm(TRANS(lnPage,"@L 99999999")+".Tif","SCAN")
IF NOT FILE(lcTiffOut)
	lpmessage("ERROR: Can not redact page "+ ALLTRIM(STR(lnPage))+ ;
		".  Page not found.")
	RETURN .F.

ENDIF

llTest = .F.
DO CASE
CASE lcAction = "REDACT"
** Create a Redacted Text Page called RedText with a Page Number of lnPage
	lbpage= lnPage + (nstartbates-1)
	lcSub = newPage("c:\RedText.Txt",lbpage, ;
		"THIS PAGE HAS BEEN REDACTED")
	c_sizefont='18bc'
CASE lcAction = "BLANK"
** Create a Blank Text Page called BlnkText with a Page Number of lnPage
	lcSub = newPage("c:\BlnkText.Txt",lnPage, ;
		"THIS PAGE INTENTIONALLY LEFT BLANK")
	c_sizefont='18bc'
CASE lcAction = "TEXT"
*--use the passed file name
	c_sizefont='12c'
ENDCASE


IF lcSub = "ERROR"
	n_Errors = n_Errors + 1
ELSE
	IF !llTest                                   && Only if Not testing
** Convert the Substitute Text page to a Tiff File called ReplTiff
*		c_String = lcSub+" "+lcTiffOut+" 18bc"
		n_r=lfTiffmaker(lcSub,lcTiffOut,c_sizefont)
		n_Errors= IIF(n_r<1,n_Errors+1,n_Errors)
	ELSE
		IF !FILE(lcTiffOut)
			gfmessage("Tiff Page " + ALLT(STR(lnPage)) + " not found to redact!")
			n_Errors = n_Errors + 1
		ENDIF
	ENDIF
ENDIF

IF n_Errors <= 0
	RETURN .T.
ELSE
	gfmessage("ERROR: Page "+ ALLTRIM(STR(lnPage))+ " not redacted.")
	RETURN .F.
ENDIF


**************************************************************************************
* PROCEDURE: Newpage
* Abstract: Prepare a new page with user specified text
* Called by: procedure PAGESUB
* Calls:
**************************************************************************************
FUNCTION newPage
PARAMETERS lcFile, lnPage, lcText
PRIVATE i, lnTxt, c_Text
c_Text = SPACE(5) + ALLTRIM(lcText)
lnTxt = FCREATE(lcFile,0)
IF lnTxt > 0
** Insert blank lines
	FOR i = 1 TO 15
		=FPUTS(lnTxt,SPACE(75))
	ENDFOR

	=FPUTS(lnTxt, c_Text)

	FOR i = 1 TO 19
		=FPUTS(lnTxt,SPACE(75))
	ENDFOR

	=FPUTS(lnTxt,SPACE(45)+ALLTRIM(STR(lnPage)))
	=FCLOSE(lnTxt)
ELSE
	lcFile = "ERROR"
	gfmessage("Could not Create Blank Page...")
ENDIF

RETURN lcFile

**************************************************************************************
* PROCEDURE: FLREPLAC
* Abstract: Substitutes a user specified new page for an existing page
* Called by: flreplac.scx, procedure flreleas
* Calls:
**************************************************************************************
PROCEDURE FLREPLAC
PARAMETERS c_Pages, c_file
PRIVATE laPages, lcAction, n_count
DIMENSION laPages[1]
lcAction = "TEXT"                               && lcPage is either REDACT (for a Redacted Page) or TEXT for Text Page Substitution.

WAIT WINDOW "Replacing page.  Please wait..." NOWAIT NOCLEAR
DO gfparse WITH c_Pages,laPages
FOR n_count = 1 TO ALEN(laPages,1)              && For each page
	DO PageSub WITH c_DirBase, pn_lrsno, pn_tag, laPages[n_Count], lcAction, c_file
ENDFOR

WAIT CLEAR

**************************************************************************************
* PROCEDURE: REPLTIFF
* Abstract: Substitutes a user specified new tiff page for an existing page
* Called by: flreplac.scx
* Calls:
**************************************************************************************
PROCEDURE Repltiff
PARAMETERS c_Oldfile, lnPage  &&c_Newfile
*--01/09/04 kdl start: need to set the properties of the new tiff file to match
*-- system requirments.
PRIVATE c_String, n_Errors, c_parameter, n_File, h_Time, n_Time

n_Errors = 0

c_Newfile = ALLTRIM(c_DirRed + Lffilenm(TRANS(lnPage,"@L 99999999")+".Tif","SCAN"))

c_Oldfile = ALLTRIM(c_Oldfile)

COPY FILE (c_Oldfile) TO (c_Newfile )

*!*	IF n_Errors = 0
*!*		DO waitscr WITH "Replacing page.  Please wait..."
*!*	*--convert page number to file name with path
*!*		c_Oldfile = PADL(c_Oldfile, 8, "0") + ".TIF"
*!*		c_Oldfile = c_DirRed + Lffilenm(c_Oldfile, "SCAN")
*!*		c_String = c_Newfile + " " + c_Oldfile
*!*		! COPY &c_String > nul
*!*		DO waitclr
*!*	ELSE
*!*		= gfmsg("ERROR: Page not replaced! Contact IT department.")
*!*	ENDIF

**************************************************************************************
* PROCEDURE: TIFPARSE
* Abstract:  Extracts data from a file/path name string
* Called by:
* Calls:
**************************************************************************************
PROCEDURE Tifparse
PARAMETERS lcTiff, n_RT, n_tag, n_Page
PRIVATE n_Period, n_Slash1, n_slash2, n_Slash3
lcTiff = ALLTRIM(lcTiff)
n_Slash1 = RAT("\",lcTiff, 1)
n_slash2 = RAT("\",lcTiff, 3)
n_Slash3 = RAT("\",lcTiff, 4)
n_RT = INT(VAL(SUBSTR(lcTiff,n_Slash3+1,8)))
n_tag = INT(VAL(SUBSTR(lcTiff,n_slash2+1,8)))
n_Page = INT(VAL(SUBSTR(lcTiff,n_Slash1+1,8)))

**************************************************************************************
* PROCEDURE: REDACALL
* Abstract: builds list of all pages in release package
* Called by: flpost - redact all option
* Calls:
**************************************************************************************
PROCEDURE Redacall
PARAMETERS c_Redtxt,o_flpost
PRIVATE n_Page, n_count, n_Files, lcAction, c_redpage
c_redpage=''
o_flpost.c_redpage=c_redpage
o_message = CREATEOBJECT('rts_message_yes_no',"Redact ALL pages received for this tag")
o_message.SHOW
l_Change=IIF(o_message.exit_mode="YES",.T.,.F.)			&&THISFORM.return_value1=1

RELEASE o_message 	&& 07/22/2009 MD

IF NOT l_Change		&&gfNo_Yes("Redact ALL pages received for this tag", "N")
	o_flpost.l_continue=.F.
	RETURN
ENDIF
IF ALEN(a_Files,1) > 0
*--build string of all page numbers (tiff files) except the 1st page
	FOR n_count = 2 TO ALEN(a_Files, 1)
		n_Page = INT(VAL(RIGHT(JUSTSTEM(a_Files[n_Count,1]),7)))
*INT(VAL(LEFT(a_Files[n_Count,2],8)))
		c_Page = ALLTRIM(STR(n_Page))
		c_redpage = IIF( n_count = 2, c_Page, ;
			c_redpage + "," + c_Page)
	ENDFOR
*--now call the page redaction screen with the string of all pages.  the user
*--can select the redaction text
	o_flpost.c_redpage=c_redpage
	o_flpost.l_continue=.T.
ELSE
ENDIF

**************************************************************************************
* PROCEDURE: FLADDTXN
* Abstract: Add record to flentry
* Called by: incomong.prg
* Calls: gfUse, gfUnUse, gfPush, gfPop
**************************************************************************************
PROCEDURE FLADDTXN
*--3/23/06 kdl start: modified for VFP system
PARAMETERS lcClCode,ln_Tag,n_txncode,c_atcode,c_descript,l_recinc,l_recnrs,n_lnCount,c_lco
LOCAL lcSQLLine
oflgen=CREATEOBJECT('cntdataconn')
*oflgen= CREATEOBJECT("medgeneric")
lcSQLLine="exec dbo.Putfirstlooktimesheet "+;
	"null"+;
	",'"+lcClCode+"'"+;
	","+ALLTRIM(STR(ln_Tag))+;
	",'"+DTOC(d_today)+"'"+;
	",'"+ALLTRIM(STR(n_txncode))+"'"+;
	",'"+fixquote(c_atcode)+"'"+;
	",'"+fixquote(c_descript)+"'"+;
	","+ALLTRIM(STR(n_lnCount))+;
	",'"+pc_userid+"'"+;
	",'"+NVL(ALLTRIM(pc_offcode),RIGHT(ALLTRIM(lcClCode),1))+"'"+;
	",'"+c_lco+"'"

oflgen.sqlpassthrough(lcSQLLine,'flentry')

**************************************************************************************
* PROCEDURE: FLADDCOMXN
* Abstract: Add record to flcomm
* Called by: incoming.prg
* Calls: gfUse, gfUnUse, gfPush, gfPop
**************************************************************************************
PROCEDURE FlAddCom
*--3/23/06 kdl start: modified for VFP system
LPARAMETERS c_descript, c_clcode, n_txncode, n_tag, c_mailid, n_pagecnt, c_comment, n_timesheettxnid, u_timesheettxnid
LOCAL lcSQLLine

*!*	oflgen=CREATE("medgeneric")
*!*	lcSQLLine="exec dbo.Putfirstlooktimesheet "+;
*!*		"null"+;
*!*		",'"+c_clcode+"'"+;
*!*		","+ALLTRIM(STR(n_tag))+;
*!*		",'"+DTOC(d_today)+"'"+;
*!*		",'"+ALLTRIM(STR(n_txncode))+"'"+;
*!*		",'"+c_mailid+"'"+;
*!*		",'"+fixquote(c_descript)+"'"+;
*!*		","+ALLTRIM(STR(n_pagecnt))+;
*!*		",'"+pc_userid+"'"+;
*!*		",'"+c_comment+"'"+;
*!*		","+STR(n_timesheettxnid)+;
*!*		","+IIF(EMPTY(NVL(u_timesheettxnid,"")),"NULL","'"+u_timesheettxnid+"'")


*!*	oflgen.sqlpassthrough(lcSQLLine)

**************************************************************************************
* PROCEDURE: FLRECEIV
* Abstract: Set the status of the first look tag to received
* Called by: Flpost.spr
* Calls: lfPrnOrder IN printcov.prg, gfuse.prg, gfunuse.prg, waitmsg.prg
*  waitclr.prg
**************************************************************************************
PROCEDURE flreceiv
PARAMETERS lNoimages
IF PCOUNT() <1
	lNoimages = .F.
ENDIF

WAIT WINDOW "Preparing system files for FL release.  Please wait..." NOWAIT NOCLEAR

PRIVATE n_Curarea, c_CurOrd, n_Ncnt, a_Txn, d_Date, l_UseCom, ;
	l_Useflc, l_Usefle, l_Tabills, l_Order, l_TaAtty, llnetwork, ;
	lcPltAtty, n_Indent, l_CovLet, ldOrder, ldDecline, ;
	lnCopy, llFedEx, n_MedPgs, l_incoming,cclcode,ctag,ctxncode

LOCAL c_sql,c_date,lc_status,omedfl
l_incoming = .T.
n_Curarea = SELECT()
c_CurOrd = ORDER()
n_MedPgs = 0
d_Date = DATE()
c_date = DTOC(d_Date)
c_tdate = TTOC(DATETIME())

omedfl=CREATEOBJECT('cntdataconn')

*--12/8/16: check that there the tag is not on Clident Rep hold before starting FL release
c_sql="select count(*) as icount from tblorder where cl_code='&pc_clcode.' AND tag="+STR(pn_tag)+" AND ISNULL(handling,'') = 'R' and active=1"
nr=omedfl.sqlpassthrough(c_sql, "curhandle")
IF USED("curhandle")
	licount = NVL(curhandle.icount,0)
	USE IN curhandle
	IF licount > 0
		gfmessage("The record you are trying to release is on Client Rep hold and cannot be released until the hold is removed.  Please see the client representative with any questions.")
		RETURN
	ENDIF
ENDIF


c_sql="update tbldisttodo set rem_date=getdate(),rem_by='FL_TEMP_HOLD' WHERE lrs_no="+STR(pn_lrsno)+" AND tag="+STR(pn_tag)+;
	" and rem_date is null"
nr=omedfl.sqlpassthrough(c_sql)

c_sql="SELECT * FROM tblflentry WITH (nolock) WHERE cl_code='&pc_clcode.' AND tag="+STR(pn_tag)+" AND active=1 AND deleted IS null order by created desc"
nr=omedfl.sqlpassthrough(c_sql,'flentry')

**10/01/18 SL #109598
*c_sql="SELECT * FROM tbltimesheet WITH (nolock,INDEX(ix_tbltimesheet)) "+
c_sql="SELECT * FROM tbltimesheet WITH (nolock) "+;
	"WHERE cl_code='&pc_clcode.' AND tag="+STR(pn_tag)+" AND txn_code=41 AND active=1 AND deleted IS null"
nr=omedfl.sqlpassthrough(c_sql,'chk_41')
WAIT CLEAR
*--SET STEP ON
IF RECCOUNT('flentry')>0 OR RECCOUNT('chk_41')>0

	lc_status = 'N'
	IF RECCOUNT('flentry')>0
		SELECT COUNT(*) FROM flentry WHERE txn_code = 1 INTO ARRAY aTxn
		IF aTxn > 0
			lc_status = "R"
		ENDIF
	ENDIF

*--lc_status=IIF(RECCOUNT('flentry')>0,'R','N')

	WAIT WINDOW "Updating system files.  Please wait..." NOWAIT NOCLEAR

**10/01/18 SL #109598
*c_sql="SELECT id_tblrequests AS id_tblrequests FROM tblrequest WITH (nolock,INDEX (ix_tblrequests_2)) WHERE cl_code='&pc_clcode.' AND tag="+STR(pn_tag)+" AND active=1 AND deleted IS null"
	c_sql="SELECT id_tblrequests AS id_tblrequests FROM tblrequest WITH (nolock) WHERE cl_code='&pc_clcode.' AND tag="+STR(pn_tag)+" AND active=1 AND deleted IS null"
	nr=omedfl.sqlpassthrough(c_sql,'idrequest')

	IF RECCOUNT('flentry')>0
		omed=CREATE("medtimesheet")
		SELECT flentry
		n_Txnid = txn_id
		SCAN 		&&WHILE cl_code = pc_clcode AND TAG = pn_tag &&AND txn_id = n_Txnid
			cclcode=flentry.cl_code
			ctag=ALLTRIM(STR(flentry.TAG))
			ctxncode=ALLTRIM(STR(flentry.txn_code))
**10/01/18 SL #109598
*c_sql="select * from tbltimesheet with (nolock,INDEX(ix_tbltimesheet)) where cl_code='&cclcode.' and tag=&ctag. "+
			c_sql="select * from tbltimesheet with (nolock) where cl_code='&cclcode.' and tag=&ctag. "+;
				"and txn_code=&ctxncode. and deleted is null and active=1"
			nr=omedfl.sqlpassthrough(c_sql,'isthere')
			IF RECCOUNT('isthere')>0
				LOOP
			ENDIF

			omed.getitem(.NULL.)
			n_timesheet=SELECT()
			SCATTER MEMVAR BLANK
			GATHER MEMVAR

			SELECT flentry
			SCATTER MEMVAR
			IF m.txn_code = 1
				n_MedPgs = m.count
			ENDIF

			REPLACE flentry.txn_date WITH DATETIME() IN flentry

			SELECT (n_timesheet)
			REPLACE cl_code WITH m.cl_code, ;
				TAG WITH m.Tag, ;
				txn_date WITH DTOC(d_today), ;
				txn_code WITH m.txn_code, ;
				DESCRIPT WITH m.descript,;
				txn_id WITH m.txn_id, ;
				COUNT WITH m.count, ;
				o WITH m.o, ;
				rec_nrs WITH m.rec_nrs, ;
				rec_inc WITH m.rec_inc, ;
				mailid_no WITH m.mailid_no, ;
				CreatedBy WITH pc_userid, ;
				ACTIVE WITH .T.,;
				id_tblrequests WITH idrequest.id_tblrequests  IN (n_timesheet)
			omed.updatedata

			c_sql="UPDATE tblflentry SET active=0,deleted='&c_tdate.',deletedby='&pc_userid.' WHERE id_tblflentry='"+m.id_tblflentry+"'"
			nr=omedfl.sqlpassthrough(c_sql)

*--5/27/14 must update the tblcode41 id_tbltimesheet field to reflect the new tbltimesheet.id_tbltimesheet
			IF m.txn_code = 41
				c_sql= "[dbo].[FLcode41updt] '" + m.id_tblflentry+"','" + cclcode + "'," + ctag + ",41,'" + pc_userid + "'"
				nr=omedfl.sqlpassthrough(c_sql)
			ENDIF

			SELECT flentry
		ENDSCAN
	ENDIF
	IF USED('flentry')
		USE IN flentry
	ENDIF

	c_sql="SELECT * FROM tblflcomm WITH (nolock) WHERE cl_code='&pc_clcode.' AND tag="+STR(pn_tag)+" AND active=1 AND deleted IS null"
	nr=omedfl.sqlpassthrough(c_sql,'flcomm')
	IF RECCOUNT('flcomm')>0
		SELECT flcomm
		SCAN 			&&WHILE cl_code = pc_clcode AND TAG = pn_tag
			SCATTER MEMVAR
*GATHER MEMVAR
			m.txn_date = DTOC(d_Date)
			m.created=DTOC(NVL(m.created,{}))
			m.edited=DTOC(NVL(m.edited,{}))
			m.deleted=DTOC(NVL(m.deleted,{}))
			m.retired=DTOC(NVL(m.retired,{}))

			INSERT INTO COMMENT FROM MEMVAR
			o=CREATE("medcomment")
			o.getitem(.NULL.)
			o.updatedata

			c_sql="UPDATE tblflcomm SET active=0,deleted='&c_tdate.',deletedby='&pc_userid.' WHERE id_tblflcomm='"+m.id_tblflcomm+"'"
			nr=omedfl.sqlpassthrough(c_sql)
			SELECT flcomm
		ENDSCAN
	ENDIF
	IF USED('flcomm')
		USE IN flcomm
	ENDIF

*--4/22/14 accomodate FL records with no RSS images
	IF lNoimages = .F.
		DO Flreleas
	ENDIF

*--4/29/09 - set finish date to current date when record status is updated

*// 6/15/10 update revw_stat setting when record released
	crevstatus=""
	IF pl_review AND (d_today <=convrtDate(pd_revstop)  OR EMPTY(convrtDate(pd_revstop)))
		crevstatus=",revw_stat='A'"
	ENDIF

	IF lNoimages = .F.
		c_sql="UPDATE tblrequest SET status='&lc_status.'"+ ;
			crevstatus + ;
			",fin_date='&c_date.',dtflrelease=getdate(),sFlReleaseBy='&pc_userid.',sFlReleaseType='RD' WHERE cl_code='&pc_clcode.' AND tag="+STR(pn_tag)+" AND active=1 AND deleted IS null"
	ELSE
		c_sql="UPDATE tblrequest SET status='&lc_status.'"+ ;
			crevstatus + ;
			",fin_date='&c_date.',distribute=1,dtflrelease=getdate(),sFlReleaseBy='&pc_userid.',sFlReleaseType='RD' WHERE cl_code='&pc_clcode.' AND tag="+STR(pn_tag)+" AND active=1 AND deleted IS null"
	ENDIF
	nr=omedfl.sqlpassthrough(c_sql)

	WAIT CLEAR

*-- generate the order summary sheet at this time
	WAIT WINDOW "Preparing order summary sheet.  Please wait..." NOWAIT NOCLEAR

	c_sql="SELECT * FROM tblcovlet WITH (nolock) WHERE cl_code='&pc_clcode.' AND tag="+STR(pn_tag)+" AND active=1 AND deleted IS null"
	nr=omedfl.sqlpassthrough(c_sql,'covlet')

*--10/13/16: table based check for Zoloft first-look type
	sSql =  "exec [dbo].[GetFlPngValue] '" + ALLTRIM(UPPER(pc_litcode)) + "','" + NVL(ALLTRIM(UPPER(pc_area)),'') + "'"
	nr=omedfl.sqlpassthrough(sSql,'curchecklit')
	lZolType = .F.
	IF RECCOUNT('curchecklit') >0
		lZolType  = curchecklit.bresult
	ENDIF
	IF USED('curchecklit')
		USE IN curchecklit
	ENDIF
*--4/5/17: add variable to trak Zoloft FLR disttodo jobs being posted.
	LOCAL lZolposted
	lZolposted = .F.

*--6/28/16 - add the ZOF/GSK litigation/area to the KFR jobs generater process
*--4/22/14 - for zoloft, generate fl release notification job
	IF lZolType = .T.
*--IF UPPER(ALLTRIM(pc_litcode))=="ZOL" OR UPPER(ALLTRIM(pc_litcode))=="EFF" OR (UPPER(ALLTRIM(pc_litcode))=="ZOF" AND UPPER(ALLTRIM(pc_area))=="GSK")
*-- check that the PDF file is availabe
		LOCAL bZolnotify,bPdfexists,spdfpath,spdfname
		bZolnotify = .F.
		bPdfexists = .F.
		c_sql = "exec [dbo].[GetzolPdfname] " + ALLTRIM(STR(pn_lrsno)) + "," + ALLTRIM(STR(pn_tag))
		nr = omedfl.sqlpassthrough(c_sql,'curpdf')
		IF RECCOUNT('curpdf')> 0
			spdfpath = ADDBS(ALLTRIM(curpdf.spdfpath))
			spdfname = ALLTRIM(curpdf.spdfname)
			IF FILE(spdfpath + spdfname)
				bPdfexists = .T.
			ENDIF
		ENDIF
		IF USED('curpdf')
			USE IN curpdf
		ENDIF
		IF bPdfexists
*-- add KFR distribution server jobs if not already there
			bresult = Zoloftdsjobs(pc_clcode,pn_lrsno,pn_tag)
*--4/5/17: zoloft posted result stored
			lZolposted = NVL(bresult,.F.)

			IF bresult = .T.
				c_sql = "exec [dbo].[Addemailjob] 'KFR',''," + ALLTRIM(STR(pn_lrsno)) + "," + ALLTRIM(STR(pn_tag)) + ",'" + ALLTRIM(pc_userid) + "','',''"
				nr=omedfl.sqlpassthrough(c_sql)
				IF nr
					bZolnotify = .T.
				ENDIF
			ELSE
				gfmessage("DS Server job(s) not posted. No KFR email notice added for tag: " +  ALLTRIM(STR(pn_lrsno)) + "." + ALLTRIM(STR(pn_tag)))
			ENDIF
		ELSE
			gfmessage("PDF file not found. No KFR email notice added for tag: " +  ALLTRIM(STR(pn_lrsno)) + "." + ALLTRIM(STR(pn_tag)))
		ENDIF

		IF bZolnotify = .F.
*--if the Zoloft FL release notification job did not get posted, then reset the tag to FL review status.
			c_sql="update tblrequest set redacted=0,distribute=0,status='F' WHERE cl_code='&pc_clcode.' AND tag="+STR(pn_tag)+" AND active=1 AND deleted IS null"
			nr = omedfl.sqlpassthrough(c_sql)

			c_sql="UPDATE tblflentry set active=1,deleted=null WHERE cl_code='&pc_clcode.' AND tag=" + STR(pn_tag)
			nr = omedfl.sqlpassthrough(c_sql)

			c_sql="UPDATE tbltimesheet set active=0,deleted=getdate() WHERE cl_code='&pc_clcode.' AND tag=" + STR(pn_tag) + ;
				" and txn_code=1 and deleted is null"
			nr = omedfl.sqlpassthrough(c_sql)

			gfmessage("FL release failed for tag: " +  ALLTRIM(STR(pn_lrsno)) + "." + ALLTRIM(STR(pn_tag)))

			c_sql="update tbldisttodo set rem_date=null,rem_by='' WHERE lrs_no="+STR(pn_lrsno)+" AND tag="+STR(pn_tag)+;
				" and rem_date is not null and rem_by='FL_TEMP_HOLD'"
			nr=omedfl.sqlpassthrough(c_sql)

			RETURN
		ENDIF
	ENDIF

*--6/28/16: send order summary via email
	c_sql= "SELECT r.nid_tbltagitem, r.status, isnull(r.scan_pages,0) as scan_pages,isnull(i.doc_type,'') as doc_type FROM tblrequest r WITH (nolock) " + ;
		" join tbltagitem i WITH (nolock) on isnull(r.nid_tbltagitem,-1) = i.nid " + ;
		" WHERE r.cl_code= '&pc_clcode.' AND r.tag= " + ALLTRIM(STR(pn_tag)) + " AND r.active=1 AND r.deleted IS null"
	nr=omedfl.sqlpassthrough(c_sql,'curnid')
	IF RECCOUNT('curnid')>0
		SELECT curnid
		c_Nid = ALLTRIM(NVL(curnid.nid_tbltagitem,""))
		c_Status = ALLTRIM(NVL(curnid.STATUS,""))
		iPages = NVL(curnid.scan_pages,0)
		c_Doctype = ALLTRIM(NVL(curnid.doc_type,""))
		IF NOT EMPTY(c_Nid)
			DO callscdoc WITH c_Nid,pn_lrsno,pn_tag,.F.,ALLTRIM(pc_userid),c_Doctype,c_Status,iPages
		ENDIF
		USE IN curnid
*--8/15/16: add distribution server jobs
*--4/5/17: block for zoloft posted
		IF lZolposted=.F.
			DO PostDsJobs WITH pc_clcode, pn_tag
		ENDIF
	ELSE
		llnetwork = .F.                           && direct output to user's printer
		n_Indent = 12                             && Preset line indentation
		lcPltAtty = gfAtName( pc_platcod)
		STORE {01/01/1990} TO ldOrder, ldDecline
		STORE 0 TO lnCopy
		STORE .F. TO llFedEx

		SET PROCEDURE TO GLOBAL ADDITIVE
		SET CONSOLE OFF
		IF TYPE("arAtty") = "U"
			PUBLIC ARRAY arAtty[1]
			arAtty = ""
		ENDIF

		pn_prty2=4
		pn_prty3=6

		DO lfPrnOrder IN printcov                 && order summary sheet procedure
		DO lfPrnBar IN printcov                   && bar codes
		RELEASE arAtty
		SET CONSOLE ON
	ENDIF

	RELEASE omedfl
	RELEASE oflgen
	oflgen=.NULL.
	omedfl = .NULL.

	WAIT CLEAR

ELSE
	IF lNoimages = .F.
		DO Flreleas
	ENDIF
	lpmessage("Missing RECEIVE TRANSACTION. Contact IT depatment.")
ENDIF
SELECT (n_Curarea)

WAIT WINDOW "Releasing system files from FL release.  Please wait..." NOWAIT NOCLEAR
omedfl=CREATEOBJECT('cntdataconn')
*omedfl=CREATEOBJECT('medgeneric')

c_sql="update tbldisttodo set rem_date=null,rem_by='' WHERE lrs_no="+STR(pn_lrsno)+" AND tag="+STR(pn_tag)+;
	" and rem_date is not null and rem_by='FL_TEMP_HOLD'"
nr=omedfl.sqlpassthrough(c_sql)

WAIT CLEAR

RELEASE omedfl
RELEASE oflgen
oflgen=.NULL.
omedfl = .NULL.

*******************************************************************************************
* PROCEDURE: FLreleas
* Abstract: Move first-look scanned files to production directrory and set distribut flag
*  in the record table
* Called by: Procedure flreceiv
* Calls: globupd.prg, waitscr.prg, waitclr.prg
*******************************************************************************************
PROCEDURE Flreleas

PRIVATE c_DirEx, c_DirNew, n_Curarea, c_CurOrd, c_String, n_Cnt, a_tmp, ;
	n_File, h_Time, n_Errors, c_TiffOut, d_Date, n_Copy, c_DirDay, n_Errors, ;
	l_Genfile, l_defaults, l_floldrl

LOCAL o_flrel
*--10/30/19: initialize variable [149281]
c_TiffOut = ""

n_Curarea = SELECT()
d_Date = DATE()
n_Copy = 0                                      && copied files counter
c_DirDay = ""                                   && production day directory variable
n_Errors = 0
*--1/15/04 kdl start: add counter for GEN files
l_Genfile = .F.    && GEN files indicator


*--set the transfer-from directory
*--IF NOT gfNo_Yes("Release this record for shipment to ordering attorneys?", "N")
*--if there are scanned files, move them to production directory
IF l_Files
	WAIT WINDOW "Moving scanned files to production directory." NOWAIT NOCLEAR
	l_floldrl = .F.

*--5/30/19: [87505]
	ocon=CREATEOBJECT('cntdataconn')
	cPdf = ""
	IF ALLTRIM(UPPER(NVL(pc_ScanDocType,"")))=="PDF"
		LOCAL cDirEx, cdirnew, cFolderPath,cRedact

*--get FL release from path
		cRedact =IIF( pl_flimgmod OR pl_Redacted,"y","n")
		cFolderPath = TRANS(pn_lrsno,"@L 99999999")
		IF ALLTRIM(UPPER(cRedact)) == "Y"
			cDirEx = "\\sanstor\image\KOPFLook\" + ADDBS(cFolderPath) + ;
				TRANS(pn_tag,"@L 99999999")
			cDirEx = ADDBS(cDirEx) + "Redact"
		ELSE
			cDirEx = "\\imagesvr\rtdocs\Rt-fl\" + ADDBS(cFolderPath) + ;
				TRANS(pn_tag,"@L 999")
		ENDIF
*--get the FL release to path, and create folder if necessary
*--Cases directory
		cdirnew = "\\imagesvr\rtdocs\Rt-docs\" + cFolderPath
		IF NOT DIRECTORY(cdirnew)
			MKDIR cdirnew
		ENDIF
*--tag folder
		cdirnew = ADDBS(cdirnew) + TRANS(pn_tag,"@L 999")
		IF NOT DIRECTORY(cdirnew)
			MKDIR &cdirnew
		ENDIF
*--rss fFL release multi-pg PDF
		cPdf = ADDBS(cdirnew) + "rs-" + PADL(ALLTRIM(pc_lrsno),8,"0") + "-" + PADL(ALLTRIM(pc_tag),3,"0") + ".pdf"
		IF FILE(cPdf)
			ERASE (cPdf)
		ENDIF

		cParam = "SYSID|rtsflrelease PDFMERGEFOLDER " + '"'+ cDirEx + '" "' + cPdf + '" ' + "*.pdf"
		RUN /N "T:\Release\Net\bytescout\ByteScoutProcesses.exe " &cParam
		DO WHILE isrunning("ByteScoutProcesses.exe")
			LOOP
		ENDDO
*!*			cParam = "FOLDER2PDF " + cDirEx + " " + cPdf
*!*			RUN /N "T:\Release\Net\AmyProcesses\AmyuniProcesses.exe " &cParam
*!*			DO WHILE isrunning("AmyuniProcesses.exe")
*!*				LOOP
*!*			ENDDO

*--8/28/19: update tblrequest,tblflentry page count if necessary.
*--12/19/19: do not update page count if not redacted since page count will be "1" forthe multi-page FL PDF [155313]
		IF ALLTRIM(UPPER(cRedact)) == "Y"
			n_Files = ADIR(a_Files, ADDBS(ALLTRIM(cDirEx)) + '*.pdf')
			c_sql="exec dbo.getrequestbylrsno "+ALLTRIM(STR(pn_lrsno))+","+ALLTRIM(STR(pn_tag))
			ocon.sqlpassthrough(c_sql, "tmprequest")
			IF RECCOUNT('tmprequest')>0 AND n_Files<>tmprequest.scan_pages
				cpages=ALLTRIM(STR(n_Files))
				c_sql="update tblrequest set scan_pages="+cpages+",pages="+cpages+" where id_tblrequests='"+;
					tmprequest.id_tblrequests+"'"
				nr = ocon.sqlpassthrough(c_sql)

				c_sql= "UPDATE tblflentry SET count = "+cpages+" WHERE cl_code='" + tmprequest.cl_code + "'" +;
					" and tag = " + ALLTRIM(STR(tmprequest.TAG)) + " and txn_code = 1 and deleted is null"
				nr = ocon.sqlpassthrough(c_sql)
			ENDIF
		ENDIF
	ELSE
		o_flrel = CREATEOBJECT("depdisposition.frmflrel")
		o_flrel.sqlchk_case( ALLTRIM(STR(pn_lrsno)),ALLTRIM(STR(pn_tag)), IIF( pl_flimgmod OR pl_Redacted, "Y", "N"))
		RELEASE o_flrel		&& 07/22/2009 MD
		o_flrel = .NULL.
	ENDIF

	WAIT CLEAR

	nresult=1
*--there are no FL documents for Zoloft so no pages to replace during release
*--10/13/16: table based check for Zoloft first-look type
*--8/28/19: this call has been moved up in the code [875055]
*--ocon=CREATEOBJECT('cntdataconn')
	sSql =  "exec [dbo].[GetFlPngValue] '" + ALLTRIM(UPPER(pc_litcode)) + "','" + NVL(ALLTRIM(UPPER(pc_area)),'') + "'"
	nr=ocon.sqlpassthrough(sSql,'curchecklit')
	lZolType = .F.
	IF RECCOUNT('curchecklit') >0
		lZolType  = curchecklit.bresult
	ENDIF
	IF USED('curchecklit')
		USE IN curchecklit
	ENDIF
*--SET STEP ON 
	IF ((NOT NVL(pc_offcode,'P')=='C') AND lZolType = .F.)
*--IF ((NOT NVL(pc_offcode,'P')=='C') AND (NOT (UPPER(ALLTRIM(NVL(pc_litcode,'')))=="ZOL" OR UPPER(ALLTRIM(NVL(pc_litcode,'')))=="EFF" OR UPPER(ALLTRIM(NVL(pc_litcode,'')))=="ZOF")))
		WAIT WINDOW "Creating new first-look status page." NOWAIT NOCLEAR
		c_DirNew = "W:\Rt-docs\" + TRANS(pn_lrsno,"@L 99999999")+"\" + ;
			TRANS( pn_tag,"@L 999")
		IF FILE('c:\temp\cover.txt')
			ERASE c:\TEMP\COVER.TXT
		ENDIF
		DO Fltitlpg IN flprint WITH 2
		IF NOT FILE('c:\temp\cover.txt')
			WAIT CLEAR
			gfmessage('Error generating new title page. Contact IT department.')
			RETURN
		ENDIF
*--5/31/19: handle page replacement in multi-pg PDFs [87505]
		IF ALLTRIM(UPPER(NVL(pc_ScanDocType,"")))=="PDF"
			IF FILE(cPdf)
				IF FILE('c:\temp\cover.tif')
					ERASE c:\TEMP\COVER.tif
				ENDIF
				IF FILE("c:\temp\cover.txt")
					nresult=lfTiffmaker('c:\temp\cover.txt',"c:\temp\cover.tif","12bc")
					n_Errors= IIF(nresult<1,n_Errors+1,n_Errors)
*--update the multi-page RSS PDF file
					IF FILE("c:\temp\cover.tif")
						cParam = "SYSID|rtsflrelease1 PAGEREPLACE " + cPdf + " " + "c:\temp\cover.tif " + "1"
						RUN /N "T:\Release\Net\AmyProcesses\AmyuniProcesses.exe " &cParam
						DO WHILE isrunning("AmyuniProcesses.exe")
							LOOP
						ENDDO
					ELSE
						gfmessage("Unable to replace cover page for this PDF record.")
						n_Errors= n_Errors+1
					ENDIF
				ENDIF
			ELSE
				n_Errors= n_Errors+1
			ENDIF
		ELSE
			c_TiffOut = c_DirNew +"\" + Lffilenm("00000001.tif", "SCAN")
*--c_String = ("c:\temp\cover.txt " + c_TiffOut + "12bc")
			nresult=lfTiffmaker('c:\temp\cover.txt',c_TiffOut,"12bc")
			n_Errors= IIF(nresult<1,n_Errors+1,n_Errors)
		ENDIF
		WAIT CLEAR
	ENDIF

	IF NVL(pc_offcode,'P')=='C' AND pl_Redacted
*--need to generate a new billing cover page for redacted records
		LOCAL ldOrder, lDecline, llFound, lnCopy, llFedEx, lcSQLLine,;
			lloGen, lnCurArea, lloForm,l_HasNRS,lcCAPlt
		STORE {01/01/1990} TO ldOrder, ldDecline, ldCancel
		STORE 0 TO lnCopy, lnTota
		c_DirNew = "W:\Rt-docs\" + TRANS(pn_lrsno,"@L 99999999")+"\" + ;
			TRANS( pn_tag,"@L 999")
		pc_softdir=ADDBS("t:\softimgs\" + "R_" + ALLTRIM(pc_lrsno)+ "\" + ;
			PADL(ALLTRIM(pc_tag), 3, "0"))

		WAIT WINDOW "Creating new billing cover page." NOWAIT NOCLEAR
		oGen=CREATEOBJECT('cntdataconn')
*oGen=CREATEOBJECT("transactions.medrequest")
		PUBLIC ARRAY arAtty[1]
		arAtty = ""
		IF pc_rqatcod == "BEBE  3C"
**10/01/18 SL #109598
*lcSQLLine="select * from tblBill with (nolock,INDEX(ix_tblBills_2)) where cl_code='"+
			lcSQLLine="select * from tblBill with (nolock) where cl_code='"+;
				ALLTRIM(pc_clcode)+"' and active=1"
			oGen.sqlpassthrough(lcSQLLine,"viewTaBills")
			SELECT viewTaBills
			SCAN FOR EMPTY(NVL(invoice_no,0))

				llFound = lfOrdStatus( at_code, ;
					@ldOrder, @ldDecline, @lnCopy, @llFedEx, @ldCancel)
				IF EMPTY(oGen.checkDate(ldOrder)) AND ;
						(!EMPTY(oGen.checkDate(ldDecline)) OR ;
						!EMPTY(oGen.checkDate(ldCancel))) && Declined
					SELECT viewTaBills
					LOOP
				ENDIF
				lcCAPlt = gfAtType(at_code)		&& external to printcov
				IF at_code <> pc_rqatcod
					IF NVL(pl_BBAsb,.F.)
						IF lcCAPlt <> "P"
							IF NOT AtShare( at_code, pc_BBRound, pc_plBBAsb, pc_BBDock) && internal to printcov
								SELECT viewTaBills
								LOOP
							ENDIF
						ENDIF
					ENDIF
				ENDIF

				IF NOT lfOrdStatus( at_code, ;
						@ldOrder, @ldDecline, @lnCopy, @llFedEx, @ldCancel)
					SELECT viewTaBills
					LOOP
				ENDIF
				IF EMPTY(oGen.checkDate(ldOrder)) OR ;
						NOT EMPTY(oGen.checkDate(ldDecline)) OR ;
						INLIST(viewTaBills.Response, "F", "C")
					SELECT viewTaBills
					LOOP
				ENDIF
				IF NOT EMPTY(arAtty[1])
					DIMENSION arAtty[ALEN(aratty)+1]
				ENDIF
				arAtty[ALEN(aratty)]=at_code
				SELECT viewTaBills
			ENDSCAN
			SELECT viewTaBills
			USE
		ELSE
**10/01/18 SL #109598
*lcSQLLine="select * from tblBill with (nolock,INDEX(ix_tblBills_2)) where cl_code='"+
			lcSQLLine="select * from tblBill with (nolock) where cl_code='"+;
				ALLTRIM(pc_clcode)+"' and active=1 order by cl_code, at_code"
			oGen.sqlpassthrough(lcSQLLine,"viewTaBills")
			SELECT viewTaBills
			IF RECCOUNT()>0
&& internal to printcov
				IF lfOrdStatus( at_code, ;
						@ldOrder, @ldDecline, @lnCopy, @llFedEx, @ldCancel)
					IF NOT EMPTY(arAtty[1])
						DIMENSION arAtty[ALEN(aratty)+1]
					ENDIF
					arAtty[ALEN(aratty)]=at_code
				ENDIF
			ENDIF
			SELECT viewTaBills
			USE
		ENDIF

		IF NOT EMPTY(arAtty[1])
			pl_softimg = .T.
			l_softpg = .T.
			DO BillCovr WITH pc_clcode, pn_tag
		ENDIF

		RELEASE oGen
		oGen = .NULL.

		cfile=pc_softdir+"6_cabill.txt"
		IF FILE(cfile)
			WAIT WINDOW "Moving new billing cover page to RSS..." NOWAIT NOCLEAR
*--5/31/19: handle page replacement in multi-pg PDFs [87505]
			IF ALLTRIM(UPPER(NVL(pc_ScanDocType,"")))=="PDF"
				IF FILE(cPdf)
					IF FILE('c:\temp\cover.txt')
						ERASE c:\TEMP\COVER.TXT
					ENDIF
					nresult=lfTiffmaker(cfile,"c:\temp\cover.tif","12bc")
					n_Errors= IIF(nresult<1,n_Errors+1,n_Errors)
*--update the multi-page RSS PDF file
					IF FILE("c:\temp\cover.tif ")
						cParam = "SYSID|rtsflrelease2 PAGEREPLACE " + cPdf + " " + "c:\temp\cover.tif " + "1"
						RUN /N "T:\Release\Net\AmyProcesses\AmyuniProcesses.exe " &cParam
						DO WHILE isrunning("AmyuniProcesses.exe")
							LOOP
						ENDDO
					ELSE
						gfmessage("Unable to replace 6_cabill page for this PDF record.")
						n_Errors= n_Errors+1
					ENDIF
				ELSE
					n_Errors= n_Errors+1
				ENDIF
			ELSE
				c_TiffOut = ADDBS(c_DirNew) +"p0000001.TIF"   && + Lffilenm("00000001.tif", "SCAN")
				nresult=lfTiffmaker(cfile,c_TiffOut,"12bc")
				n_Errors= IIF(nresult<1,n_Errors+1,n_Errors)
			ENDIF

		ELSE
			n_Errors= IIF(nresult<1,n_Errors+1,n_Errors)
		ENDIF
		RELEASE arAtty
		WAIT CLEAR
	ENDIF

	IF n_Errors > 0
		lpmessage("ERROR: Production cover page. Contact IT department.")
*--12/13/21: no longer used [258496]
*!*			n_File1 = FCREATE("C:\TEMP\ERRTIFF.TXT")
*!*			IF n_File1 > 0
*!*				= FPUT(n_File1, TIME())
*!*				= FPUT(n_File1, STR(pn_lrsno) + "*" + ALLTRIM(STR(pn_tag)))
*!*				= FPUT(n_File1, UPPER(ALLTRIM(c_TiffOut)))
*!*				= FPUT(n_File1, UPPER(ALLTRIM(c_Line)))
*!*				= FPUT(n_File1, "Start time: " + ALLTRIM(STR(h_Time)))
*!*				= FPUT(n_File1, "End time: " + ALLTRIM(STR(n_Time)))
*!*				= FPUT(n_File1, "n_file: " + ALLTRIM(STR(n_File)))
*!*				= FCLOSE(n_File1)
*!*			ENDIF
	ENDIF

ENDIF

IF n_Errors = 0
*o_flrel=CREATEOBJECT('medgeneric')
	o_flrel=CREATEOBJECT('cntdataconn')
	c_sql="UPDATE tblrequest SET distribute=1 "+;
		"WHERE cl_code='&pc_clcode.' AND tag="+STR(pn_tag)+" AND active=1 AND deleted IS null"
	o_flrel.sqlpassthrough(c_sql)

	RELEASE o_flrel		&& 07/22/2009 MD
	o_flrel = .NULL.
	pl_Distrib = .T.
ELSE
	lpmessage("ERROR: All first-look files not copied. Contact IT Department.")
ENDIF

SELECT (n_Curarea)
RELEASE c_DirEx, c_DirNew, n_Curarea, c_CurOrd, c_String, n_Cnt, a_tmp, ;
	n_File, h_Time, n_Errors, c_TiffOut, d_Date, n_Copy, c_DirDay, n_Errors, ;
	l_Genfile, l_defaults, l_floldrl,arAtty
RETURN

**************************************************************
* FUNCTION: LFMOVE
* Abstract: Move passed file to passed location. Return result
**************************************************************
FUNCTION Lfmove
PARAMETER c_file, c_Dest1, c_Base1
PRIVATE n_File, c_Copy, c_Delete
IF FILE(c_file)
	c_Copy   = "Copy file " + c_file + " to " + c_Dest1 + c_Base1
	c_Delete = "Delete file " + c_file
	&c_Copy
	&c_Delete
	RETURN .T.
ELSE
	RETURN .F.
ENDIF

**************************************************************
* FUNCTION: LFMODGEN
* Abstract: Modify the file path in the gen file that is moved
*  to the production directory
**************************************************************
FUNCTION lfModGen
PARAMETER c_file, c_NewDir, c_DestPth, c_Fname, c_Action
PRIVATE n_GenFile, n_TempFile, c_TempFile, c_String, c_NewStrg, ;
	n_Pos1, n_Pos3, c_TempDir
n_GenFile = FOPEN(c_file)
c_NewDir = LOWER(c_NewDir)
IF n_GenFile > 0
	c_TempDir = ADDBS(MLPriPro("R", "RTS.INI", "Data","JTEMP", "\")) + pc_userid + "\"
	c_TempFile = SYS(3) + ".TMP"
	n_TempFile = FCREATE(c_TempDir + c_TempFile)
*-- step through gen file, reading/modifying and putting lined
*-- into temp gen file
	IF n_TempFile > 0
		DO WHILE NOT FEOF(n_GenFile)
			c_String = FGET(n_GenFile)
			n_Pos1 = RAT("\", c_String) - 1
			n_Pos3 = RAT("\", c_String, 3)
			c_NewStrg = LEFT(c_String, n_Pos3) + ;
				"redact\" + c_NewDir + ;
				RIGHT( c_String, LEN(c_String) - n_Pos1)
			= FPUT(n_TempFile, c_NewStrg)
		ENDDO
		= FCLOSE(n_GenFile)
*--9/12/03 kdl start: check that new gen file is complete
*--move pointer to beginning of the temp gen file
		=FSEEK(n_TempFile, 0, 0)
		n_Tifcnt = 0
		DO WHILE NOT FEOF(n_TempFile)
			c_String = ALLTRIM(FGET(n_TempFile))
			IF UPPER(RIGHT(c_String, 3)) == "TIF"
				n_Tifcnt = n_Tifcnt + 1
			ENDIF
		ENDDO
		= FCLOSE(n_TempFile)
*--compare number of tif files in temp gen file to number of files
*--in the name translation array.
		IF n_Tifcnt <> ALEN(a_Files, 1)
			lpmessage("Error: Bad temporary GEN file. Contact IT department.")
			ERASE (c_TempDir + c_TempFile)
			RETURN .F.
		ENDIF
*--9/12/03 kdl end:
*-- now move the modified copy of the gen file to the production
*-- directory
		COPY FILE (c_TempDir + c_TempFile) TO ;
			(c_DestPth + c_Fname)
		IF c_Action == "MOVE"
			ERASE (c_file)
		ENDIF
		ERASE (c_TempDir + c_TempFile)
	ELSE
		= FCLOSE(n_GenFile)
		lpmessage("Error: No temporary GEN file. Contact IT department.")
		RETURN .F.
	ENDIF
ELSE
	lpmessage("Error: GEN file not found. Contact IT department.")
	RETURN .F.
ENDIF
RETURN .T.

**************************************************************************************
* PROCEDURE: FLSTATPG
* Abstract: Set the release package status page text and print it. Prepare the Gen file
* Called by: Flstatpg.spr
* Calls: gfmsg.prg
**************************************************************************************
PROCEDURE Flstatpg
PARAMETER n_Select
PRIVATE c_Text
STORE "" TO c_Text, c_Text2
DO CASE
CASE n_Select = 1
	c_Text = "THIS DOCUMENT HAS NOT BEEN REDACTED"
CASE n_Select = 2
	c_Text = "THIS DOCUMENT HAS BEEN REDACTED"
CASE n_Select = 3
	c_Text = "ALL PAGES OF THIS DOCUMENT HAVE BEEN REDACTED"
CASE n_Select = 4
	c_Text = "NOT REDACTED DUE TO LACK OF ATTORNEY RESPONSE"
ENDCASE

c_Text = SPACE(5) + ALLTRIM(c_Text)
lnTxt = FCREATE("C:\TEMP\STATTEXT.TXT",0)
IF lnTxt > 0
** Insert blank lines
	FOR i = 1 TO 15
		=FPUTS(lnTxt,SPACE(75))
	ENDFOR

	=FPUTS(lnTxt, c_Text)

	FOR i = 1 TO 19
		=FPUTS(lnTxt,SPACE(75))
	ENDFOR
	=FCLOSE(lnTxt)
	lpmessage("Status Page c:\temp\stattext.txt created.")
ELSE
	lcFile = "ERROR"
	lpmessage("Could not Create status page text file...")
ENDIF

**************************************************************************************
* PROCEDURE: FLALERT
* Abstract: Print account manager alert
* Called by: procedure fldocprt in flprint.prg
* Calls: flprint.prg, gfmsg.prg, gfuse_ro.prg, gfunuse.prg, flrevsht.frx
**************************************************************************************
PROCEDURE Flalert
PRIVATE n_Curarea, l_Used, n_Fee, n_Pages
n_Curarea = SELECT()
l_Used = gfuse_RO( "admpop")

*--get the page count and witness fee summary data
STORE 0 TO n_Fee, n_Pages
DO FlFeePgs WITH n_Fee, n_Pages

IF ! PRINTSTATUS()
	=gfmsg("Printer is not ready.  Fix it and try again.")
ELSE
*--11/4/14: force electronic FL delivery for some litigations
	oGen=CREATEOBJECT('cntdataconn')
	lcSQLLine="Exec [dbo].[getchgflshiptype] '"+ALLTRIM(fixquote(pc_litcode))+"'"
	oGen.sqlpassthrough(lcSQLLine,"chkFlLit")
	SELECT chkFlLit
	IF RECCOUNT()>0
		IF NVL(chkFlLit.bChgshp,.F.) = .T.
			pc_Flship = "E"
		ENDIF
	ENDIF
	IF USED("chkFlLit")
		USE IN chkFlLit
	ENDIF

	SELECT ADMPOP
	DO PrintOn IN flprint
	REPORT FORM FLrevSht
	DO PrintOff IN flprint
ENDIF
= gfunuse( "admpop", l_Used)
SELECT (n_Curarea)

**************************************************************************************
* FUNCTION: PRTBAR2A
* Abstract: call the prntbar2 program
* Called by: flrevsht.frx
* Calls: prntbar2.prg
**************************************************************************************
FUNCTION prtBar2
PARAMETERS n_Param1, n_Param2
IF PARAMETERS() < 2
	DO PrntBar2 WITH n_Param1
ELSE
	DO PrntBar2 WITH n_Param1, n_Param2
ENDIF
RETURN ""

**************************************************************************************
* PROCEDURE: FLSTFILE
* Abstract: Build translation array of tiff names to page "numbers" from the idx file
* Called by: procedure flpost in flproc.prg
* Calls: gfmsg.prg
**************************************************************************************
PROCEDURE Flstfile
PRIVATE n_Len, n_File, c_Idxfile, n_Cnt, l_iswej1
l_iswej1 = .F.

n_Len =ADIR(a_dir, (c_DirEx + "*.idx"))

*--9/12/03 kdl start: Add check for multiple IDX files
DO CASE
CASE n_Len = 1
	c_Idxfile = c_DirEx + ALLTRIM(a_dir[1,1])
CASE n_Len = 0
*--9/10/04 kdl start: add check for new images that not include idx file
	n_Len = ADIR(a_dir, (c_DirEx + "P" + "*.tif"))
	IF n_Len = 0
		lpmessage("ERROR: IDX file not found. Contact IT department.")
		RETURN
	ELSE
		l_iswej1 = .T.
	ENDIF
CASE n_Len > 1
	lpmessage("ERROR: Multiple IDX files found. Contact IT department.")
	RETURN
ENDCASE

*--build array of scanned documents in idx file and assign translation names
*--9/10/04 kdl start: add translation for new images that not include idx file

IF NOT l_iswej1
	n_File = FOPEN(c_Idxfile)
	IF n_File >= 0
		n_Cnt = 1
		DO WHILE NOT FEOF(n_File)
			DIMENSION a_Files[n_Cnt,2]
			c_String = FGETS(n_File,250)
			c_String = FGETS(n_File,250)
			c_String = FGETS(n_File)
*--this is the tiff file name (positions 166-177 on the idx record)
			c_file = SUBSTR(c_String, 166, 12)
			a_Files[n_Cnt, 1] = c_file                && file id
			a_Files[n_Cnt, 2] = PADL(ALLTRIM(STR(n_Cnt - 1)),8,"0")+".TIF" && bates number, page id, always start at 0
			n_Cnt = n_Cnt + 1
		ENDDO
		=FCLOSE(n_File)
	ELSE
		= gfmsg("ERROR: IDX file not found. Contact IT department.")
		RETURN
	ENDIF
ELSE
	FOR n_Cnt = 1 TO n_Len
		DIMENSION a_Files[n_Cnt,2]
		c_file = ALLTRIM(a_dir[ n_cnt, 1])
		a_Files[n_Cnt, 1] = c_file                && file id
		a_Files[n_Cnt, 2] = PADL(ALLTRIM(STR(n_Cnt - 1)),8,"0")+".TIF" && bates number, page id, always start at 0
	ENDFOR
ENDIF

**************************************************************************************
* PROCEDURE: LFFILENM
* Abstract: Convert file names
* Called by: procedures flreleas, Pagesub in flproc.prg
* Calls: gfmsg.prg
**************************************************************************************
FUNCTION Lffilenm
PARAMETERS c_Filenme, c_Direct

IF PARAMETERS() < 2
	c_Direct = "BATES"
ENDIF
PRIVATE c_ConvName, n_Factor
c_ConvName = ""
n_Factor = IIF( c_Direct = "SCAN", -1, 1)
n_Elem = ASCAN(a_Files, UPPER(c_Filenme))
IF n_Elem > 0
	c_ConvName = a_Files[n_Elem + n_Factor]
ELSE
	=gfmsg("ERROR: File name conversion failed.  Contact IT department.")
ENDIF
RETURN c_ConvName

**************************************************************************************
* PROCEDURE: LFCRDIR
* Abstract: Create first look review directory
* Called by: flincome procedure
* Calls: gfuse_ro.prg, gfunuse.prg
**************************************************************************************
PROCEDURE Lfcrdir
PARAMETERS c_Text
PRIVATE n_Curarea, l_Used, c_DirBase, c_DirNew, lc_litcode, c_offcode, ;
	c_case, n_caseid, n_tagid, n_Test
STORE "" TO c_DirBase, c_DirNew, c_litcode, c_offcode
c_case = SUBSTR(c_Text, 120, 8)
n_caseid = VAL(ALLTRIM(STRTRAN(c_case,"_","")))
n_tagid =  VAL(SUBSTR(c_Text, 129, 3))

SELECT tamaster
IF SEEK(n_caseid)
	c_litcode = tamaster.Litigation
	c_offcode = tamaster.lrs_nocode
ENDIF
SELECT fllit
IF SEEK(c_litcode + c_offcode)
	c_DirBase = ALLTRIM(fllit.rev_dir)           && base directory for all rts 1st look
ELSE
	c_DirBase = "T:\KOPFLOOK\"
ENDIF
c_DirBase =  ADDBS(c_DirBase)                   && base image directory

*--Cases directory
c_DirNew = c_DirBase + TRANS(n_caseid,"@L 99999999")
n_Test = ADIR( a_tmp, (c_DirNew), "D")
IF n_Test = 0
	MKDIR &c_DirNew
ENDIF

*-- this is the tag's directory
c_DirNew = c_DirBase + TRANS(n_caseid,"@L 99999999")+"\"+ ;
	TRANS(n_tagid,"@L 99999999")
n_Test = ADIR( a_tmp, c_DirNew, "D")
IF n_Test = 0
	MKDIR &c_DirNew
ENDIF

RETURN (c_DirNew + "\")

**************************************************************************************
* PROCEDURE: FLEDIT
* Abstract: used to display first-look transaction for edit/deletion during review
*           phase
* Called by: flproc1.scx transaction edit option
* Calls: depstat.prg
**************************************************************************************
PROCEDURE fledit
PARAMETERS o_frmdepsum

LOCAL n_Curarea, c_Alias, c_Ftable, c_Order, ;
	l_IsFltrans, l_IsPrltrans, l_Usedist, c_sql
STORE .F. TO l_IsFltrans, l_IsPrltrans, l_Usedist
STORE "" TO c_Alias, c_Ftable, c_Order, c_Winfl
n_Curarea = SELECT()

*--save active windows to files
oview=CREATEOBJECT("transactions.frmviewtransmemo","D",.T., pn_tag)
oview.SHOW(1)
RELEASE oview		&& 07/22/2009 MD

*--If the "1" transaction is gone, check if the tag status needs to be
*-- changed, but first confirm then clear out all orphan transactions
*-- and comments.
*omedfl=CREATEOBJECT('medgeneric')
omedfl=CREATEOBJECT('cntdataconn')
c_sql="SELECT * FROM tblflentry WITH (nolock) WHERE cl_code='"+pc_clcode+"' AND tag="+;
	STR(pn_tag)+" AND active=1 AND deleted IS null"

omedfl.sqlpassthrough(c_sql,"flentry")
SELECT flentry
INDEX ON txn_code TAG txn_code

IF pl_DelFunc AND NOT SEEK(1,'flentry')
*--check if there are any existing first-look transactions in the entry tables
**10/01/18 SL #109598
*c_sql= "SELECT * FROM tbltimesheet WITH (nolock,INDEX (ix_tbltimesheet)) WHERE cl_code='"+
	c_sql= "SELECT * FROM tbltimesheet WITH (nolock) WHERE cl_code='"+;
		pc_clcode+"' AND tag="+STR(pn_tag)+" AND active=1 AND deleted IS NULL"
	omedfl.sqlpassthrough(c_sql,"entry")

*--7/13/17: trap for missing "entry" cursor [65716]
	l_IsPrtrans = .F.
	IF USED("entry")
		SELECT entry
		INDEX ON txn_code TAG txn_code
		l_IsPrtrans = SEEK(88,'Entry')
		IF NOT l_IsPrtrans
			l_IsPrtrans = SEEK(53,'Entry')
		ENDIF
	ENDIF

*!*			INDEX ON txn_code TAG txn_code
*!*		l_IsPrtrans = SEEK(88,'Entry')
*!*		IF NOT l_IsPrtrans
*!*			l_IsPrtrans = SEEK(53,'Entry')
*!*		ENDIF

	l_IsFltrans = (RECCOUNT("flentry")>0)
*--no need to prompt if there are no other transactions
	IF (l_IsPrtrans OR l_IsFltrans)
		o_message = CREATEOBJECT('rts_message_yes_no',"Delete all first-look log-in transactions for tag?")
		o_message.SHOW
		l_Change=IIF(o_message.exit_mode="YES",.T.,.F.)			&&THISFORM.return_value1=1
		o_message.RELEASE
		IF l_Change
*--clear alltransaction from the flentry table
			IF l_IsFltrans
				c_sql="UPDATE tblflentry SET active=0,deleted='"+DTOC(d_today)+"'"+;
					" WHERE cl_code='"+pc_clcode+"' AND tag="+STR(pn_tag)+" AND active=1 AND deleted IS NULL"
				omedfl.sqlpassthrough(c_sql)
			ENDIF                                  && there are first-look entries
*--clear entries from the fl comment file
			c_sql="UPDATE tblflcomm SET active=0,deleted='"+DTOC(d_today)+"'"+;
				" WHERE cl_code='"+pc_clcode+"' AND tag="+STR(pn_tag)+" AND active=1 AND deleted IS NULL"
			omedfl.sqlpassthrough(c_sql)

*--clear entries from the production entry file
			IF l_IsPrtrans
				c_sql="UPDATE tbltimesheet SET active=0,deleted='"+DTOC(d_today)+"'"+;
					" WHERE cl_code='"+pc_clcode+"' AND tag="+STR(pn_tag)+ " AND txn_code=53 "+;
					" AND active=1 AND deleted IS NULL"
				omedfl.sqlpassthrough(c_sql)

				IF SEEK(88,'Entry')
					o_message = CREATEOBJECT('rts_message_yes_no',"Delete all first-look 88 tranasctions for this tag?")
					o_message.SHOW
					l_Change=IIF(o_message.exit_mode="YES",.T.,.F.)			&&THISFORM.return_value1=1
					o_message.RELEASE
					IF l_Change
						c_sql="UPDATE tbltimesheet SET active=0,deleted='"+DTOC(d_today)+"'"+;
							" WHERE cl_code='"+pc_clcode+"' AND tag="+STR(pn_tag)+ " AND txn_code=88 "+;
							" AND active=1 AND deleted IS NULL"
						omedfl.sqlpassthrough(c_sql)
*--now clear the associated dist system to dos
						IF pc_Flship = "E"
							c_sql="UPDATE tbldisttodo SET rem_by='&pc_userid.'"+;
								",rem_date='"+DTOC(d_today)+"'"+;
								",rem_time='"+TIME()+"'"+;
								" WHERE lrs_no='"+ALLTRIM(pc_lrsno)+"' AND tag="+STR(pn_tag)+;
								" AND active=1 AND deleted IS NULL"
							omedfl.sqlpassthrough(c_sql)
						ENDIF                            && electornic
					ENDIF							&&delete 88's
				ENDIF                               && 88 transaction
			ENDIF                                  && there are production entries
		ENDIF                                     && If confirmation received
	ENDIF                                        && if there are transactions other than "1"
	c_sql="UPDATE tblrequest SET status='W',fin_date=NULL,pages=0,"+;
		"hstatus='',hnrs=0,hnrs_code='',hinc=0,hqual='' "+;
		" WHERE cl_code='"+pc_clcode+"' AND tag="+STR(pn_tag)+ ;
		" AND active=1 AND deleted IS NULL"
	omedfl.sqlpassthrough(c_sql)
	pc_Status = "W"
*--need to update the deponent summary screen
	o_frmdepsum.FRMdepsummary_request.STATUS="W"
	o_frmdepsum.FRMdepsummary_request.statusname="WAIT"
	o_frmdepsum.FRMdepsummary_request.qualif=""
	o_frmdepsum.FRMdepsummary_request.fin_date=DTOC({})
	o_frmdepsum.FRMdepsummary_request.PAGES=0
	o_frmdepsum.FRMdepsummary_requestupdate

	n_1lklvl = gflkStat("LEVEL", pl_FrstLook, 'W', pn_tag)
ENDIF                                           && if there are no "1" transactions

SELECT (n_Curarea)

RETURN

**************************************************************************************
* PROCEDURE: FLGETPR
* Abstract:  adds FL pre-review transactions to the first-look transaction brows
*     list
* Called by: Depstat.prg- makebrow,
* Calls:
**************************************************************************************
PROCEDURE Flgetpr
PRIVATE n_Curarea
n_Curarea = SELECT()
SELECT (pc_Entryn)
SET ORDER TO Cl_Txn
*--incomplete transactions
IF SEEK( pc_clcode + "*" + STR(53) + "*" + STR(pn_tag))
	SCAN WHILE cl_code =pc_clcode AND TAG = pn_tag AND ;
			txn_code = 53
		wstr = SPACE(90)
		DO setarr IN depstat WITH wstr
		DO addmtran IN depstat WITH wstr, RECNO(), 0, TAG, ;
			txn_date, txn_id, txn_code
		SELECT (pc_Entryn)
	ENDSCAN
ENDIF
*--88 transactions
IF SEEK( pc_clcode + "*" + STR(88) + "*" + STR(pn_tag))
	SCAN WHILE cl_code =pc_clcode AND TAG = pn_tag AND ;
			txn_code = 88
		wstr = SPACE(90)
		DO setarr IN depstat WITH wstr
		DO addmtran IN depstat WITH wstr, RECNO(), 0, TAG, ;
			txn_date, txn_id, txn_code
		SELECT (pc_Entryn)
	ENDSCAN
ENDIF

SELECT (n_Curarea)
RETURN

**************************************************************************************
* PROCEDURE: FLFEEPGS
* Abstract:  Compute pages count and fee total for current tag
* Called by: flproc.fledit
* Calls:
**************************************************************************************
PROCEDURE FlFeePgs
PARAMETER n_Fee, n_Pages
PRIVATE c_Order, n_Curarea, l_UseFlent
n_Curarea = SELECT()
n_Fee = 0.0
n_Pages = 0
l_UseFlent = gfuse("flentry")

SELECT flentry                                  && Entry file
c_Order = ORDER()
SET ORDER TO
CALCULATE SUM(flentry.COUNT) TO n_Pages FOR ;
	flentry.cl_code + "*" + STR(flentry.TAG) = pc_Depokey ;
	AND flentry.txn_code = 1
IF ! EMPTY(c_Order)
	SET ORDER TO (c_Order) IN flentry
ENDIF
= gfunuse("flentry", l_UseFlent)

SELECT (pc_Entryn)
c_Order = ORDER()
CALCULATE SUM(wit_fee) TO n_Fee FOR ;
	cl_code + "*" + STR(TAG) = pc_Depokey ;
	AND txn_code = 7
IF ! EMPTY(c_Order)
	SET ORDER TO (c_Order) IN (pc_Entryn)
ENDIF

SELECT (n_Curarea)

RETURN

**************************************************************************************
* Procedure: LFUPTIFF
*
* Abstract: Updates user's copy of txttiff.exe, if necessary
* Called by: local procedures flpost, flreleas
**************************************************************************************
PROCEDURE lfUpTiff
PRIVATE n_TxtTiff, d_TxtTiff
*--first check for the txttiff.exe
*!*	n_TxtTiff = ADIR(a_txtTiff, "T:\TXTTIFF\TXTTIFF.EXE")
*!*	IF n_TxtTiff > 0 AND FILE("c:\TxtTiff\TxtTiff.exe")
*!*		d_TxtTiff = a_txtTiff[1, 3]
*!*		n_TxtTiff = ADIR(a_txtTiff, "C:\TXTTIFF\TXTTIFF.EXE")
*!*		IF n_TxtTiff > 0
*!*			IF d_TxtTiff > a_txtTiff[1, 3]
*!*				COPY FILE T:\TxtTIFF\TxtTIFF.EXE TO c:\TxtTIFF\TxtTIFF.EXE
*!*			ENDIF
*!*		ENDIF
*!*	ENDIF

*--11/9/04 kdl start:
*--now check for the sqlflrel.exe
*!*	n_TxtTiff = ADIR(a_txtTiff, "T:\TXTTIFF\SQLFLREL.EXE")
*!*	IF n_TxtTiff > 0 AND FILE("c:\TxtTiff\SQLFlrel.exe")
*!*		d_TxtTiff = a_txtTiff[1, 3]
*!*		n_TxtTiff = ADIR(a_txtTiff, "C:\TXTTIFF\SQLFLREL.EXE")
*!*		IF n_TxtTiff > 0
*!*			IF d_TxtTiff > a_txtTiff[1, 3]
*!*				COPY FILE T:\TxtTIFF\SQLflrel.EXE TO c:\TxtTIFF\SQLflrel.EXE
*!*			ENDIF
*!*		ENDIF
*!*	ENDIF

**************************************************************************************
* Procedure: LFUPTSET
*
* Abstract: Updates user's copy of tiffprop.exe, if necessary
* Called by: local procedures repltiff
**************************************************************************************
PROCEDURE lfupTset
*!*	PRIVATE n_TxtTiff, d_TxtTiff
*!*	n_TxtTiff = ADIR(a_txtTiff, "T:\TXTTIFF\TIFPROP.EXE")
*!*	IF n_TxtTiff > 0 AND FILE("c:\TxtTiff\TIFPROP.EXE")
*!*		d_TxtTiff = a_txtTiff[1, 3]
*!*		n_TxtTiff = ADIR(a_txtTiff, "C:\TXTTIFF\TIFPROP.EXE")
*!*		IF n_TxtTiff > 0
*!*			IF d_TxtTiff > a_txtTiff[1, 3]
*!*				COPY FILE T:\TxtTIFF\Tifprop.EXE TO c:\TxtTIFF\Tifprop.EXE
*!*			ENDIF
*!*		ENDIF
*!*	ENDIF

**************************************************************************************
* Procedure: chkOrder
*
* Abstract: Gets the order data for an attorney/tag
* Called by: nrs procedure in incoming.prg
**************************************************************************************
PROCEDURE chkOrder
PARAMETER c_Atty, d_Order, d_Decline, d_Cancel
LOCAL c_sql
*omed=CREATEOBJECT('medgeneric')
omed=CREATEOBJECT('cntdataconn')
**10/01/18 SL #109598
*c_sql="SELECT * FROM tblorder WITH (nolock,INDEX (ix_tblorder_1)) WHERE cl_code='&pc_clcode.' AND tag="+
c_sql="SELECT * FROM tblorder WITH (nolock) WHERE cl_code='&pc_clcode.' AND tag="+;
	ALLTRIM(STR(pn_tag))+" AND at_code="+omed.cleanstring(c_Atty)+" AND active=1 and deleted IS null"
omed.sqlpassthrough(c_sql,'order')
IF RECCOUNT('order') > 0
	d_Order = ORDER.date_order
	d_Decline = ORDER.date_decln
	d_Cancel = ORDER.date_cancl
ENDIF

***********************************************************************************
*12/06/2005 MD
**********************************************************************************
* Procedure: LpShtype
*
* Abstract: Update the all of the first-look review attorney's orders or a single
*		 tag's ship types based on the attorney's rolodex shipment methods
**********************************************************************************
PROCEDURE lpshtype
PARAMETERS l_TagChg, n_tag

IF PCOUNT() < 1
	l_TagChg = .F.
ENDIF
IF PCOUNT() < 2
	n_tag = 0
ENDIF

PRIVATE lnCurArea, c_list,  c_shipstr

CLEAR TYPEAHEAD
lnCurArea = SELECT()

IF l_TagChg AND NOT bringMessage("Update ship methods of first-look review attorney's order?")
*--			"Update ship methods of first-look review attorney's orders?"))
	RETURN
ENDIF


c_list = IIF( pc_Flship = "E", "DS", IIF(pc_Flship = "C", "CD", "P"))

&&-get ship type from attorney level ship table

c_shipstr = getshipstring(pc_Flatty, pc_clcode)

*--Prompt user to pick DS type(s)
IF c_shipstr <> "P" OR c_list <> "P"

*--set currrent ship types in the shiptype popup
	c_shipstr=lpshppop(c_shipstr, pc_Flatty, n_tag, pc_clcode)
	IF TYPE("c_shipstr")="L"
		IF c_shipstr=.F.
			RETURN
		ENDIF
	ENDIF
*--set the case level ship methods to user-selected settings.
	IF NOT l_TagChg
		updateship(pc_clcode, pc_Flatty)
		updateorder(c_shipstr, pc_clcode, pc_Flatty, n_tag)

	ENDIF
ENDIF
RETURN
***********************************************************************************
PROCEDURE bringMessage
PARAMETERS lsMessage

LOCAL llResponse

o_message = CREATEOBJECT('rts_message_yes_no',lsMessage)
o_message.SHOW
llResponse=IIF(o_message.exit_mode="YES",.T.,.F.)
o_message.RELEASE

RETURN llResponse
***********************************************************************************
PROCEDURE getshipstring
PARAMETERS lcAtcode, lcClCode
LOCAL lcSQLLine, lcshipstr, lnCurArea

lnCurArea=SELECT()
lcshipstr=""
*objgen=CREATEOBJECT("medgeneric")
objgen=CREATEOBJECT('cntdataconn')
lcSQLLine="select * from tblAttyShip WITH (nolock) where at_code='"+lcAtcode+"' and active=1"
objgen.sqlpassthrough(lcSQLLine,"AttyShip")

SELECT attyShip
IF RECCOUNT()=0
	lcshipstr = "P"
ELSE
	IF attyShip.rpapernum > 0
		lcshipstr = "P"
	ENDIF
	IF attyShip.rdsnum > 0
		lcshipstr = IIF( EMPTY(lcshipstr), "D", lcshipstr + ",D")
	ENDIF
	IF attyShip.rvsnum > 0
		lcshipstr = IIF( EMPTY(lcshipstr), "V", lcshipstr + ",V")
	ENDIF
	IF attyShip.rcdnum > 0
		lcshipstr = IIF( EMPTY(lcshipstr), "C", lcshipstr + ",C")
	ENDIF
	IF attyShip.rshipftp
		lcshipstr = IIF( EMPTY(lcshipstr), "F", lcshipstr + ",F")
	ENDIF
ENDIF

SELECT attyShip
USE
RELEASE objgen
SELECT(lnCurArea)
RETURN lcshipstr
*********************************************************************************
PROCEDURE lpshppop
LPARAMETERS lcshipstr, lcAtcode, lnTag, lcClCode, llCaseLevel
LOCAL l_eship, l_billok, lnCurArea
lnCurArea=SELECT()
shpTypes=CREATEOBJECT("frmEnterShippingMethods")

l_eship=.F.
l_eship=getship(lcClCode, lcAtcode)

*--deactivate shipment type options where appropriate
IF NOT llCaseLevel AND NOT pl_CAVer
	l_billok = billok(lcClCode, lnTag, lcAtcode)
ELSE
	l_billok = .T.
ENDIF

FOR n_Cnt = 1 TO ALEN(shpTypes.a_types,1)
	shpTypes.a_types[n_cnt, 1]=IIF( LEFT(shpTypes.a_types[n_cnt, 3], 1) $ lcshipstr, "T", " " )
ENDFOR

FOR n_Cnt = 1 TO ALEN(shpTypes.a_types,1)
	shpTypes.a_types[n_cnt, 1] = IIF( (NOT l_billok) OR (n_Cnt > 1 AND ( pl_ofcPas OR NOT l_eship)), "\", "") + ;
		shpTypes.a_types[n_cnt, 1]
ENDFOR

shpTypes.SHOW

*--reset shipping types based on the popup's bar's marks
IF shpTypes.exit_mode="OK"
	lcshipstr=""
	FOR n_Cnt = 1 TO ALEN(shpTypes.a_types,1)
		IF "T" $ shpTypes.a_types[n_cnt, 1]
			lcshipstr = IIF( EMPTY(c_list), LEFT(shpTypes.a_types[ n_Cnt, 3], 1), ;
				lcshipstr + "," + LEFT(shpTypes.a_types[ n_Cnt, 3], 1))
		ENDIF
	ENDFOR
ELSE
	shpTypes.RELEASE
	RETURN .F.
ENDIF
shpTypes.RELEASE
SELECT (lnCurArea)
RETURN lcshipstr
***********************************************************************************
PROCEDURE billok
***********************************************************************
* ABSTRACT: check bill dates against receive transaction date
***********************************************************************
PARAMETERS c_clcode, n_tag, c_atcode

LOCAL d_transdte , l_Change, lnCurArea
LOCAL objgen AS OBJECT
lnCurArea = SELECT()
l_Change = .T.
objgen=CREATE('cntdataconn') &&"medgeneric")

c_sql = "SELECT txn_date FROM tbltimesheet WITH (nolock) " + ;
	" WHERE cl_code='&c_clcode.' AND tag="+STR(n_tag)+ ;
	" AND txn_code IN (1, 41) AND active=1 AND deleted IS null"+;
	" ORDER BY txn_date"
objgen.sqlpassthrough(c_sql,'timesheet')
*--MD 03/17/2009 Added ------
c_sql = "select date_bill from tblorder where cl_code='"+ALLTRIM(c_clcode)+"' and tag="+ALLTRIM(STR(n_tag))+" and at_code='"+;
	ALLTRIM(c_atcode)+"' and active=1"
objgen.sqlpassthrough(c_sql,'viewBillDate')
*---------------------------

SELECT timesheet
IF RECCOUNT() > 0
	GO TOP
	c_atcode = PADR(c_atcode, 8)
	d_transdte = NVL(TTOD(timesheet.txn_date),{})			&&a_txn[1]
	d_billDate=NVL(TTOD(viewBillDate.date_bill),{})
*--first check for paper copy shipment
*l_Change = (CTOD(ORDER.date_bill) < d_transdte)  &&MD 03/17/2009 commented
	l_Change = (d_billDate < d_transdte)
*--now check for Distribution server shipments if l_change is still .T.
	IF l_Change
		c_sql= "SELECT MAX(date_bill) AS maxdate FROM tbldistbill WITH (nolock)" +;
			"WHERE cl_code='&c_clcode.' AND tag="+STR(n_tag)+;
			" AND at_code='&c_atcode.' AND [Id]=0"+;
			" AND active=1 AND deleted IS null"
		objgen.sqlpassthrough(c_sql,'billdate')
		IF RECCOUNT("billdate")=1
			l_Change = (NVL(TTOD(billdate.maxdate),{}) < d_transdte)
		ENDIF
	ENDIF
ENDIF
USE IN viewBillDate
RELEASE objgen
SELECT (lnCurArea)
RETURN l_Change
************************************************************************************
PROCEDURE getship
PARAMETERS lcClCode, lcAtcode
LOCAL l_eship, lnCurArea
LOCAL objgen AS OBJECT
lnCurArea=SELECT()
l_eship=.F.
objgen=CREATE('cntdataconn') &&"medgeneric")

lcSQLLine="SELECT [plan] FROM tblbill WITH (nolock) WHERE cl_code='"+lcClCode+"'"+;
	" and at_code='"+lcAtcode+"' and active=1"
objgen.sqlpassthrough(lcSQLLine,'tabills')

IF RECCOUNT("tabills")=1
	c_sql="SELECT eship FROM tblplan WITH (nolock) WHERE [plan]='" + Tabills.plan + "'"+;
		" and active=1"
	objgen.sqlpassthrough(c_sql,'plan')
	IF RECCOUNT("plan")=1
		l_eship = plan.eship
	ENDIF
	SELECT plan
	USE
ENDIF

SELECT Tabills
USE
RELEASE objgen
SELECT(lnCurArea)
RETURN (l_eship)
*************************************************************************************
PROCEDURE updateship
PARAMETERS lcClCode, lcAtcode
LOCAL lcSQLLine,lnCurArea
LOCAL objgen AS OBJECT
lnCurArea=SELECT()
objgen=CREATE('cntdataconn') &&"medgeneric")

lcSQLLine="select * from tblShip WITH (nolock) "+;
	"where cl_code='"+lcClCode+"' and at_code='"+lcAtcode+"'"+;
	" and active=1"
objgen.sqlpassthrough(lcSQLLine,"gtaship")

SELECT gtaship
IF RECCOUNT()>0
	lcSQLLine="update tblShip set "+;
		" rpapernum='"+	IIF( "P" $ c_shipstr, "1", "0")+"',"+;
		" rcdnum='"+IIF( "C" $ c_shipstr, "1", "0")+"',"+;
		" rvsnum='"+IIF( "V" $ c_shipstr, "1", "0")+"',"+;
		" rshipftp='"+IIF( "F" $ c_shipstr, "1", "0")+"',"+;
		" rdsnum='"+IIF( "D" $ c_shipstr, "1", "0")+"',"+;
		" edited='"+TTOC(DATETIME())+"',"+;
		" editedby='"+ goApp.CurrentUser.ntlogin+"'"+;
		" where cl_code='"+lcClCode+"' and at_code='"+lcAtcode+"'"
	objgen.sqlpassthrough(lcSQLLine)
ELSE
	lcSQLLine="SELECT id_tblBills FROM tblbill WITH (nolock) WHERE cl_code='"+lcClCode+"'"+;
		" and at_code='"+lcAtcode+"' and active=1"
	objgen.sqlpassthrough(lcSQLLine,'tabills')

	lcSQLLine="Insert into tblShip (cl_code, at_code,rpapernum,"+;
		"rcdnum, rvsnum, rdsnum, rshipftp, rcdtype,rdstype, rftptype, mcdtype,"+;
		"mdstype, mftptype, id_tblbills, created, createdby, active, retire) values ("+;
		"'"+lcClCode+"',"+;
		"'"+lcAtcode+"',"+;
		"'"+IIF( "P" $ c_shipstr, "1", "0")+"',"+;
		"'"+IIF( "C" $ c_shipstr, "1", "0")+"',"+;
		"'"+IIF( "V" $ c_shipstr, "1", "0")+"',"+;
		"'"+IIF( "D" $ c_shipstr, "1", "0")+"',"+;
		"'"+IIF( "F" $ c_shipstr, "1", "0")+"',"+;
		"'"+"T"+"',"+;
		"'"+"T"+"',"+;
		"'"+"T"+"',"+;
		"'"+"T"+"',"+;
		"'"+"T"+"',"+;
		"'"+"T"+"',"+;
		"'"+Tabills.id_tblBills+"',"+;
		"'"+TTOC(DATETIME())+"',"+;
		"'"+goApp.CurrentUser.ntlogin+"',"+;
		"'1','0')"
	objgen.sqlpassthrough(lcSQLLine)
	SELECT Tabills
	USE
ENDIF

SELECT gtaship
USE
RELEASE objgen
SELECT (lnCurArea)
************************************************************************************
PROCEDURE updateorder
*--update ship methods of the orders for the the first-look attorney
PARAMETERS lcShipString, lcClCode, lcAtcode, lnTag
LOCAL n_Cnt, n_alen, lnCurArea
LOCAL objgen AS OBJECT
lnCurArea=SELECT()

objgen=CREATE('cntdataconn') &&"medgeneric")

DIMENSION a_types[5,3]
a_types[1, 1] = "P"
a_types[2, 1] = "DS"
a_types[3, 1] = "VS"
a_types[4, 1] = "CD"
a_types[5, 1] = "FT"
n_alen = ALEN(a_types, 1)


*--9/28/16: define order type if not already defined.
IF TYPE("c_Ordtypes") == "U"
	c_Ordtypes = ""
ENDIF

FOR n_Cnt = 1 TO n_alen
	a_types[n_cnt, 2] = ;
		IIF( LEFT(a_types[n_cnt, 1], 1) $ lcShipString, .T., .F.)
ENDFOR

IF NOT l_TagChg
	lcSQLLine="Select * from tblOrder o WITH (nolock) inner join tblRequest r WITH (nolock) on "+;
		"o.cl_code=r.cl_code and o.tag=r.tag "+;
		"where o.cl_code='"+lcClCode+"' and o.at_code='"+lcAtcode+"'"+;
		" and o.active=1"
	WAIT WINDOW "Updating orders' ship methods" NOWAIT NOCLEAR
ELSE
	lcSQLLine="Select * from tblOrder o WITH (nolock) inner join tblRequest r WITH (nolock) on "+;
		"o.cl_code=r.cl_code and o.tag=r.tag "+;
		"where o.cl_code='"+lcClCode+"' and o.tag='"+ALLTRIM(STR(lnTag))+"' and o.at_code='"+lcAtcode+"'"+;
		" and o.active=1"
	WAIT WINDOW "Updating order ship methods" NOWAIT NOCLEAR
ENDIF

objgen.sqlpassthrough(lcSQLLine,"vorder")
SELECT vorder
IF RECCOUNT()>0
	SELECT vorder
	SCAN
		IF INLIST(vorder.STATUS, "W", "T", "F")

*--no update if order date or shipment data is null
			IF ISNULL(vorder.date_order) OR ISNULL(vorder.shiptype) OR ISNULL(c_Ordtypes)
				LOOP
			ENDIF

*--original ship medthod(s)

			c_Ordtypes = IIF( vorder.numcopy > 0 AND ;
				INLIST( vorder.shiptype, " ", "P"), "P", vorder.shiptype)
			lcCurArea2=SELECT()
			lcSQLLine="Exec dbo.call_dsordertype '"+vorder.cl_code+"', "+ALLTRIM(STR(vorder.TAG))+","+ ;
				"'"+vorder.at_code+"', '"+TTOC(vorder.date_order)+"', '"+vorder.shiptype+"', 0, "+;
				"'"+vorder.id_tblOrders+"', '"+goApp.CurrentUser.ntlogin+"', '&c_Ordtypes.',2"
			objgen.sqlpassthrough(lcSQLLine,"shiptypes")
			c_Ordtypes=shiptypes.ordtypes
			SELECT shiptypes
			USE
			SELECT (lcCurArea2)
			FOR n_Cnt = 1 TO n_alen
				a_types[n_cnt, 3] = ;
					IIF( LEFT(a_types[n_cnt, 1], 1) $ c_Ordtypes, .T., .F.)
			ENDFOR
*--Now update order ship types in ordtype
			FOR n_count = 1 TO n_alen
*--check if there is a change between the original and current line items settings
				IF a_types[ n_Count, 2] <> a_types[ n_Count, 3]
					IF a_types[ n_Count, 1] = "P"  		&& paper type is stored in orders table
						lcSQLLine="Update tblOrder set numCopy='"+ALLTRIM(STR(IIF(a_types[n_Count, 2], 1, 0)))+"', "+;
							"shiptype='"+IIF(a_types[ n_Count, 2], "P", "")+"', "+;
							"edited='"+TTOC(DATETIME())+"', editedby='"+goApp.CurrentUser.ntlogin+"' "+;
							"where id_tblOrders='"+vorder.id_tblOrders+"'"
						objgen.sqlpassthrough(lcSQLLine)
					ELSE
*--column 2 is the condition to be saved, so action is based it's value (remember we
*--are only looking at rows different than original line items values)
						IF a_types[ n_Count, 2]
*--Add a ship method option
							lcSQLLine="exec DsInsertItemType '&lcClCode', '"+;
								ALLTRIM(STR(vorder.TAG))+"', '"+vorder.at_code+"', '"+;
								a_types[ n_Count, 1]+"', 1, 'T', 0, '', '"+TTOC(vorder.date_order)+"', '"+;
								goApp.CurrentUser.ntlogin+"'"
							objgen.sqlpassthrough(lcSQLLine)
						ELSE
*--remove a ship level option
							lcSQLLine="EXEC dbo.DsDeleteitemtype '&lcClCode.',"+ALLTRIM(STR(vorder.TAG))+;
								",'"+ vorder.at_code+"','"+a_types[ n_Count, 1]+;
								"',0,'',0,'','','"+goApp.CurrentUser.ntlogin+"'"
							objgen.sqlpassthrough(lcSQLLine)
						ENDIF
					ENDIF
				ENDIF
			ENDFOR
		ENDIF		&& IF INLIST(record.status, "W", "T", "F")
		SELECT vorder
	ENDSCAN
ENDIF

WAIT CLEAR
SELECT vorder
USE
RELEASE objgen
SELECT (lnCurArea)

*************************************************************************
PROCEDURE lpmessage
LPARAMETERS c_message
o_message = CREATEOBJECT('rts_message',c_message)
o_message.SHOW
RELEASE o_message

**************************************************************************
PROCEDURE OakFlook
PARAMETERS lnLrsno,lnTag
PRIVATE lo,c_sql,objreq,n_Cnt
IF TYPE('l_Print1st')='U'
	l_Print1st=.F.
ENDIF

objreq=CREATE('cntdataconn') &&"medrequest")

IF NOT USED('master')
	c_sql="dbo.getmasterbyrt " +ALLTRIM(STR(lnLrsno))
	objreq.sqlpassthrough(c_sql,'master')
ENDIF
IF NOT USED('request')
	c_sql="dbo.getrequestbylrsno " +ALLTRIM(STR(lnLrsno))+","+ALLTRIM(STR(lnTag))
	objreq.sqlpassthrough(c_sql,'request')
ENDIF

IF NVL(pl_softimg,.F.)
	pc_softdir = "t:\softimgs\" + "R_" + pc_lrsno
	n_Cnt = ADIR(a_dir, pc_softdir, "D")
	IF n_Cnt = 0
		MD &pc_softdir
	ENDIF
	pc_softdir = pc_softdir + "\" + PADL(ALLTRIM(pc_tag), 3, "0")
	n_Cnt = ADIR(a_dir, pc_softdir, "D")
	IF n_Cnt = 0
		MD &pc_softdir
	ENDIF
	pc_softdir = pc_softdir + "\"
ENDIF
IF (l_Print1st AND pc_Status = "F")
	DO lfFlAlert IN printcov 							&& internal to printcov
ENDIF
LOCAL ldSentDate, ldReturn, lnLookDays, lcSQLLine, lcAtcode,c_scandate,c_dtactive
pl_GotCase=.F.
DO gfgetcas
SET CLASSLIB TO deponentoptions ADDITIVE
lo=CREATEOBJECT("deponentoptions.frmFirstLookDates")
lo.SHOW
ldSentDate=lo.txtSentDate.VALUE
ldReturn=lo.ReturnDate
lnLookDays=lo.txtDaysLook.VALUE
RELEASE lo
lcSQLLine="select * from tblTimeSheet where cl_code='"+ALLTRIM(pc_clcode)+"' and "+;
	"tag ='"+ALLTRIM(STR(pn_tag))+"' and txn_code=88 and deleted is null and active=1"
objreq.sqlpassthrough(lcSQLLine,"view88trans")
SELECT view88trans
IF RECCOUNT("view88trans")=0
	IF !EMPTY(convrtDate(pd_closing))
		DO gfReOpen WITH .T., "Adding First Look transaction for tag "+ALLTRIM(STR(REQUEST.TAG))
	ENDIF
* add 88 transaction
*	DO Add88txn IN flprint WITH l_Has88, d_deliv, n_numdays, c_typeday

	IF TYPE("oTrans")!="O"
		oTrans=CREATEOBJECT('cntdataconn') &&CREATEOBJECT("transactions.medrequest")
	ENDIF

	c_typeday=''
	lc_timeSheetID=oTrans.addtxnrec("I",d_today, ;
		"First Look: Deliver " + DTOC(ldSentDate) + ", Due back " + DTOC(ldReturn), ;
		pc_clcode, 88, pn_tag, pc_mailid, 0, 0, lnLookDays, ;
		"","",0,0, "FIRSTLOOK2","",goApp.CurrentUser.ntlogin,REQUEST.id_tblrequests,"")

	lcSQLLine="update tblTimeSheet set [type]='"+ALLTRIM(c_typeday)+"', "+;
		"rcv_date='"+ALLTRIM(DTOC(ldSentDate))+"', due_Date='"+ALLTRIM(DTOC(ldReturn))+"', "+;
		"rq_at_code='"+ALLTRIM(fixquote(pc_Tflatty))+"' "+",rec_code='&pc_Flship.', " + ;
		"RCA_No='"+ALLTRIM(pc_BBNuRCA)+"', ASB_Round='"+ALLTRIM(pc_BBRound)+"' "+ ;
		"where id_tblTimeSheet='"+ALLTRIM(lc_timeSheetID)+"'"

	oTrans.sqlpassthrough(lcSQLLine)

*!*		objreq.addTxnRec("I",DATETIME(),;
*!*			"First Look due back "+ALLTRIM(DTOC(ldReturn)),;
*!*			ALLTRIM(pc_clcode),88, pn_tag, pc_mailid, 0, 0, lnLookDays, ;
*!*			pc_BBNuRCA, pc_BBRound, "", 0, "FIRSTLOOK2","", ALLTRIM(goApp.CurrentUser.ntlogin),;
*!*			REQUEST.id_tblrequests,"")

* update tblRequest
	lcSQLLine="update tblrequest set datedlv_88='"+DTOC(ldSentDate)+"', datedue_88='"+;
		DTOC(ldReturn)+"' where id_tblRequests='"+REQUEST.id_tblrequests+"' and active=1"
	objreq.sqlpassthrough(lcSQLLine)

	IF pc_Flship="E"
		c_ImageDb = ""
		lcSQLLine="select flimagedb from tblFlLit where code='"+ALLTRIM(fixquote(pc_litcode))+"' and office='"+ALLTRIM(fixquote(pc_offcode))+"'"
		objreq.sqlpassthrough(lcSQLLine,"viewFlLit")
		SELECT viewFlLit
		IF RECCOUNT()>0
			c_ImageDb = ALLTRIM(viewFlLit.flimagedb)   && 1st look image database
		ENDIF
		USE
		c_ImageDb = IIF( EMPTY(NVL(c_ImageDb,"")), "LOOK", c_ImageDb)
		lcSQLLine="select scan_table from tblScanLook where cl_code='"+ALLTRIM(pc_clcode)+"' and tag='"+ALLTRIM(STR(pn_tag))+"'"
		objreq.sqlpassthrough(lcSQLLine,"ScanLook")
		IF RECCOUNT()>0
			c_ImageDb = ALLTRIM(scanlook.scan_table)
		ELSE
			c_ImageDb = "WEJ1"
		ENDIF
*--make 1st look jobs priority 2
		c_dtactive=DTOC(ldSentDate)
		n_dsid=gfdsjobid()
		lcSQLLine="exec dbo.dsjob '"+ALLTRIM(STR(pn_lrsno))+"', '"+ALLTRIM(STR(pn_tag))+"', '"+;
			ALLTRIM(fixquote(pc_Tflatty))+"', 'KF', '"+"1"+"', '"+;
			ALLTRIM(c_ImageDb)+"', 1, 0, '', '', '&c_dtactive.', 0"+", '"+ALLTRIM(STR(2))+"'"+",'&n_dsid.'"
		objreq.sqlpassthrough(lcSQLLine)
	ENDIF
ENDIF

USE IN view88trans

* printbase parameters are:
* delivery date, return date, # of review days,
* type of days(B -business, C -calender, or blank, sent date, bates, print logo
SELECT MASTER
IF pc_rqatcod="BEBE  3C"
	DO Printbase IN flprint WITH gfDtskip(ldSentDate, 3), ldReturn, lnLookDays, "", ldSentDate,"000001", .T.
*	DO Printbase IN flprint WITH gfDtskip(ldSentDate, 3), ldReturn, lnLookDays, "", ldSentDate,"000002", .T.
ELSE
	DO Printbase IN flprint WITH gfDtskip(ldSentDate, 3), ldReturn, lnLookDays, "", ldSentDate,"", .T.
ENDIF

************************************************************************
FUNCTION lfTiffmaker
PARAMETERS cFilein,cFileout,cFont
LOCAL c_font,c_filein,c_fileout,cp,nr,Obj
c_filein=ALLTRIM(cFilein)
c_fileout=ALLTRIM(cFileout)

lResult = txt2tiff(c_filein,c_fileout)
nr = 1
IF NOT FILE(c_fileout)
	gfmessage("Text to Tiff Error: General error creating TIFF file.")
	nr = 0
ENDIF

RETURN (nr)

*!*	c_font=ALLTRIM(cFont)
*!*	nr=0
*!*	DECLARE INTEGER RunTiffMaker IN tiffmaker50.DLL
*!*	Obj=CREATEOBJECT("TiffMaker50vic.ClsTiffmk50")

*!*	cp = "in=&c_filein.;out=&c_fileout.;format=Tif/14" +;
*!*		";canvas=8/11/150;save=0;font=&cfont.;offset=.25/0"

*!*	nr=Obj.RunTiffMaker(cp)

*!*	*CLEAR DLLS RunTiffMaker
*!*	RELEASE Obj 	&& 07/22/2009 MD
*!*	Obj=.NULL.
*!*	RETURN (nr)

********************************************************************
FUNCTION lfOrdStatus
PARAMETER lcAtty, ldOrder, ldDecline, lnCopy, llFedEx, ldCancel, lcbillcat, ;
	lcshiptype, l_jobs

LOCAL llFound, lcAlias, c_Ordtypes, lcSQLLine, lloGen,oGen
objgen=CREATE('cntdataconn') &&"medgeneric")

lcAlias = ALIAS()
IF INLIST(TYPE("lcBillcat"), "L", "U")
	lcbillcat = ""
ENDIF
IF INLIST(TYPE("lcshiptype"), "L", "U")
	lcshiptype = ""
ENDIF

IF INLIST(TYPE("l_jobs"), "C", "U")
	l_jobs = .F.
ENDIF

IF TYPE("oGen")!="O"
	oGen=CREATEOBJECT('cntdataconn') &&CREATEOBJECT("transactions.medrequest")
	lloGen=.T.
ENDIF

**10/01/18 SL #109598
*lcSQLLine="select * from tblOrder with (nolock,INDEX(ix_tblOrder_1)) where cl_code='"+
lcSQLLine="select * from tblOrder with (nolock) where cl_code='"+;
	ALLTRIM(pc_clcode)+"' and tag='"+ALLTRIM(STR(pn_tag))+"' and at_code='"+ALLTRIM(fixquote(lcAtty))+"' and active=1"
oGen.sqlpassthrough(lcSQLLine,"viewOrder")
SELECT viewOrder
IF RECCOUNT()>0
	llFound = .T.
	ldOrder = viewOrder.date_order
	ldDecline = viewOrder.date_decln
	ldCancel = viewOrder.date_cancl
	llFedEx = viewOrder.fedex
	lcbillcat = viewOrder.billcat
	lnCopy = viewOrder.numcopy
	c_Ordtypes = IIF( viewOrder.numcopy > 0 AND ;
		INLIST(viewOrder.shiptype, " ", "P"), "P", "")

	lcSQLLine="Exec dbo.call_dsordertype '"+pc_clcode+"', "+ALLTRIM(STR(pn_tag))+","+ ;
		"'"+fixquote(lcAtty)+"', '"+""+"', '"+viewOrder.shiptype+"', '"+IIF(l_jobs=.T.,"1","0")+"', "+;
		"'"+viewOrder.id_tblOrders+"', '"+goApp.CurrentUser.ntlogin+"', '&c_Ordtypes.',2"
	oGen.sqlpassthrough(lcSQLLine,"viewShipTypes")
	SELECT viewShipTypes
	IF RECCOUNT()>0
		c_Ordtypes=viewShipTypes.ordtypes
	ENDIF
	SELECT viewShipTypes
	USE
	lcshiptype = IIF( EMPTY(c_Ordtypes), "P", c_Ordtypes)
ELSE
	llFound = .F.
ENDIF
SELECT viewOrder
USE
IF lloGen=.T.
	RELEASE oGen
ENDIF

SELECT (lcAlias)

RETURN llFound

****************************************************************
FUNCTION lffindfold
PARAMETERS cSpec
LOCAL cpath,ni,c_foundfolder,oflgen
oflgen=CREATEOBJECT('cntdataconn') && CREATEOBJECT("medgeneric")
c_sql="exec [dbo].[getimagepath] 'FLOOK','R'"
nr=oflgen.sqlpassthrough(c_sql,'curfl')
ni=1
DIMENSION flreadpath[ni,2]
flreadpath[1,1] = ''
flreadpath[1,2] = ''
IF RECCOUNT('curfl')>0
	SELECT curfl
	SCAN
		DIMENSION flreadpath[ni,2]
		flreadpath[ni,1] = ALLTRIM(curfl.sname)
		flreadpath[ni,2] = ALLTRIM(curfl.spath)
		ni=ni+1
	ENDSCAN
ENDIF
IF USED('curfl')
	USE IN curfl
ENDIF

c_foundfolder=""
FOR ni=1 TO ALEN(flreadpath,1)
	cpath=ADDBS(ALLTRIM(flreadpath[ni,2]))
	IF DIRECTORY(cpath+cSpec)
		c_foundfolder =(cpath+cSpec)
		EXIT
	ENDIF
ENDFOR
RETURN (c_foundfolder)

**************************************************************
*-------------------------------------------------------------------------
* Post jobs to the distribution server. Do it here instead of in the
* printcovr program
*-------------------------------------------------------------------------

FUNCTION  Zoloftdsjobs
PARAMETERS cclcode, nRt, nTag

LOCAL n_Curarea,c_shiptype,bresult,oflgen,iCnt
bresult = .F.
oflgen=CREATEOBJECT('cntdataconn') && CREATEOBJECT("medgeneric")
*--nr=oflgen.sqlpassthrough(c_sql,'curfl')
n_Curarea=SELECT()
SELECT 0
DIMENSION a_types[4,2]
a_types[1,1]="D"
a_types[2,1]="V"
a_types[3,1]="C"
a_types[4,1]="W"
a_types[1,2]="DS"
a_types[2,2]="VS"
a_types[3,2]="CD"
a_types[4,2]="DV"

n_alen=ALEN(a_types, 1)

*--7/27/17: change for current Zof add DS job rules. #66230
c_sql = "exec [dbo].[GetzolflrelPostingatcodes]'" + cclcode + "'," + ALLTRIM(STR(nTag))
*--c_sql= "exec [dbo].[Getzolflrelatcodes] '" + cclcode + "'"
nr=oflgen.sqlpassthrough(c_sql,"curatty")

IF NOT USED("curatty")
	RETURN bresult
ENDIF

SELECT curatty
SCAN
	cAtcode = curatty.at_code
	IF EMPTY(cAtcode)
		LOOP
	ENDIF

*--11/22/16: only add tbldisttodo job for ordered at_codes
	c_sql= "exec [dbo].[GetOrderbyClAtTagOrdered] '" + cclcode + "','" +  fixquote(cAtcode) + "'," + ALLTRIM(STR(nTag))
*--c_sql= "exec [dbo].[GetOrderbyClAtTag] '" + cclcode + "','" +  fixquote(cAtcode) + "'," + ALLTRIM(STR(nTag))
	nr=oflgen.sqlpassthrough(c_sql,"curorder")
	IF RECCOUNT("curorder")=0
*  RETURN .F.
* 11/27/2016 - in case there is more than one attorney
		LOOP
	ENDIF

	c_Ordtypes = ""
	c_sql="Exec dbo.call_dsordertype '"+cclcode+"', "+ALLTRIM(STR(nTag))+","+ ;
		"'"+fixquote(cAtcode)+"', '"+""+"', '', '1', "+;
		"'"+curorder.id_tblOrders+"', '', '&c_Ordtypes.',2"
	nr=oflgen.sqlpassthrough(c_sql,"viewShipTypes")
	SELECT viewShipTypes
	IF RECCOUNT()>0
		GO TOP IN viewShipTypes
		c_Ordtypes=ALLTRIM(NVL(viewShipTypes.ordtypes,''))
	ENDIF
	IF USED("curorder")
		USE IN curorder
	ENDIF
	IF USED("viewShipTypes")
		USE IN viewShipTypes
	ENDIF

	lcshiptype=IIF(EMPTY(c_Ordtypes),"P",c_Ordtypes)
	FOR iCnt = 1 TO ALEN(a_types,1)
		IF a_types[icnt,1] $ lcshiptype
			IF gfsendds(cAtcode)
				DO dsZolInsert WITH a_types[icnt,2], nRt, nTag, cAtcode, cclcode
				IF ALLTRIM(a_types[icnt,2])=="DV" THEN
					c_sql = "UPDATE tbldistbill set date_proc = getdate() where cl_code = '&cclcode.' and tag =" + ALLTRIM(STR(nTag)) + ;
						" and at_code = '" + fixquote(cAtcode) + "' and shiptype in ('DS','VS') and deleted is null and date_proc is null"
				ELSE
					c_sql = "UPDATE tbldistbill set date_proc = getdate() where cl_code = '&cclcode.' and tag =" + ALLTRIM(STR(nTag)) + ;
						" and at_code = '" + fixquote(cAtcode) + "' and shiptype = '" + a_types[icnt,2] + "' and deleted is null and date_proc is null"
				ENDIF

				nr=oflgen.sqlpassthrough(c_sql)
				bresult = .T.
			ENDIF
		ENDIF
	NEXT
	SELECT curatty
ENDSCAN

IF USED("curatty")
	USE IN curatty
ENDIF

SELECT (n_Curarea)
RETURN bresult

****************************************************************************************
PROCEDURE dsZolInsert
PARAMETERS ctype,nRt,nTag,cAtcode, cclcode
LOCAL oGen
oGen=CREATEOBJECT('cntdataconn') && CREATEOBJECT("medgeneric")

c_email=''
c_ImageDb='ZOL'
c_ImageDb2=''
c_rectype=ctype
n_Copies=0
n_Idval=0
n_priority=8
c_Userid = "ZOL_FLRELEASE"

*-- for rectype of DV, we need to clear out the DS and VS types and consolidate in the single DV type
IF c_rectype = "DV"
	c_sql = "update tbldisttodo set rem_date = getdate(), rem_by= 'FLR_DVTYPE' where lrs_no="+ALLTRIM(STR(nRt))+" and tag="+ALLTRIM(STR(nTag))+;
		" and at_code='"+fixquote(cAtcode) + "' and rectype in ('DS','VS') and (rem_date is null OR (rem_date IS NOT null AND rem_by='FL_TEMP_HOLD'))"
	nr=oGen.sqlpassthrough(c_sql)
ENDIF

c_sql="select * from tbldisttodo where lrs_no="+ALLTRIM(STR(nRt))+" and tag="+ALLTRIM(STR(nTag))+;
	" and at_code='"+fixquote(cAtcode)+ "' and rectype='&c_rectype.' and (rem_date is null OR (rem_date IS NOT null AND rem_by='FL_TEMP_HOLD'))"
nr=oGen.sqlpassthrough(c_sql,'indist')

IF RECCOUNT('indist')<1
*--12/6/16: add check for client rep hold status
	shold = "0"		&& tbldisttodo hold flag
	c_sql="SELECT COUNT(*) as icount FROM tblorder WITH (nolock)  WHERE cl_code= '"+ cclcode +"'  AND tag="+ ALLTRIM(STR(nTag)) +" AND at_code= '" + fixquote(cAtcode) + "' AND ISNULL(handling,'')='R' AND active=1 and deleted is null"
	nr=oGen.sqlpassthrough(c_sql,'curhold')
	IF USED("curhold")
		SELECT curhold
		IF RECCOUNT()>0
			GO TOP IN curhold
			shold = IIF(curhold.icount > 0, "1", "0")
		ENDIF
		USE IN curhold
	ENDIF

	c_dsjobid=gfdsjobid()

	c_sql="INSERT INTO tbldisttodo ( "+;
		"lrs_no, tag, at_code, email, imagedb1,"+;
		"imagedb2, enter_date, enter_time, rectype, Add_by,"+;
		"Copies, [Id],priority,active,job_id,created,proc_time,"+;
		"jobphase,produced,rem_by,rem_time,"+;
		"atmt_time,delay,on_hold,"+;
		"alerts,viewalerts,webalerts,not_ocr,pages"+;
		",proc_date"+;
		")"+;
		" VALUES ("+;
		ALLTRIM(STR(nRt))+;
		","+ALLTRIM(STR(nTag))+;
		",'"+fixquote(cAtcode)+"'"+;
		",'"+c_email+"'"+;
		",'"+c_ImageDb+"'"+;
		",'"+c_ImageDb2+"'"+;
		",GETDATE()"+;
		",CONVERT(CHAR(8),GETDATE(),114)"+;
		",'"+c_rectype+"'"+;
		",'"+c_Userid+"'"+;
		","+ALLTRIM(STR(n_Copies))+;
		","+ALLTRIM(STR(n_Idval))+;
		","+ALLTRIM(STR(n_priority))+;
		",1"+;
		",'"+c_dsjobid+"'"+;
		",GETDATE()"+;
		",'','',0,'','','',0," + shold + ",0,0,0,0,0"+;
		",GETDATE()"+;
		")"

	nr=oGen.sqlpassthrough(c_sql)

ELSE
	SELECT indist
	SCAN FOR ISNULL(indist.proc_date)
		c_sql = "update tbldisttodo set proc_date = getdate() where job_id = '" + ALLTRIM(indist.job_id) + "'"
		nr=oGen.sqlpassthrough(c_sql)
		SELECT indist
	ENDSCAN
ENDIF


*-------------------------------------------------------------------------
* Post jobs to the distribution server. Do it here instead of in the
* printcovr program
*-------------------------------------------------------------------------
PROCEDURE PostDsJobs
PARAMETERS lcClCode, n_tag
LOCAL n_Curarea,c_shiptype
n_Curarea=SELECT()
pl_GotCase=.F.
LOCAL oGen
oGen=CREATEOBJECT('cntdataconn')
IF NOT USED('master')
**10/01/18 SL #109598
*oGen.sqlpassthrough("SELECT * FROM tblmaster WITH (nolock,INDEX (ix_tblmaster_2)) WHERE cl_code='"+ lcClCode +
	oGen.sqlpassthrough("SELECT * FROM tblmaster WITH (nolock) WHERE cl_code='"+ lcClCode +;
		"' AND active=1 AND deleted IS null",'master')
ENDIF
DO gfgetcas
pl_GotDepo=.F.
*--GO TOP IN casedeponent
DO gfgetdep WITH lcClCode,n_tag

SELECT 0
*omed=CREATEOBJECT('medgeneric')
**10/01/18 SL #109598
*c_sql="select * from tblorder WITH (nolock,index (ix_tblorder_1)) where "+
c_sql="select * from tblorder WITH (nolock) where "+;
	"cl_code='&lcclcode.' and tag="+STR(n_tag)+;
	"AND date_order is not null AND date_decln IS null AND date_cancl is null "+;
	"AND active=1 and deleted is null"
nl = oGen.sqlpassthrough(c_sql,'actorders')

IF RECCOUNT('actorders')>0
	SELECT actorders
	DIMENSION a_types[6]
	a_types[1]="P"
	a_types[2]="D"
	a_types[3]="V"
	a_types[4]="C"
	a_types[5]="F"
	a_types[6]="W"
	n_alen=ALEN(a_types, 1)
	SCAN
		c_Ordtypes = IIF( actorders.numcopy > 0 AND ;
			INLIST(actorders.shiptype, " ", "P"), "P", actorders.shiptype)

		lcSQLLine="Exec dbo.call_dsordertype '"+lcClCode+"', "+ALLTRIM(STR(n_tag))+","+ ;
			"'"+fixquote(actorders.at_code)+"', '"+""+"', '"+actorders.shiptype+"', '1', "+;
			"'"+actorders.id_tblOrders+"', '', '&c_Ordtypes.',2"
		nl = oGen.sqlpassthrough(lcSQLLine,"viewShipTypes")
		SELECT viewShipTypes
		IF RECCOUNT()>0
			GO TOP IN viewShipTypes
			c_Ordtypes=ALLTRIM(NVL(viewShipTypes.ordtypes,''))
		ENDIF
		USE IN viewShipTypes
		lcshiptype=IIF(EMPTY(c_Ordtypes),"P",c_Ordtypes)
		FOR EACH c_shiptype IN a_types		&&n_shpcnt = 1 TO n_Alen
			IF c_shiptype $ lcshiptype
				IF c_shiptype<>"P"		&&INLIST(c_shiptype,"D","V","C","F","W")
					IF gfsendds(actorders.at_code)
						n_dsid=gfdsjobid()
						c_sql= "EXEC dbo.dspost '&lcclcode.',"+STR(n_tag)+",'"+;
							fixquote(actorders.at_code)+"','"+fixquote(pc_area)+"',0,'"+;
							c_shiptype+"','',6,1,NULL,'&n_dsid.'"
						nl= oGen.sqlpassthrough(c_sql)
					ENDIF
				ENDIF
			ENDIF
		ENDFOR
		SELECT actorders
	ENDSCAN
ENDIF
IF USED('actorders')
	USE IN actorders
ENDIF
SELECT (n_Curarea)
