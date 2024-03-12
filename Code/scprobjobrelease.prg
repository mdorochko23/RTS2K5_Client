
LOCAL o_rt,c_sql,nl
pn_lrsno=0
pn_tag=0
SET CLASSLIB TO depdisposition ADDIT
o_rt= CREATEOBJ("depdisposition.frmgetlrsandtag")
o_rt.SHOW

RELEASE o_rt

IF (pn_lrsno=0 OR pn_tag=0)
	gfmessage( "You must enter both Rt and Tag numbers...")
	RETURN
ELSE
	ort=CREATEOBJECT("generic.medgeneric")

	c_sql= "select * from tbltagitem i where i.lrs_no= " +ALLTRIM(STR(pn_lrsno)) + " and i.tag=" + ALLTRIM(STR(pn_tag)) + ;
		" AND I.PreProc_done is not null And I.softcopy_done is null " + ;
		" And I.dtmanual is null And I.scan_date is null And i.dtrssdone is null " + ;
		" And I.reassigned is not null and ISNULL(i.sjobuser,'') <>'' and i.deleted is null"
	ort.sqlexecute(c_sql,"viewitem")

	IF RECCOUNT("viewitem")>0
		SELECT viewitem
		SCAN
			IF gfmessage( "Problem job is reserved by: "+ ALLTRIM(viewitem.sjobuser)+". Release?",.T.)
				c_sql="update tbltagitem set sjobuser='' where nid= "+ viewitem.nid
				nl=ort.sqlexecute(c_sql,"viewitem")
				IF nl
					gfmessage("Reserved problem job released...")
				ENDIF
			ENDIF
		ENDSCAN
	ELSE
		gfmessage( "No reserved problem job found for tag:"+ALLTRIM(STR(pn_lrsno))+"."+ALLTRIM(STR(pn_tag)))
	ENDIF
	IF USED('viewitem')
		USE IN viewitem
	ENDIF
	RELEASE o_rt
ENDIF

