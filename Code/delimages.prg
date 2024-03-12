*--5/15/19: need to add ability to rename/move folder [87505]
DECLARE INTEGER MoveFile IN kernel32;
	STRING lpExistingFileName, STRING lpNewFileName

SQLDISCONNECT(0)
pn_lrsno=0
pn_tag=0
LOCAL o_rt,c_sql,nr,c_base,oFSO,cfoldname,cdelfoldnam,cReason,lmoved,lreset,cflfoldname,cWebpath,cClcode,cUser,lFirstlook
PRIVATE suser,nc,omed
lmoved=.F.
lreset=.F.
suser=ALLTRIM(goApp.CurrentUser.orec.login) + "_DI"
omed=CREATEOBJECT("medgeneric")
c_sql="select delete_images from tbluserctrl with (nolock) where Id_userctrl='"+;
	ALLTRIM(goApp.CurrentUser.orec.ID_USERCTRL)+"'"
omed.sqlexecute(c_sql,"viewUserCtrl")
SELECT viewUserCtrl
IF RECCOUNT()=0
	gfmessage("Can't access tblUserCtrl")
	RELEASE omed
	RETURN
ENDIF
IF NVL(viewUserCtrl.delete_images,.F.)=.F.
	gfmessage("You are not allowed to use this option")
	RELEASE omed
	RETURN
ENDIF
o_rt= CREATEOBJ("depdisposition.frmgetlrsandtag")
o_rt.SHOW
RELEASE o_rt
IF pn_lrsno=0 OR pn_tag=0
	gfmessage("No case and/or tag selected. Process cancelled.")
	RELEASE omed
	RETURN
ENDIF
cReason=''
o_rt= CREATEOBJ("depdisposition.frmgetdropreason")
o_rt.CAPTION="Enter Reason for Deleting Images"
o_rt.SHOW
IF o_rt.exit_mode="OK"
*--7/20/17" Clear any ' " ' in the string
	cReason=ALLTRIM(gfstrclean(STRTRAN(o_rt.droptext,'"',"")))
	RELEASE o_rt
ELSE
	RELEASE o_rt
	gfmessage("No reason entered for deleting images. Process cancelled.")
	RETURN
ENDIF
o_rt=.NULL.

IF NOT gfmessage("Delete scanned images for tag:"+ALLTRIM(STR(pn_lrsno))+"."+ALLTRIM(STR(pn_tag))+"?",.T.)
	RELEASE omed
	RETURN
ENDIF

*--record deletion and data updates--*
c_sql="exec dbo.getrequestbylrsno "+ALLTRIM(STR(pn_lrsno))+","+ALLTRIM(STR(pn_tag))
lr=omed.sqlexecute(c_sql,'request')
lFirstlook=NVL(REQUEST.first_look,.F.) AND NOT NVL(REQUEST.distribute,.F.)

*--1/26/22: remove web copies of record before removing RSS images. [262821]
cWebpath=ADDBS(MLPriPro("R", "RTS.INI", "Data","WebImageBasePathNew", "\")) ;
	+ IIF(lFirstlook,"rt-fl$\","rt-docs$\") ;
	+ ADDBS(PADL(ALLTRIM(STR(pn_lrsno)),8,"0")) ;
	+ ADDBS(PADL(ALLTRIM(STR(pn_tag)),3,"0")) + ;
	+ "RT-"+PADL(ALLTRIM(STR(pn_lrsno)),8,"0")+"-"+PADL(ALLTRIM(STR(pn_tag)),3,"0")+".pdf"
IF FILE(cWebpath)
	*08/04/2021 WY #246909 (make sure file delete does not throw an error)
	IF AbleToDelete (cWebpath) = .f.
		RETURN && can not delete try again later
	ENDIF 
	*ERASE (cWebpath)
ENDIF
*-- remove web copy of file from 14.70
cWebpath=ADDBS(MLPriPro("R", "RTS.INI", "Data","WebImageBasePath", "\")) ;
	+ IIF(lFirstlook,"rt-fl\","rt-docs\") ;
	+ ADDBS(PADL(ALLTRIM(STR(pn_lrsno)),8,"0")) ;
	+ ADDBS(PADL(ALLTRIM(STR(pn_tag)),3,"0")) + ;
	+ "RT-"+PADL(ALLTRIM(STR(pn_lrsno)),8,"0")+"-"+PADL(ALLTRIM(STR(pn_tag)),3,"0")+".pdf"
IF FILE(cWebpath)
	*08/04/2021 WY #246909 (make sure the file delete does not throw an error)
	IF AbleToDelete (cWebpath) = .f.
		RETURN && can not delete try again later
	ENDIF 
	*ERASE (cWebpath)
ENDIF
*-- remove any PNG files from web (there is no rt-fl or rt-docs sub folder for png files)
IF lFirstlook
	cWebpath = ""
	cWebpath=ADDBS(MLPriPro("R", "RTS.INI", "Data","WebImagePngPath", "\")) ;
		+ ADDBS(PADL(ALLTRIM(STR(pn_lrsno)),8,"0")) ;
		+ ADDBS(PADL(ALLTRIM(STR(pn_tag)),3,"0"))
	IF DIRECTORY(cWebpath)
		n_files = ADIR( a_files, ADDBS(cWebpath)+"*.png")
		loTherm=CREATEOBJECT("app.appfrmthermometer")
		n_fcnt=0
		FOR n_cnt = 1 TO n_files
			loTherm.updatedisplay(n_cnt, n_files, ;
				"Deleting first-look PNG files", "Deleted "+;
				ALLTRIM(STR(n_cnt))+" from "+ALLTRIM(STR(n_files)))
			c_file = a_files[n_cnt, 1]
			IF FILE(ADDBS(cWebpath) + a_files[n_cnt, 1])
				ERASE ADDBS(cWebpath) + a_files[n_cnt, 1]
			ENDIF
			n_fcnt=n_fcnt+1
		ENDFOR
		RELEASE loTherm
		n_files = ADIR( a_files, ADDBS(cWebpath)+"*.*")
		IF n_files = 0
			RMDIR cWebpath
		ENDIF
	ENDIF
ENDIF

*--update the web loading job tables
c_sql="update pdf_ocr..tbljob set dtdeleted=getdate() where srt="+ALLTRIM(STR(pn_lrsno))+ ;
	" and ntag="+ALLTRIM(STR(pn_tag))+" and dtdeleted is null"
lr=omed.sqlexecute(c_sql)

c_sql="update pdf_ocr..tblrecord set dtdeleted=getdate() where srt="+ALLTRIM(STR(pn_lrsno))+ ;
	" and ntag="+ALLTRIM(STR(pn_tag))+" and dtdeleted is null"
lr=omed.sqlexecute(c_sql)

*--delete scanned images from RSS
imgdelete(lFirstlook,cReason)

c_sql="update tblrequest set scan_date=null,scan_pages=0,scanned=0,scan_table='',pages=0, upld_date=null where id_tblrequests='"+ ;
	REQUEST.id_tblrequests+"'"
lr=omed.sqlexecute(c_sql)

*--12/6/16: delete scanlook table rows if first look status
c_sql="exec dbo.getmasterbyrt " + ALLTRIM(STR(pn_lrsno))
lr=omed.sqlexecute(c_sql,"master")
cClcode = ALLTRIM(MASTER.cl_Code)
IF lFirstlook
	c_sql="update tblscanlook set active = 0,deleted=getdate(),deletedby='"+suser+ "' where cl_code='&cClcode.' and tag="+ALLTRIM(STR(pn_tag))
	lr=omed.sqlexecute(c_sql)
ENDIF

*--update tbldistodo tablesand send notification(s) that records have been changed
dsinsert("D1","","")


*--1/26/22: remove web copies of record before removing RSS images. [262821]
*!*	*-- 5/24/17: remove web copy of file from rtwebapp
*!*	cWebpath=ADDBS(MLPriPro("R", "RTS.INI", "Data","WebImageBasePathNew", "\")) ;
*!*		+ IIF(lFirstlook,"rt-fl$\","rt-docs$\") ;
*!*		+ ADDBS(PADL(ALLTRIM(STR(pn_lrsno)),8,"0")) ;
*!*		+ ADDBS(PADL(ALLTRIM(STR(pn_tag)),3,"0")) + ;
*!*		+ "RT-"+PADL(ALLTRIM(STR(pn_lrsno)),8,"0")+"-"+PADL(ALLTRIM(STR(pn_tag)),3,"0")+".pdf"
*!*	IF FILE(cWebpath)
*!*		*08/04/2021 WY #246909 (make sure file delete does not throw an error)
*!*		IF AbleToDelete (cWebpath) = .f.
*!*			RETURN && can not delete try again later
*!*		ENDIF 
*!*		*ERASE (cWebpath)
*!*	ENDIF
*!*	*-- remove web copy of file from 14.70
*!*	cWebpath=ADDBS(MLPriPro("R", "RTS.INI", "Data","WebImageBasePath", "\")) ;
*!*		+ IIF(lFirstlook,"rt-fl\","rt-docs\") ;
*!*		+ ADDBS(PADL(ALLTRIM(STR(pn_lrsno)),8,"0")) ;
*!*		+ ADDBS(PADL(ALLTRIM(STR(pn_tag)),3,"0")) + ;
*!*		+ "RT-"+PADL(ALLTRIM(STR(pn_lrsno)),8,"0")+"-"+PADL(ALLTRIM(STR(pn_tag)),3,"0")+".pdf"
*!*	IF FILE(cWebpath)
*!*		*08/04/2021 WY #246909 (make sure the file delete does not throw an error)
*!*		IF AbleToDelete (cWebpath) = .f.
*!*			RETURN && can not delete try again later
*!*		ENDIF 
*!*		*ERASE (cWebpath)
*!*	ENDIF
*!*	*-- remove any PNG files from web (there is no rt-fl or rt-docs sub folder for png files)
*!*	IF lFirstlook
*!*		cWebpath = ""
*!*		cWebpath=ADDBS(MLPriPro("R", "RTS.INI", "Data","WebImagePngPath", "\")) ;
*!*			+ ADDBS(PADL(ALLTRIM(STR(pn_lrsno)),8,"0")) ;
*!*			+ ADDBS(PADL(ALLTRIM(STR(pn_tag)),3,"0"))
*!*		IF DIRECTORY(cWebpath)
*!*			n_files = ADIR( a_files, ADDBS(cWebpath)+"*.png")
*!*			loTherm=CREATEOBJECT("app.appfrmthermometer")
*!*			n_fcnt=0
*!*			FOR n_cnt = 1 TO n_files
*!*				loTherm.updatedisplay(n_cnt, n_files, ;
*!*					"Deleting first-look PNG files", "Deleted "+;
*!*					ALLTRIM(STR(n_cnt))+" from "+ALLTRIM(STR(n_files)))
*!*				c_file = a_files[n_cnt, 1]
*!*				IF FILE(ADDBS(cWebpath) + a_files[n_cnt, 1])
*!*					ERASE ADDBS(cWebpath) + a_files[n_cnt, 1]
*!*				ENDIF
*!*				n_fcnt=n_fcnt+1
*!*			ENDFOR
*!*			RELEASE loTherm
*!*			n_files = ADIR( a_files, ADDBS(cWebpath)+"*.*")
*!*			IF n_files = 0
*!*				RMDIR cWebpath
*!*			ENDIF
*!*		ENDIF
*!*	ENDIF
*!*	dsinsert("D1","","")
*!*	c_sql="update pdf_ocr..tbljob set dtdeleted=getdate() where srt="+ALLTRIM(STR(pn_lrsno))+ ;
*!*		" and ntag="+ALLTRIM(STR(pn_tag))+" and dtdeleted is null"
*!*	lr=omed.sqlexecute(c_sql)
*!*	c_sql="update pdf_ocr..tblrecord set dtdeleted=getdate() where srt="+ALLTRIM(STR(pn_lrsno))+ ;
*!*		" and ntag="+ALLTRIM(STR(pn_tag))+" and dtdeleted is null"
*!*	lr=omed.sqlexecute(c_sql)

*// reset bates if possible
IF NOT USED('MASTER')
	c_sql="exec dbo.getmasterbyrt " + ALLTRIM(STR(pn_lrsno))
	lr=omed.sqlexecute(c_sql,"master")
	cClcode = ALLTRIM(MASTER.cl_Code)
ENDIF

*--6/22/17: accomodate automated bates tags. try to reset bates aoutobates tags before calling frmresetbates
LOCAL bAutoBates
bAutoBates = .F.
c_sql = "exec [dbo].[ResetAutoBates] " + ALLTRIM(STR(pn_lrsno))+","+ALLTRIM(STR(pn_tag))+",'"+ALLTRIM(suser)+"'"
omed.sqlexecute(c_sql,'curChkit')
IF USED('curChkit')
	bAutoBates=NVL(curChkit.EXP,.F.)
	USE IN curChkit
ENDIF
IF bAutoBates = .F.
	obates=CREATEOBJECT("case.frmresetbates",MASTER.ID_TBLMASTER, MASTER.cl_Code,"AR")
ENDIF

RELEASE obates

*ENDIF
*!*	IF (NVL(REQUEST.first_look,.F.) AND NVL(REQUEST.distribute,.F.) AND ;
*!*			gfmessage('Tag '+ALLTRIM(STR(pn_lrsno))+"."+ALLTRIM(STR(pn_tag))+' is released from first-look!'+CHR(13)+;
*!*			'Reset to "Wait" status?',.T.)) ;
*!*			OR ((NVL(REQUEST.first_look,.F.) AND NVL(REQUEST.distribute,.F.))=.F. AND ;
*!*			gfmessage('Reset tag '+ALLTRIM(STR(pn_lrsno))+"."+ALLTRIM(STR(pn_tag))+' to "Wait" status?',.T.))

IF gfmessage('Reset tag '+ALLTRIM(STR(pn_lrsno))+"."+ALLTRIM(STR(pn_tag))+' to "Wait" status?',.T.)

*gfmessage(PADC('Reset tag '+ALLTRIM(STR(pn_lrsno))+"."+ALLTRIM(STR(pn_tag))+' to "Wait" status?',43)+CHR(13)+;
*"(Note: Associated Soft-Copy job is deleted)",.T.) AND ;

	lreset=.T.
	WAIT WINDOW "Resetting status of tag:"+ALLTRIM(STR(pn_lrsno))+"."+ALLTRIM(STR(pn_tag)) NOWAIT NOCLEAR

	c_sql="select * from tbltimesheet with (nolock)" + ;
		" where cl_code='&cClcode.' and tag="+ALLTRIM(STR(pn_tag))+" and txn_code in (41) and (deleted is null  or active = 1)"
	lr=omed.sqlexecute(c_sql,'viewTimeSheet41')

	c_sql="select * from tbltimesheet with (nolock)" + ;
		" where cl_code='&cClcode.' and tag="+ALLTRIM(STR(pn_tag))+" and txn_code in (1) and (deleted is null  or active = 1)"
	lr=omed.sqlexecute(c_sql,'viewTimeSheet1')

	c_sql="select * from tblflentry with (nolock)" + ;
		" where cl_code='&cClcode.' and tag="+ALLTRIM(STR(pn_tag))+" and txn_code in (41) and (deleted is null  or active = 1)"
	lr=omed.sqlexecute(c_sql,'viewFlentry41')


*-------------  Flentry  ------------------------
	c_sql="update tblflentry set active=0,deleted=getdate(),deletedby='"+suser+"' "+;
		" where cl_code='&cClcode.' and tag="+ALLTRIM(STR(pn_tag))+" and (deleted is null  or active = 1)"
	lr=omed.sqlexecute(c_sql)

*-------------  Timesheet  ------------------------
	c_sql="update tbltimesheet set active=0,deleted=getdate(),deletedby='"+suser+"' "+;
		" where cl_code='&cClcode.' and tag="+ALLTRIM(STR(pn_tag))+;
		" and txn_code in (1,41,53,88,10,16,20) and (deleted is null  or active = 1)"

	lr=omed.sqlexecute(c_sql)

	c_sql = "update tbltimesheet set active=0,deleted = getdate(), deletedby = '"+suser+"' " +;
		" where cl_code='&cClcode.' and tag=" + ALLTRIM(STR(pn_tag)) + ;
		" and txn_code = 12 and descript= 'Scanning hold' and (deleted is null  or active = 1)"

	lr=omed.sqlexecute(c_sql)

*-------------  Disttodo  ------------------------
	c_sql="update tbldisttodo set rem_date=getdate(), rem_by= '" + suser + "' where lrs_no = " + ALLTRIM(STR(pn_lrsno)) + " and tag = " + ALLTRIM(STR(pn_tag)) + " and rem_date is null"

	lr=omed.sqlexecute(c_sql)

*-------------  Request  ------------------------
	c_sql="update tblrequest set status='W',redacted=0,distribute=0,nrs=0,nrs_code='', fin_Date=null " +;
		" ,scanned=0, scan_date=null, scan_pages=0, scan_table='', pages=0,datedlv_88=null,datedue_88=null,inc=0 " +;
		" ,hstatus='', hnrs=0, hnrs_code='', hinc=0, hqual='', edited=getdate(), editedby='"+suser+"' " +;
		" where cl_code='&cClcode.' and tag="+ALLTRIM(STR(pn_tag))+" and active=1"
	lr=omed.sqlexecute(c_sql)

*-------------  code41  ------------------------
	IF RECCOUNT('viewTimeSheet41')>1
		c_sql="UPDATE tblcode41 set active=0, deleted='"+TTOC(DATETIME())+"',"+;
			"deletedby='"+suser+"' "+;
			"WHERE id_tbltimesheet='"+viewTimeSheet41.id_tblTimeSheet+"' and (deleted is null  or active = 1)"
		lr=omed.sqlexecute(c_sql)
	ENDIF

*--5/29/14 accomodate hidden FL txn 41
	IF RECCOUNT('viewFlentry41')>1
		c_sql="UPDATE tblcode41 set active=0, deleted='"+TTOC(DATETIME())+"',"+;
			"deletedby='"+suser+"' "+;
			"WHERE id_tbltimesheet='"+viewFlentry41.id_tblflentry+"' and (deleted is null  or active = 1)"
		lr=omed.sqlexecute(c_sql)
	ENDIF

*-------------  comment  ------------------------
	IF RECCOUNT('viewTimeSheet1')>1
		c_sql="UPDATE tblcomment set active=0, deleted='"+TTOC(DATETIME())+"',"+;
			"deletedby='"+suser+"' "+;
			"WHERE id_tbltimesheet='"+viewTimeSheet1.id_tblTimeSheet+"' and (deleted is null  or active = 1)"
		lr=omed.sqlexecute(c_sql)
	ENDIF

*1/3/19: remove admission categories [123146]
*-------------  tbladmissn ------------------------
	c_sql="update recordtrak..tbladmissn set active=0, deleted = getdate(), deletedby = '"+suser+"' " +;
		"where cl_code='&cClcode.' and tag="+ALLTRIM(STR(pn_tag))+" and active=1"
	lr=omed.sqlexecute(c_sql)

*-------------  TagItem  ------------------------
	IF gfmessage("Delete the Soft-Copy job for tag "+ALLTRIM(STR(pn_lrsno))+"."+ALLTRIM(STR(pn_tag))+"?",.T.)
		c_sql="update tbltagitem set manualby='&suser.',dtmanual=getdate(),dropreason='&cReason.'"+;
			" where lrs_no="+ALLTRIM(STR(pn_lrsno))+" and tag="+ALLTRIM(STR(pn_tag))+" and doc_type in ('R','IR','N') and dtrssdone is not null"
	ELSE

		c_sql = "exec [dbo].[tagitemjobreset2] " + ALLTRIM(STR(pn_lrsno)) + "," + ALLTRIM(STR(pn_tag)) + ",'" + suser + "'"

*!*			c_sql="update tbltagitem set softcopy_done=null,scan_date=null,dtrssdone=null,REASSIGNED=NULL,reassignby=null,"+;
*!*				" sqauser=null,sqastatus=null,dtqaadd=null,dtqadone=null" +;
*!*				" where lrs_no="+ALLTRIM(STR(pn_lrsno))+" and tag="+ALLTRIM(STR(pn_tag))+" and doc_type in ('R','IR','N') and dtrssdone is not null"
	ENDIF

	lr=omed.sqlexecute(c_sql)


*--2/17/17: delete the first look images if there are any
	c_sql="exec dbo.getrequestbylrsno "+ALLTRIM(STR(pn_lrsno))+","+ALLTRIM(STR(pn_tag))
	lr=omed.sqlexecute(c_sql,'request')
	lFLcurrent=NVL(REQUEST.first_look,.F.) AND NOT NVL(REQUEST.distribute,.F.)

	IF NVL(lFLcurrent,.F.) <> NVL(lFirstlook,.F.)
		imgdelete(lFLcurrent, cReason)
		IF lFLcurrent
			c_sql="update tblscanlook set active = 0,deleted=getdate(),deletedby='"+suser+ "' where cl_code='&cClcode.' and tag="+ALLTRIM(STR(pn_tag))
			lr=omed.sqlexecute(c_sql)
		ENDIF
	ENDIF


ENDIF

*-- reset shipment(s) option
c_sql = "exec [dbo].[getGetShipCnt] " + ALLTRIM(STR(pn_lrsno)) + "," + ALLTRIM(STR(pn_tag))
lr=omed.sqlexecute(c_sql,"chkship")
IF RECCOUNT("chkship") >0
	IF gfmessage('Reset tag shipments for re-shipment?',.T.)
		SELECT chkship
		SCAN
			c_sql = "exec dbo.reshipcd "  + ALLTRIM(STR(pn_lrsno)) + "," + ALLTRIM(STR(pn_tag)) + ;
				",'" + fixquote(ALLTRIM(chkship.at_code)) + "','" + suser + "'"
			lr=omed.sqlexecute(c_sql)
		ENDSCAN
	ENDIF
ENDIF
IF USED("chkship")
	USE IN chkship
ENDIF

addmemo("Images deleted"+IIF(lreset," and tag reset to wait status","")+;
	" by "+ ALLTRIM(suser)+": "+cReason)

gfmessage("Image deletion process complete")

IF USED("viewFlentry41")
	USE IN viewFlentry41
ENDIF


WAIT CLEAR

RELEASE oFSO,o_rt
****************************************************************************************
PROCEDURE imgdelete
LPARAMETERS lFlook,cdelreason
LOCAL oFSO,lcFilename
WAIT WINDOW "Deleting scanned images for tag:"+ALLTRIM(STR(pn_lrsno))+"."+ALLTRIM(STR(pn_tag)) NOWAIT NOCLEAR

oFSO = CREATEOBJ('Scripting.FileSystemObject')

c_base=IIF( lFlook,"w:\rt-fl","w:\rt-docs")

*delete tbldocument rows
c_sql="exec dbo.deletedocumentrows "+ALLTRIM(STR(pn_lrsno))+","+ALLTRIM(STR(pn_tag))+",";
	+IIF(lFlook,"1","0")+",'"+suser+"'"+",'"+cdelreason+"'"
lr=omed.sqlexecute(c_sql,'nrows')

*rename rss directory
cfoldname=ADDBS(c_base)+ADDBS(PADL(ALLTRIM(STR(pn_lrsno)),8,"0"))+PADL(ALLTRIM(STR(pn_tag)),3,"0")

*delete thumb.db file if there is one
Delthumb(cfoldname)

cdelfoldname=ADDBS(c_base)+"deleted\"+ADDBS(PADL(ALLTRIM(STR(pn_lrsno)),8,"0"))+PADL(ALLTRIM(STR(pn_tag)),3,"0")

cqafoldname=ADDBS("w:\rt-stage")+ADDBS(PADL(ALLTRIM(STR(pn_lrsno)),8,"0"))+PADL(ALLTRIM(STR(pn_tag)),3,"0")

IF DIRECTORY(cdelfoldname)
	csavfoldname=ADDBS(c_base)+"deleted\"+ADDBS(PADL(ALLTRIM(STR(pn_lrsno)),8,"0"))+;
		PADL(ALLTRIM(STR(pn_tag)),3,"0")+"_"+SYS(1)
	IF DIRECTORY(csavfoldname)
* if second delete of day, dump the earilier set of images that were  saved.
		oFSO.DeleteFolder(csavfoldname)
	ENDIF
	lmoved=lfmove(cdelfoldname,csavfoldname)
ENDIF

IF DIRECTORY(cfoldname) AND NOT DIRECTORY(cdelfoldname)
	*--6/7/19: need to create RT delete base folder for move command to work 
	csavbase=ADDBS(c_base)+"deleted\"+ADDBS(PADL(ALLTRIM(STR(pn_lrsno)),8,"0"))
	IF NOT DIRECTORY(csavbase) 
		MKDIR (csavbase)
	ENDIF
	lmoved=lfmove(cfoldname,cdelfoldname)
	IF NOT lmoved
		gfmessage("Error deleteting scanned images. Contact IT department.")
		RETURN
	ENDIF
ENDIF

IF DIRECTORY(cqafoldname)
	ERASE (ADDBS(cqafoldname)+"*.*")
	RD (cqafoldname)
ENDIF

*remove the first-look image processing directory
IF lFlook
	cflfoldname="T:\KOPFLook\"+ADDBS(PADL(ALLTRIM(STR(pn_lrsno)),8,"0"))+;
		PADL(ALLTRIM(STR(pn_tag)),8,"0")
	IF DIRECTORY(cflfoldname)
		oFSO.DeleteFolder(cflfoldname)
	ENDIF
ENDIF

RELEASE oFSO

*****************************************************************************************
PROCEDURE dsinsert
PARAMETERS ctype,catcode,cemail
*nr=sqlexecute(nc,c_sql,'viewdist')
LOCAL c_atcode,c_email,c_rectype,c_sql
c_atcode=catcode
c_email=cemail
c_ImageDb='WEJ1'
c_ImageDb2=''
c_rectype=ctype
n_Copies=0
n_Idval=0
n_priority=6

c_dsjobid=lfdsjobid()

c_sql="INSERT INTO tbldisttodo ( "+;
	"lrs_no, tag, at_code, email, imagedb1,"+;
	"imagedb2, enter_date, enter_time, rectype, Add_by,"+;
	"Copies, [Id],priority,active,job_id,created,proc_time,"+;
	"jobphase,produced,rem_by,rem_time,"+;
	"atmt_time,delay,on_hold,"+;
	"alerts,viewalerts,webalerts,not_ocr,pages"+;
	")"+;
	" VALUES ("+;
	ALLTRIM(STR(pn_lrsno))+;
	","+ALLTRIM(STR(pn_tag))+;
	",'"+c_atcode+"'"+;
	",'"+c_email+"'"+;
	",'"+c_ImageDb+"'"+;
	",'"+c_ImageDb2+"'"+;
	",GETDATE()"+;
	",CONVERT(CHAR(8),GETDATE(),114)"+;
	",'"+c_rectype+"'"+;
	",'"+suser+"'"+;
	","+ALLTRIM(STR(n_Copies))+;
	","+ALLTRIM(STR(n_Idval))+;
	","+ALLTRIM(STR(n_priority))+;
	",1"+;
	",'"+c_dsjobid+"'"+;
	",GETDATE()"+;
	",'','',0,'','','',0,0,0,0,0,0,0"+;
	")"
lr=omed.sqlexecute(c_sql)


****************************************************************
FUNCTION lfdsjobid
LOCAL n_Curarea, n_jobnum, c_Prefix, l_distid
n_Curarea = SELECT()

l_distid=.T.
IF NOT USED("distid")
	USE T:\VFPFree\GLOBAL\distid IN 0
*!*		c_path=dbf_use('data','GLOBAL','rts.ini')
*!*		USE (ADDBS(c_path)+'distid') IN 0
	l_distid=.F.
ENDIF

SELECT distid

GOTO TOP
DO WHILE NOT RLOCK()
ENDDO
DO WHILE FLAG
ENDDO
REPLACE FLAG WITH .T.
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
			gfmessage("Seek MIS help! Please do not continue!!")
			gfmessage( "DS Job ID overflow !!")
		ENDDO
	ENDIF
ELSE
	REPLACE distid.jobid_no WITH n_jobnum
ENDIF

REPLACE distid.FLAG WITH .F.
UNLOCK

IF NOT l_distid=.T.
	USE IN distid
ENDIF

SELECT (n_Curarea)

RETURN (c_Prefix + PADL(ALLTRIM(STR(n_jobnum)), 8, "0"))

****************************************************
FUNCTION lfmove
PARAMETERS cDirEx,c_dirnew

*--5/15/19: change to use kernal32 process for folder move to accomodate multiple file formats (TIFF and PDF) [87505]
n_files = ADIR( a_files, ADDBS(cDirEx)+"*.*")
MoveFile(cDirEx,c_dirnew)
n_files2 = ADIR( a_files, ADDBS(c_dirnew)+"*.*")
IF n_files=n_files2 AND n_files2>0
	RETURN .T.
ELSE
	RETURN .F.
ENDIF

*!*	IF NOT DIRECTORY(c_dirnew)
*!*		MKDIR &c_dirnew
*!*	ENDIF
*!*	LOCAL n_fcnt,n_files,n_cnt,c_FromPath,c_ToPath,c_file
*!*	n_files = ADIR( a_files, ADDBS(cDirEx)+"*.tif")
*!*	loTherm=CREATEOBJECT("app.appfrmthermometer")
*!*	n_fcnt=0
*!*	FOR n_cnt = 1 TO n_files
*!*		loTherm.updatedisplay(n_cnt, n_files, ;
*!*			"Saving current set of image files", "Copied "+;
*!*			ALLTRIM(STR(n_cnt))+" from "+ALLTRIM(STR(n_files)))
*!*		c_file = a_files[n_cnt, 1]
*!*		c_FromPath = ADDBS(cDirEx)
*!*		c_ToPath = ADDBS(c_dirnew)
*!*		IF NOT FILE(c_ToPath + c_file)
*!*			COPY FILE (c_FromPath + c_file) TO ;
*!*				(c_ToPath + c_file)
*!*			n_fcnt=n_fcnt+1
*!*		ENDIF
*!*	ENDFOR

*!*	IF n_fcnt=n_files AND n_files>0
*!*		ERASE (ADDBS(cDirEx)+"*.*")
*!*		RD (cDirEx)
*!*		RETURN .T.
*!*	ELSE
*!*		RETURN .F.
*!*	ENDIF

********************************************************************************
PROCEDURE addmemo
PARAMETERS cmemo,caction,nmemotype
LOCAL c_action
c_action=IIF(PCOUNT()<2,"NONE",caction)
n_memotype=IIF(PCOUNT()<3,1,nmemotype)

LOCAL ots AS medtimesheet OF timesheet
ots = CREATEOBJECT("medtimesheet")

LOCAL oCmts AS medcomment OF COMMENT
oCmts = CREATEOBJECT("medcomment")

LOCAL oMedr AS medrequest OF REQUEST
oMedr=CREATEOBJECT("medrequest")

WAIT WINDOW "Creating Transaction.  Please wait." NOWAIT NOCLEAR

m.comments=""

ots.getitem(NULL)
SELECT timesheet
SCATTER MEMVAR BLANK
m.id_tblrequests=REQUEST.id_tblrequests
m.txn_date = DATETIME()
m.comments = cmemo
m.CreatedBy = suser
m.created=DATETIME()
m.active = .T.
m.txn_code = 4
m.descript = REQUEST.DESCRIPT
m.cl_Code = REQUEST.cl_Code
m.mailid_no = REQUEST.mailid_no
m.tag = pn_tag

GATHER MEMO MEMVAR
ots.updatedata
lc_idtimesheet=medtimesheetupdateresults.id_tblTimeSheet

oCmts.getitem(NULL)
SELECT COMMENT
REPLACE DESCRIPT WITH m.descript, txn_date WITH DATETIME(), txn_code WITH 4, ;
	TAG WITH pn_tag, cl_Code WITH m.cl_Code, mailid_no WITH m.mailid_no, ;
	CreatedBy WITH suser, ;
	COMMENT WITH cmemo, ;
	id_tblTimeSheet WITH lc_idtimesheet, ;
	created WITH DATETIME(), ACTIVE WITH .T.,  retire WITH .F.
oCmts.updatedata

RELEASE oCmts,ots
oCmts=.NULL.
ots=.NULL.
WAIT CLEAR


********************************************************************************
PROCEDURE Delthumb
PARAMETERS cPAth
LOCAL oFs,lcFilename

lcFilename = ADDBS(cPAth) + "thumbs.db"

* Define constants for file attributes
#DEFINE FA_NORMAL 	0	&& Normal file. No attributes are set.
#DEFINE FA_READONLY  1	&& Read-only file.
#DEFINE FA_HIDDEN 	2	&& Hidden file.
#DEFINE FA_SYSTEM 	4	&& System file.
#DEFINE FA_ARCHIVE 	32	&& File has changed since last backup.

#DEFINE FA_VOLUME 	8 	&& Disk drive volume label. Attribute is read-only.
#DEFINE FA_DIRECTORY  16	&& Folder or directory. Attribute is read-only.
#DEFINE FA_ALIAS 	1024	&& Link or shortcut. Attribute is read-only.
#DEFINE FA_COMPRESSED 	2048	&& Compressed file. Attribute is read-only.

oFs = CREATEOBJECT("Scripting.FileSystemObject")
IF oFs.FileExists(lcFilename)
	oFile = oFs.GETFILE(lcFilename) && lcFile is the name of the file
* Flip hidden flag and delete
	oFile.ATTRIBUTES = BITXOR(oFile.ATTRIBUTES, FA_HIDDEN)
	oFs.DeleteFile(lcFilename)
ENDIF
RELEASE oFs


*08/04/2021 WY #246909 (make sure file delete does not throw an error)
FUNCTION AbleToDelete (tcFile as string) as boolean
	*caller already determined that the file exists, no need to make sure

	tcFile = ALLTRIM(tcFile)
	LOCAL llNoDice
	llNoDice = .f.
	TRY 
		DELETE FILE (tcFile)
	CATCH
		llNoDice = .t. && file must be open or security problem
	ENDTRY 	
	IF llNoDice
		gfmessage("Unable to delete." + CHR(13) + CHR(13) + ;
					"Image files are in use by yourself or another user." + CHR(13) + CHR(13) + ;
					"Try again later.")
		RETURN .f.
	ELSE
		RETURN .T.	
	ENDIF 	
ENDFUNC 

