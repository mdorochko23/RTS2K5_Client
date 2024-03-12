*****************************************************
** Delvelop report of Oakland fl delverables
*****************************************************
LOCAL dtdate,odate,l_continue
*!*	nc=SQLCONNECT('recordtrak')
SET CLASSLIB TO C:\rts2k5\client\Class\base additive
SET CLASSLIB TO C:\rts2k5\client\Class\app additive
SET CLASSLIB TO C:\rts2k5\client\Class\utility additive
odate=CREATEOBJECT ('utility.frmjustgetdate')
odate.CAPTION='Select Delivery Date'
odate.SHOW
l_continue=IIF(odate.exit_mode='SAVE',.T.,.F.)
dtdate=odate.d_date
odate.RELEASE
IF l_continue
	obmed=CREATEOBJECT('medgeneric')

*--3/8/16 by kdl: change field list per zendesk 34658
	c_sql="select m.lrs_no,r.tag,r.descript,r.fl_atty,r.pages ,r.datedlv_88,r.datedue_88 " +;
		"from tblrequest r with (nolock) " +;
		"join tblmaster m  with (nolock) on m.cl_code=r.cl_code " +; 
		"where r.cl_code in " +;
		"(select cl_code from tblmaster where lrs_nocode='C') "+;
		"and cast(convert(char(10),datedlv_88,101) as datetime)=cast('"+DTOC(dtdate)+"' as datetime) and r.active=1 and m.active=1"
	
*!*		c_sql="select r.*,m.lrs_no from tblrequest r "+;
*!*			"join tblmaster m on m.cl_code=r.cl_code "+;
*!*			"where r.cl_code in " +;
*!*			"(select cl_code from tblmaster where lrs_nocode='C') "+;
*!*			"and cast(convert(char(10),datedlv_88,101) as datetime)=cast('"+DTOC(dtdate)+"' as datetime) and r.active=1 and m.active=1"

	lr=obmed.sqlexecute(c_sql,'oaktags')
	IF RECCOUNT('oaktags')>0
		SELECT oaktags
		INDEX ON STR(lrs_no)+STR(TAG) TAG LRS_TAG
		SET ORDER TO LRS_TAG IN oaktags
		oRep=CREATEOBJECT("app.rt_frm_repoutput","Oakland_FirstLook", ;
			"First Look Tags: Delivery date"+DTOC(dtdate), "oaktags")
		oRep.SHOW
	ELSE
		gfmessage("No Oakland first-look deliveries found since selected date")
	ENDIF
ENDIF
IF USED('oaktags')
	USE IN oaktags
ENDIF 
