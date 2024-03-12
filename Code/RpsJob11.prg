**FUNCTION  RpsJob11
PARAMETERS lccl, ntgreq,lddate
LOCAL n_RpsId AS INTEGER, lc_tsid AS STRING, l_ok AS Boolean
LOCAL oMed AS OBJECT
ots2 = CREATEOBJECT("generic.medgeneric")
calias=ALIAS()
lc_tsid=""
ots2.closealias('SeqID')

l_ok = ots2.sqlexecute("select [dbo].[MergeRpsJob] ('" + lccl+ "','" + STR(ntgreq) +"')", 'SeqID')

n_RpsId=0
IF USED('SeqID')
	SELECT SeqID
	IF NOT EOF()
		n_RpsId=NVL(SeqID.EXP,0)
	ENDIF
ENDIF


RELEASE ots2
IF !EMPTY(calias)
	SELECT (calias)
ENDIF
RETURN  n_RpsId
