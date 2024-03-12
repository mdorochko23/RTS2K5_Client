
**PROCEDURE TagMailUpd
**EF Added to replace the "N": Change Mail ID option of the old deponent options screen
** 08/21/2006 - MD modified to move "Mail ID hase been changed" message  inside the loop
** 06/11/2013 - EF - Added Department
PARAMETERS	c_id_tblrequests
PRIVATE c_NewDesc AS STRING, l_Confirm2 AS Boolean, l_Confirm AS Boolean
STORE .F. TO l_Confirm2, l_Confirm
IF NOT (pl_UnitMgr OR INLIST((ALLTRIM(goApp.userdepartment)), "ICU", "DPU"))
	lc_message = "Not authorized. Please check with your manager."
	o_message = CREATEOBJECT('rts_message',lc_message)
	o_message.SHOW
ELSE

	SELECT RECORD
	SCATTER NAME loRecord MEMO
	pc_Mailid=	loRecord.mailid_no
	IF ISNULL(pc_Mailid)
		WAIT WINDOW "NOTE: Tag does not have any Mail Id assigned to it yet." NOWAIT NOCLEAR
		RETURN
	ENDIF

	loRecord = goApp.OpenForm("Deponent.frmDeponentSearch", "M", NULL, NULL)
	c_NewDesc=""
	IF ISNULL(loRecord)
		RETURN
	ENDIF
	c_NewDesc=IIF(LEFT(loRecord.mailid_no, 1)="D", "DR. " +gfDrFormat(loRecord.NAME), loRecord.NAME)
	IF loRecord.RETIRE
		lc_message = "You picked a retired deponent. Mail ID cannot be changed."
		o_message = CREATEOBJECT('rts_message',lc_message)
		o_message.SHOW
		RETURN

	ENDIF

	IF USED('Timesheet')
		SELECT timesheet
		USE
	ENDIF


	LOCAL ots AS medtimesheet OF timesheet
	ots = CREATEOBJECT("medtimesheet")


	c_sql=""
	c_sql="Exec [dbo].[GetEntrybyClTagTxn4] '" +fixquote(Record.cl_code) + "','" + ALLTRIM(STR(Record.tag) ) +"'"

	L_TS = ots.sqlexecute(c_sql,'Timesheet')
	IF L_TS AND NOT EOF()
		SELECT timesheet
		INDEX ON cl_code+"*"+STR(TAG)  TAG cltag ADDITIVE


		SET ORDER TO cltag IN timesheet
		IF SEEK( (Record.cl_code + "*" + STR(Record.tag)), "Timesheet") AND UPPER( LEFT( ALLTRIM( DESCRIPT),6)) == "MIRROR"
			IF record.reissue=.T.	&& 12/08/2015 - MD #21091 allow to change MID if its Mirrored but not reissued.
				lc_message = "Mirrored tag. Mail ID cannot be changed."
				o_message = CREATEOBJECT('rts_message',lc_message)
				o_message.SHOW

				RETURN
			ENDIF 
		ENDIF

	ENDIF

	*09/03/2021 WY 249529 when user selects "No" they do not want to apply the new mailid, this reveals a nasty bug
	*the potential change is already saved to the local cursor thus the change is reflected back to the deponent option screen
	*the old code section is commented out below *</249529>
	*<249529>
	LOCAL lcNewMailId_No, lcNewDesc, lcNewId_TblDeponents
	lcNewMailId_No = loRecord.MailId_No
	lcNewDesc = ""
	lcNewId_TblDeponents = loRecord.id_tbldeponents	 
	d_null=NULL
	d_empty=""

	IF NOT (EMPTY( convrtDate(pd_closing)))
		DO gfReopen WITH .F., "Changing a deponent's Mail ID"
	ENDIF

	*SELECT  REQUEST
	lc_message = "REPLACE MAIL ID " + ALLTRIM(pc_Mailid) + " WITH " +  ALLTRIM(lcNewMailId_No) + "?"
	o_message = CREATEOBJECT('rts_message_yes_no',lc_message)
	o_message.SHOW
	l_Confirm=IIF(o_message.exit_mode="YES",.T.,.F.)
	o_message.RELEASE
	IF l_Confirm
		_SCREEN.MOUSEPOINTER= 11

		&& 06/29/2011- check for similar deponents
		l_Confirm2=chkalikedep(c_NewDesc, record.cl_code)
		&& 06/29/2011- check for similar deponents

		IF NOT l_Confirm2
			WAIT WINDOW " Update was canceled .." NOWAIT
			RETURN
		ENDIF
			
		***check departent - allow to pick a new one -6/11/13 
		*lc_DepName=m.Descript		
		ots.closealias("dept")
		c_sql="select dbo.GetDeptCode2('" +fixquote(record.cl_code) +"',"+ALLTRIM(STR(record.tag))+") as deptcode"
		ots.sqlexecute(c_sql, "Dept")		
		c_dep=DepToPrint2( ALLTRIM(NVL(c_NewDesc,"")), lcNewMailId_No)		
		
		lc_HospDept =get_hdept(lcNewMailId_No, NVL(Dept.deptcode,'Z'))		
				
		c_addition= getdescript(lc_HospDept)		
		lc_DepName= c_dep + IIF(pc_deptype = "H" OR pl_CaVer ,c_addition,"") 
		
		SELECT REQUEST	
		REPLACE DESCRIPT WITH lc_DepName, ;
				mailid_no with lcNewMailId_No, ;
				id_tbldeponents WITH lcNewId_TblDeponents IN REQUEST

		** 6/11/13 - end
		WAIT WINDOW " Update in progress.. please wait.." NOWAIT NOCLEAR
		l_UpdRec=ots.sqlexecute("Exec [dbo].[GlobalMailIdUpdate2] '" + ;
			lcNewId_TblDeponents + "','" + fixquote(Record.cl_code) + ;
			"','" + STR(Record.tag) + "','"+fixquote( ALLTRIM(pc_Mailid)) + "','" + ;
			fixquote(ALLTRIM(lcNewMailId_No)) + "','" + fixquote(lc_DepName)+ "','" + ;
			ALLTRIM(fixquote(pc_UserID)) + "','"+ lc_HospDept + "'" )

		IF l_UpdRec
			c_comments = "MAIL ID CHANGED FROM " + fixquote(ALLTRIM(pc_Mailid))+ " TO " ;
				+ fixquote(ALLTRIM(lcNewMailId_No)) + " BY: " + fixquote(ALLTRIM(pc_UserID))

			DO AddStcTxn WITH  fixquote(lc_DepName), fixquote(Record.cl_code), 4, record.tag, ;
				fixquote(ALLTRIM(lcNewMailId_No)), record.TYPE, fixquote(pc_UserID), ;
				record.id_tblRequests, c_comments, .T.

		ENDIF
		RELEASE ots

		_SCREEN.MOUSEPOINTER= 0
		IF NOT (EMPTY(convrtDate(pd_closing)))
			WAIT WINDOW "NOTE: Case is being automatically re-opened." NOWAIT NOCLEAR
			DO gfReopen WITH .T., "changing the Mail ID of Tag " + ;
				ALLT( STR( Record.tag)) + "."
		ENDIF
		_SCREEN.MOUSEPOINTER= 11
		pl_GotDepo = .F.
		DO gfGetDep WITH record.cl_code, record.tag
		*</249529>


*!*		REPLACE ;
*!*			mailid_no 			WITH ALLTRIM(loRecord.mailid_no),;
*!*			DESCRIPT 				WITH c_NewDesc,;
*!*			id_tbldeponents WITH loRecord.id_tbldeponents ;
*!*			IN REQUEST
*!*		SELECT REQUEST
*!*		SCATTER MEMVAR
*!*		d_null=NULL
*!*		d_empty=""

*!*		IF NOT (EMPTY( convrtDate(pd_closing)))
*!*			DO gfReopen WITH .F., "Changing a deponent's Mail ID"
*!*		ENDIF


*!*		SELECT  REQUEST




*!*		lc_message = "REPLACE MAIL ID " + ALLTRIM(pc_Mailid) + " WITH " +  ALLTRIM(m.mailid_no) + "?"
*!*		o_message = CREATEOBJECT('rts_message_yes_no',lc_message)
*!*		o_message.SHOW
*!*		l_Confirm=IIF(o_message.exit_mode="YES",.T.,.F.)
*!*		o_message.RELEASE
*!*		IF l_Confirm
*!*			_SCREEN.MOUSEPOINTER= 11

*!*	&& 06/29/2011- check for similar deponents
*!*			l_Confirm2=chkalikedep(m.DESCRIPT, m.cl_code)
*!*	&& 06/29/2011- check for similar deponents

*!*			IF NOT l_Confirm2
*!*				WAIT WINDOW " Update was canceled .." NOWAIT
*!*				RETURN

*!*			ENDIF
*!*				
*!*			***check departent - allow to pick a new one -6/11/13 
*!*			lc_DepName=m.Descript		
*!*			ots.closealias("dept")
*!*			c_sql="select dbo.GetDeptCode2('" +fixquote(m.cl_code) +"',"+ALLTRIM(STR(m.tag))+") as deptcode"
*!*			ots.sqlexecute(c_sql, "Dept")		
*!*			c_dep=DepToPrint2( ALLTRIM(NVL(m.Descript,"")), M.mailid_no)		
*!*			
*!*			lc_HospDept =get_hdept(m.mailid_no, NVL(Dept.deptcode,'Z'))		
*!*			
*!*			
*!*			c_addition= getdescript(lc_HospDept)		
*!*			lc_DepName= c_dep + IIF(pc_deptype = "H" OR pl_CaVer ,c_addition,"") 
*!*			
*!*			SELECT REQUEST	
*!*			REPLACE DESCRIPT WITH lc_DepName		IN REQUEST
*!*			** 6/11/13 - end
*!*			WAIT WINDOW " Update in progress.. please wait.." NOWAIT NOCLEAR
*!*			l_UpdRec=ots.sqlexecute("Exec [dbo].[GlobalMailIdUpdate2] '" + ;
*!*				m.id_tbldeponents+ "','" + fixquote(m.cl_code) + ;
*!*				"','" + STR(m.tag) + "','"+fixquote( ALLTRIM(pc_Mailid)) + "','" + ;
*!*				fixquote(ALLTRIM(m.mailid_no)) + "','" + fixquote(lc_DepName)+ "','" + ;
*!*				ALLTRIM(fixquote(pc_UserID)) + "','"+ lc_HospDept + "'" )

*!*			IF l_UpdRec
*!*				c_comments = "MAIL ID CHANGED FROM " + fixquote(ALLTRIM(pc_Mailid))+ " TO " ;
*!*					+ fixquote(ALLTRIM(m.mailid_no)) + " BY: " + fixquote(ALLTRIM(pc_UserID))

*!*				DO AddStcTxn WITH  fixquote(m.Descript), fixquote(m.cl_code), 4, m.tag, ;
*!*					fixquote(ALLTRIM(m.mailid_no)), m.TYPE, fixquote(pc_UserID), ;
*!*					m.id_tblRequests, c_comments, .T.

*!*			ENDIF
*!*			RELEASE ots

*!*			_SCREEN.MOUSEPOINTER= 0
*!*			IF NOT (EMPTY(convrtDate(pd_closing)))
*!*				WAIT WINDOW "NOTE: Case is being automatically re-opened." NOWAIT NOCLEAR
*!*				DO gfReopen WITH .T., "changing the Mail ID of Tag " + ;
*!*					ALLT( STR( M.tag)) + "."
*!*			ENDIF
*!*			_SCREEN.MOUSEPOINTER= 11
*!*			pl_GotDepo = .F.
*!*			DO gfGetDep WITH m.cl_code, m.tag

		_SCREEN.MOUSEPOINTER= 0
		lc_message = "Mail ID has been changed."
		o_message = CREATEOBJECT('rts_message',lc_message)
		o_message.SHOW
	ENDIF


* ELSE  - COMMENTED BY MD ON 06/22/2006
ENDIF


WAIT CLEAR

RETURN

********************************************

	

FUNCTION GET_HDEPT
********************************************
PARAMETERS cMailid_no, c_hospdept
PUBLIC lc_dept AS String
LOCAL c_deptype as String

	c_deptype=UPPER(LEFT(cMailid_no,1))
	c_oldDepType=UPPER(LEFT(pc_Mailid,1))
	IF c_deptype = "H" 
	IF c_oldDepType ="H"
		lc_message = "Is the department information to be mirrored?"
		o_message = CREATEOBJECT('rts_message_yes_no',lc_message)
		o_message.SHOW
		l_Confirm=IIF(o_message.exit_mode="YES",.T.,.F.)
		o_message.RELEASE
		IF  NOT l_Confirm
		
		lc_dept = validdept(cMailid_no)		
*!*				IF TYPE("lc_dept")!="C" OR ISNULL(lc_dept)=.T.
*!*						gfmessage("Please pick a Department.")
*!*						llexit=.F.
*!*						DO WHILE  llexit=.F.
*!*							DO hospdept.mpr
*!*							IF TYPE("lc_dept")="C" AND ISNULL(lc_dept)=.F.
*!*								llexit=.T.
*!*							ENDIF
*!*						ENDDO
*!*					ENDIF
*!*					
				c_HospDept=UPPER(lc_dept)
				RELEASE lc_dept		


		ENDIF
	ELSE
	** changing from non hospital to hospital 10/08/14 -foRce to pick a department
	 PUBLIC LC_DEPT
			&&11/27/2017:  allow to pick the dept that exist in our Rolodex #67478
			lc_dept = validdept(cMailid_no)		
*!*		LC_MESSAGE = "Please pick a Department for your request."
*!*		O_MESSAGE = CREATEOBJECT('rts_message',LC_MESSAGE)
*!*		O_MESSAGE.SHOW
*!*		DO HOSPDEPT.MPR
	c_hospDept=LC_DEPT
	RELEASE LC_DEPT

	
	
	ENDIF
	
	ELSE
	
	 c_hospDept="" &&DEFAULT
	
	
	
	
	
	ENDIF
RETURN c_hospDept



********************************************
FUNCTION DepToPrint2
PARAMETERS  cdeponame, cMidno
LOCAL o_name as Object,  c_dname as String, c_depn as String, c_drname as String

STORE "" to c_dname, c_depn, c_drname

		IF NOT ISDIGIT( LEFT( ALLT( cMidno), 1))
			pc_deptype = LEFT( ALLT( cMidno), 1)
		ELSE
			pc_deptype = "D"
		ENDIF

c_dname=ALLTRIM(cdeponame)
IF pc_deptype == "D"
	c_drname=gfdrformat(c_dname)
	c_depn = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
ELSE
	c_depn = ALLTRIM(c_dname)
ENDIF
RELEASE o_name


RETURN c_depn
