LOCAL nl,otag,ogen,suser
pd_created=DATE()
suser=ALLTRIM(goApp.CurrentUser.orec.login)
SET DATASESSION TO goApp.tempmastercaseformreference.DATASESSIONID
pn_lrsno=IIF(TYPE('master.lrs_no')='C',VAL(master.lrs_no),master.lrs_no)
pc_clcode=MASTER.cl_code
pn_tag=0 && #42912
SET DATASESSION TO
ogen=CREATEOBJECT('medgeneric')
*--KDL 8/3/16: trap for user abort from tag selection screen and fix process flow
*IF TYPE('otag')="O"
otag=CREATEOBJECT("casedeponent.frmgettag",pc_clcode,.F.)
otag.show
TRY
	pn_tag=NVL(otag.xRetval,-1)
	otag.RELEASE
CATCH
	pn_tag = 0
ENDTRY
*ENDIF

IF pn_tag>0
	c_sql="exec dbo.getrequestbylrsno "+ALLTRIM(STR(pn_lrsno))+","+ALLTRIM(STR(pn_tag))
	nl=ogen.sqlexecute(c_sql,'tmprequest')
	IF INLIST(tmprequest.status,"T","C") 
		gfmessage("Record not issued or cancelled. Access to this option denied")
		RETURN
	ENDIF
	IF tmprequest.first_look=.T. and tmprequest.distribute=.t.
		gfmessage("First-look record has been released. Access to this option denied")
		RETURN
	ENDIF 
	IF tmprequest.first_look=.T.
		c_sql="select * from chon_rtfl..tbldocuments where ntag="+ALLTRIM(STR(pn_tag))+" AND "+;
			"npatientid=(select npatientid from chon_rtfl..tblpatients WHERE smrn="+ALLTRIM(STR(pn_lrsno))+")"
	ELSE
		c_sql="select * from chon_rts..tbldocuments where ntag="+ALLTRIM(STR(pn_tag))+" AND "+;
			"npatientid=(select npatientid from chon_rts..tblpatients WHERE smrn="+ALLTRIM(STR(pn_lrsno))+")"
	ENDIF
	nl=ogen.sqlexecute(c_sql,'viewimage')
	IF RECCOUNT('viewimage')>0
		gfmessage("Access to this option denied - Scanned images exist")
		RETURN
	ELSE
		IF gfmessage("Are you sure you want to reset tag "+ALLTRIM(STR(pn_tag))+" to wait status?",.t.)
			memotxn("J",.f.)
			c_sql="exec dbo.tagitemjobreset "+ALLTRIM(STR(pn_lrsno))+","+ALLTRIM(STR(pn_tag))+",'&suser.'"
			nl=ogen.sqlexecute(c_sql)
		ENDIF

	ENDIF
ELSE 
	gfmessage("No tag selected")	
ENDIF

