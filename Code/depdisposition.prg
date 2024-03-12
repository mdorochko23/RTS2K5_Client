LPARAMETERS nlrs,ntag,o_frmdepsumm,l_autosoftcopy AS Boolean
LOCAL obmed,cur_area,loRequest,cfullname,lautosoftcopy
lautosoftcopy=IIF(PCOUNT()<4,.F.,l_autosoftcopy)
cur_area=SELECT()
obmed=CREATEOBJECT('medgeneric')
c_action="NONE"
IF NOT USED('master')
	nr=obmed.sqlexecute("exec dbo.getmasterbyrt "+STR(nlrs),'master')
ENDIF

nr=obmed.sqlexecute("exec dbo.getrequestbylrsno "+STR(nlrs)+","+STR(ntag),'request')

*// store the tbltagitem nid into tblrequest
IF "FRMSOFTCOPY" $ UPPER(o_frmdepsumm.name)
	REPLACE request.nid_tbltagitem WITH NVL(o_frmdepsumm.nid,"0")
ENDIF 

SCATTER NAME frmref_depsummary

pl_GotCase=.F.
DO gfgetcas
DO gfgetdep WITH REQUEST.cl_code,REQUEST.TAG
n_1lklvl = 0

IF NOT NVL(pl_ofcPas,.f.)
	DO FLincome IN flproc WITH n_1lklvl,o_frmdepsumm
ENDIF

IF n_1lklvl < 0                           && user has requested cancel from the 1st look screen
	RETURN (c_action)
ENDIF

*-- if not 1st look, or status is pre review and user does not select
*-- print 1st look documents option, then run incoming program.

IF NOT pl_autosc
	c_sql="select * from tbltagitem with (nolock) where lrs_no="+ALLTRIM(STR(pn_lrsno)) +" and tag="+ALLTRIM(STR(pn_tag))+;
		" and doc_type in ('R','IR') and deleted is null And active=1 " +;
		" and dtmanual is null and softcopy_done is null and isnull(sqastatus,'A')<>'R' and dtrssdone is null"

	nr=obmed.sqlexecute(c_sql,'viewjobs')

	IF RECCOUNT('viewjobs')>0
		gfmessage("There is an active soft-copy job for this tag. Record log in canceled.")	
		RETURN "CANCEL"
	ENDIF 
ENDIF 

IF n_1lklvl < 4

** Automatic re-open is required -- case should not have been closed
** unless all records had previously reached final disposition.
	IF NOT (EMPTY(convrtDate(pd_closing)))
		WAIT WINDOW "NOTE: Case is being automatically re-opened." NOWAIT NOCLEAR
		DO gfReOpen WITH .T., "logging in received item(s) for tag " + ;
			ALLT( STR( RECORD.TAG)) + "."
	ENDIF

	IF INLIST( frmref_depsummary.STATUS, "R", "N") OR ;
			INLIST( NVL(frmref_depsummary.hstatus,''), "R", "N")
*--	IF INLIST( request.Status, "R", "N")
		o_message = CREATEOBJECT('rts_message',"Request has already reached final disposition.")
		o_message.SHOW
		RELEASE o_message
		RETURN  (c_action)
	ENDIF

	IF INLIST( frmref_depsummary.STATUS, "T", "Q")
*--	IF INLIST( request.Status, "T", "Q")
		o_message = CREATEOBJECT('rts_message',"No record request has been issued to this deponent.")
		o_message.SHOW
		RELEASE o_message
		RETURN  (c_action)
	ENDIF

	IF NOT INLIST( frmref_depsummary.STATUS, "I", "W", "C", "F") ;
			AND NOT EMPTY ( NVL(frmref_depsummary.hstatus, ""))
*--	IF NOT INLIST( request.Status, "I", "W", "C", "F")
		o_message = CREATEOBJECT('rts_message',"Record request status not in 'outstanding' list.")
		o_message.SHOW
		RELEASE o_message
		RETURN  (c_action)
	ENDIF

*--Check for active 1 and 41 transactions
	c_sql="Select * From tblTimesheet WITH (NOLOCK) "+;
		"where cl_code='pc_clcode.' and tag="+STR(ntag)+" and txn_code in (1,41) "+;
		"and deleted is null and active=1"
	nr=obmed.sqlexecute(c_sql,'viewtime')
	IF RECCOUNT('viewtime')>0
		gfmessage('Either a 1 or 41 transaction already exists for this tag. Action cancelled.')
		RETURN  (c_action)
	ENDIF 			
	
*	IF NOT lautosoftcopy
		goApp.OpenForm("depdisposition.frmrecorddisposition", "", EVALUATE('Request.ID_tblrequests'),;
			EVALUATE('Request.ID_tblrequests'),n_1lklvl,;
			IIF(TYPE('master.lrs_no')='N',STR(MASTER.lrs_no),MASTER.lrs_no),cfullname,frmref_depsummary,lautosoftcopy,o_frmdepsumm)
*!*		ELSE
*!*			goApp.OpenForm("depdisposition.frmrecorddisposition", "S", EVALUATE('Request.ID_tblrequests'),;
*!*				EVALUATE('Request.ID_tblrequests'),n_1lklvl,;
*!*				IIF(TYPE('master.lrs_no')='N',STR(MASTER.lrs_no),MASTER.lrs_no),cfullname,frmref_depsummary,lautosoftcopy)
*!*		ENDIF
	c_action="UPDATE4"
ENDIF
WAIT CLEAR
RETURN (c_action)
