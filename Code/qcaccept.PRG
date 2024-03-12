************************************************************************************************
** Accept Documents from a Web Order-AIP/QC system

************************************************************************************************
PARAMETERS c_BBWebNo
LOCAL lc_alias as String, lc_sql as string, ll_retval as Boolean
lc_alias =ALIAS()
_SCREEN.MOUSEPOINTER=11
PRIVATE OMED AS OBJECT
OMED=CREATEOBJECT("generic.medgeneric")

STORE "" TO   lc_alias , lc_sql

lc_alias =ALIAS()

SELECT ImgData
SCAN FOR accept 

lc_sql= " exec [dbo].[AcceptUploads2] '"+ ALLTRIM(STR(ImgData.ordnum))+"','" + ALLTRIM(STR( NVL(imgdata.uplseqid,0) )) + "','" + ALLTRIM(pc_Userid) + "'"
OMED.sqlexecute(Lc_sql,"")	

SELECT ImgData	
ll_retval =.t.


SELECT ImgData
ENDSCAN

RELEASE OMED

IF NOT EMPTY(lc_Alias)
SELECT (lc_Alias)
ENDIF
_SCREEN.MOUSEPOINTER=0
RETURN ll_retval 