**************************************************************************************
* PROGRAM: GFDISJOB
* Programmer: kdl
* Date: 5/22/03
* Abstract: Send job to global Disttodo.dbf
* Called by: flproc.add88txn
* Calls: gfuse_ro.prg, gfunuse.prg, gfmsg.prg
*
* Modified:
* 05/09/05 kdl - converted to use sql tables
* 06/22/04 kdl - add id values to posted jobs
* 02/16/04 kdl - Add email parameter
* 01/22/04 kdl - Added field value for order Id to insert and parameter statement
* 01/02/04 kdl - Added logic to allow jobs (CD) without email notifications
* 12/08/03 kdl - Added code to prevent duplication of job requests
* 08/21/03 kdl - Added check for default email address to eliminate user interface
*           when one is set
*
**************************************************************************************
PARAMETERS n_Lrsno, n_Tag, c_Atcode, c_RecType, l_sendmail, c_ImageDb, n_Copies, ;
	n_Idval, c_email, d_dateproc, c_timeproc
IF PARAMETERS() < 6
   c_ImageDb = ""
ENDIF
IF PARAMETERS() < 7
	n_Copies = 1
ENDIF
IF PARAMETERS() < 8
	n_Idval = 0
ENDIF
*--2/16/04 kdl start: added email parameter check
IF TYPE("c_email") <> "C"
	c_email = ""
ENDIF
IF TYPE("d_dateproc") <> "D"
	d_dateproc = {  /  /    }
ENDIF
IF TYPE("c_timeproc") <> "C"
	c_timeproc = ""
ENDIF

PRIVATE l_Access, n_Pos, okcancel, l_Disttodo, n_CurArea, l_distins
LOCAL c_Addjob
n_CurArea = SELECT()
*--kdl out 2/16/04: c_Email = ""                      && selected email address
*--no email is sent for these jobs
l_SndEmail = .F. &&NOT INLIST(c_RecType, "CD")
*--first check for set default first-look email address for attorney code
*--1/02/04 kdl start: block email check if job type is CD
IF l_SndEmail
	l_Access = gfuse_ro("gaccess")
	c_sqlsel = "SELECT RTRIM(email) "  + ;
	      "FROM tblaccess a " + ;
	      "WHERE a.at_code = &c_Atcode AND " + ;
	      "NOT EMPTY(email) AND " + ;
	      "a.first_look = 'Y'"

*!*		SELECT ALLTRIM(email) FROM access ;
*!*		   INTO ARRAY a_Email ;
*!*		   WHERE access.at_code = c_Atcode AND ;
*!*		   NOT EMPTY(email) AND ;
*!*		   access.first_look == "Y"

	n_Result = SQLExec(pn_connection, c_Sqlsel, "curemail")
	n_Result = o_sql.sqltally( pn_connection, "curemail")
	IF n_Result = 1
	   c_Email = curemail.email  &&a_Email[1]
	ELSE
	   *--let user select email address from those in access table for the
	   *--passed att code
		c_sqlsel = "SELECT RTRIM(name_first)+' '+RTRIM(name_last)+'| '+RTRIM(email) "  + ;
		      "FROM tblaccess a " + ;
	    	  "WHERE a.at_code = &c_Atcode AND " + ;
		      "NOT EMPTY(email)"
		n_Result = SQLExec(pn_connection, c_Sqlsel, "curemail")
		n_Result = o_sql.sqltally( pn_connection, "curemail")

*!*		   SELECT ALLTRIM(name_first) + " " + ALLTRIM(name_last) + ;
*!*		      "| " + ALLTRIM(email) ;
*!*		      FROM access INTO ARRAY a_Email ;
*!*		      WHERE access.at_code = c_Atcode AND ;
*!*		      NOT EMPTY(email)

	   IF n_Result > 0
	      n_Size = ALEN(a_Email, 1) + 2
	      n_Size = IIF( n_size < 10, n_Size , 10)
	      DEFINE WINDOW popEmail FROM 4,4 TO (4+n_size+4), 76 ;
	         TITLE ' Select Attorney Email Address ' ;
	         SHADOW DOUBLE
	      ACTIVATE WINDOW popEmail
	      *--popup from array
	      @ 1, 1 GET c_Bar FROM curemail ;
	         SIZE n_size,69 ;
	         DEFAULT a_Email(1)
	      @ n_Size+2, 25 GET okcancel PICTURE '@*HT \!OK;\?Cancel' SIZE 1,10 DEFAULT 0
	      READ CYCLE
	      DEACTIVATE WINDOW popEmail
	      RELEASE WINDOW popEmail
	      IF okcancel = 1
	         n_Pos = RAT("|",c_bar) + 1
	         c_Email = SUBSTR(c_bar, n_Pos, LEN(c_bar))
	      ENDIF
	   ENDIF
	ENDIF
	= gfunuse("access", l_Access)
ENDIF

IF NOT EMPTY(c_Email) OR NOT l_SndEmail
   *--send todo job to web system
*--	l_Disttodo = gfuse("disttodo")
	*--12/08/03 kdl start: check for duplicate job requests
	c_Addjob = .T.
	*--check for existing job requests
*--	SET ORDER TO lrstagat
	c_fields = "*"
	c_where = "'" + ALLTRIM(STR(n_lrsno)) + ALLTRIM(STR(n_tag)) + PADR(c_Atcode, 8) + c_rectype + "'" +;
		" = " + "RTRIM(LTRIM(CAST(tbldisttodo.lrs_no AS char(8)))) + RTRIM(LTRIM(CAST(tbldisttodo.tag AS char(3)))) + tbldisttodo.At_code + tbldisttodo.rectype" 
	
	c_order = ""
	n_result = o_sql.sqlquery( pn_connection," FROM tbldisttodo", c_fields, c_where, c_order, "curdist")
	IF o_sql.nresult > 0
*--	IF SEEK(STR(n_lrsno) + STR(n_tag) + PADR(c_Atcode, 8) + c_rectype)
		SELECT curdist
		SCAN
*!*			SCAN WHILE STR(n_lrsno) + STR(n_tag) + c_Atcode = ;
*!*					STR(disttodo.lrs_no) + STR(disttodo.tag) + disttodo.at_code
			IF EMPTY(curdist.rem_date) AND ;
				STR(curdist.lrs_no) + STR(curdist.tag) + curdist.at_code + curdist.rectype = ;
				STR(n_lrsno) + STR(n_tag) + c_Atcode + c_rectype
				c_Addjob = .F.
				*--update the process date if there is one
*				IF NOT EMPTY(disttodo.proc_date)
*					DO WHILE NOT RLOCK()
*					ENDDO
*					REPLACE disttodo.proc_date WITH {  /  /    }, ;
*						disttodo.proc_time WITH "", ;
*						disttodo.email WITH ALLTRIM(c_Email)
*					UNLOCK
*				ENDIF

			ENDIF
		ENDSCAN
	ENDIF
	IF USED("curdist")
		USE IN curdist
	ENDIF
	*--add job requests
	IF c_Addjob
		*--1/22/04 kdl start: add n_Idval to insert when > 0
		*--6/22/04 kdl start: add id value to jobs
*--		c_Newid = lfnewid()
		*--new system will guids instead of job ids
		c_Newid = ""
		IF n_Idval > 0
			c_fieldlist = "lrs_no,tag,at_code,email,imagedb1,enter_date," + ;
				"enter_time,rectype,Add_by,Copies,Id,job_id,proc_date," + ;
				"proc_time, priority"
			c_valuelist = o_str.SQLNP(n_lrsno, .T.) + ;
				o_str.SQLNP(n_Tag, .T.) + ;	
				o_str.SQLQP(c_Atcode, .T.) + ;
				o_str.SQLQP(ALLTRIM(c_Email), .T.) + ;
				o_str.SQLQP(c_ImageDb, .T.) + ;
				o_str.SQLDP(DATE(), .T.) + ;
				o_str.SQLQP(TIME(), .T.) + ;
				o_str.SQLQP(c_Rectype, .T.) + ;
				o_str.SQLQP(pc_UserId, .T.) + ;
				o_str.SQLNP(n_Copies, .T.) + ;	
				o_str.SQLNP(n_Idval, .T.) + ;	
				o_str.SQLQP(c_Newid, .T.) + ;
				o_str.SQLDP(d_dateproc, .T.) + ;
				o_str.SQLQP(c_timeproc, .T.) + ;
				o_str.SQLNP(6, .F.)
				
			o_sql.sqlinsert(pn_connection,"tbldisttodo",;
				c_fieldlist, c_valuelist)

*!*		  		INSERT INTO disttodo ( ;
*!*	  	  			lrs_no, tag, at_code, email, imagedb1, ;
*!*		  			enter_date, enter_time, rectype, Add_by, ;
*!*					Copies, Id, job_id, proc_date, proc_time, priority);
*!*		  			VALUES ( ;
*!*		  			n_lrsno, n_Tag, c_Atcode, ALLTRIM(c_Email), c_ImageDb, ;
*!*		  			DATE(), TIME(), c_Rectype, pc_UserId, ;
*!*					n_Copies, n_Idval, c_Newid, d_dateproc, c_timeproc, 3)
		ELSE

			c_fieldlist = "lrs_no,tag,at_code,email,imagedb1,enter_date," + ;
				"enter_time,rectype,Add_by,Copies,job_id,proc_date," + ;
				"proc_time, priority"
			c_valuelist = o_str.SQLNP(n_lrsno, .T.) + ;
				o_str.SQLNP(n_Tag, .T.) + ;	
				o_str.SQLQP(c_Atcode, .T.) + ;
				o_str.SQLQP(ALLTRIM(c_Email), .T.) + ;
				o_str.SQLQP(c_ImageDb, .T.) + ;
				o_str.SQLDP(DATE(), .T.) + ;
				o_str.SQLQP(TIME(), .T.) + ;
				o_str.SQLQP(c_Rectype, .T.) + ;
				o_str.SQLQP(pc_UserId, .T.) + ;
				o_str.SQLNP(n_Copies, .T.) + ;	
				o_str.SQLQP(c_Newid, .T.) + ;
				o_str.SQLDP(d_dateproc, .T.) + ;
				o_str.SQLQP(c_timeproc, .T.) + ;
				o_str.SQLNP(6, .F.)

			o_sql.sqlinsert(pn_connection,"tbldisttodo",;
				c_fieldlist, c_valuelist)

*!*		  		INSERT INTO disttodo ( ;
*!*	  	  			lrs_no, tag, at_code, email, imagedb1, ;
*!*		  			enter_date, enter_time, rectype, Add_by, Copies, job_id, ;
*!*		  			proc_date, proc_time, priority);
*!*		  			VALUES ( ;
*!*		  			n_lrsno, n_Tag, c_Atcode, ALLTRIM(c_Email), c_ImageDb, ;
*!*		  			DATE(), TIME(), c_Rectype, pc_UserId, n_Copies, c_Newid, ;
*!*		  			d_dateproc, c_timeproc, 3)
	  ENDIF
		*--1/22/04 kdl end:
	  l_Newjob = .T.	
	ENDIF
*--	= gfunuse("disttodo", l_Disttodo)
   l_sendmail = .t.
ELSE
   = MESSAGEBOX("No web-account email address(es) found.", 0 + 48)
ENDIF

SELECT (n_CurArea)

***************************************************************************
*-- FUNCTION: LFNEWID
*-- Abstract: Get new job id number
***************************************************************************
FUNCTION lfnewid
PRIVATE n_Curarea, n_jobnum, c_Prefix, l_distid
n_Curarea = SELECT()
IF NOT USED("distid")
	USE k:\data\global\rts\distid IN 0
	l_distid = .F.
ENDIF	
SELECT distid
GOTO TOP
DO WHILE NOT RLOCK()
ENDDO
DO WHILE flag
ENDDO
REPLACE flag WITH .T.
*-- Increment counter
n_jobnum = distid.jobid_no + 1
c_Prefix = distid.prefix
IF n_jobnum >=  99999999
   REPLACE distid.jobid_no WITH 1
	n_jobnum = 1
   IF RIGHT(c_Prefix,1) != "Z"
      *-- Increment prefix
      c_Prefix = CHR(ASC(c_Prefix) + 1)
      REPLACE distid.prefix WITH c_Prefix
   ELSE
      *-- Should never happen :-(
      DO WHILE .T.
         WAIT WINDOW "Seek MIS help! Please do not continue!!"
         WAIT WINDOW "DS Job ID overflow !!"
      ENDDO
   ENDIF
ELSE
   REPLACE distid.jobid_no WITH n_jobnum
ENDIF

REPLACE distid.flag WITH .F.
UNLOCK

IF l_distid = .F. AND USED("distid")
	USE IN distid
ENDIF	

SELECT (n_CurArea)

RETURN (c_Prefix + PADL(ALLTRIM(STR(n_jobnum)), 8, "0"))
