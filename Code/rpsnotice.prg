*FUNCTION RpsNotice
PARAMETERS cRt, dDate 

LOCAL c_alias AS STRING, o_Not AS OBJECT, l_ok  as Byte
c_alias =ALIAS()
o_Not=CREATEOBJECT('medrequest')
o_Not.closealias("RpsList")


l_ok =.f.


c_sql="exec  [dbo].[RpsOrigNoticesList] '"+ cRt + "' , '" + DTOC(dDate ) + "'"
o_Not.sqlexecute(c_sql,"RpsList")
IF USED("RpsList")
	SELECT RpsList
	IF NOT EOF()
	SCAN 
	c_sql=""
	c_sql="exec dbo.ResubmitOrigNotices  '"  + STR(RpsList.JOBspecid) + "','" +ALLTRIM(pc_UserID)+ "'" 
	l_ok= o_Not.sqlexecute(c_sql,"")	
	
	SELECT RpsList
	ENDSCAN 
		
	ENDIF
ENDIF

RELEASE o_Not
IF NOT EMPTY(c_alias)
	SELECT (c_alias)
ENDIF

RETURN l_ok
