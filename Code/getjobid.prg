***************************************************************************************************************************

PARAMETERS n_rtn, n_tagn
LOCAL nid as Integer,  omed_id AS OBJECT
omed_id= CREATEOBJECT("generic.medgeneric")
nid=0
c_sql=" EXEC [dbo].[qc_GET_sequence] '" + STR(n_rtn) +"','" + STR(n_tagn) +"'"

omed_id.sqlexecute(c_sql,"QcJob")
IF USED("QcJob") AND NOT EOF()
	nid=NVL(QcJob.qc_sequence,0)
endif
RELEASE omed_id
RETURN nid