**FUNCTION ReleaseQCJob
**06/01/2011 -added pl_QCLCase: New Litigation Order
**08/26/2010 - ADDED CASES: pl_QCWCase - default status for these is PQ till case is released for a "Ready to Qc Tags".
PARAMETERS n_SelectOpt, n_qcsequence, n_weborder
LOCAL omed_res as Object, l_lok as Boolean, c_sql as String,  c_oldStatus as String
l_lok=.f.
omed_res=CREATEOBJECT("medmaster")


c_oldStatus=""
c_sql=""		
			
			DO CASE
			CASE n_SelectOpt=2
			**10/06/2011- if a research is off but a tag is not issued when exit the QC move 
			** a job to ISSSUE queue
			 c_oldStatus=IIF( pl_Resrch  ,'RQ','TQ')
			CASE n_SelectOpt=3
			 c_oldStatus='CQ'
			CASE n_SelectOpt=4
			 c_oldStatus='JQ'
			 CASE n_SelectOpt=5
			 c_oldStatus='TQ'
			 CASE n_SelectOpt=7
			 *-- confirmation queue &&04/17/2019 md #131697
			 c_oldStatus='VQ'
			 CASE n_SelectOpt=8
			 *-- Draft queue -- 08/18/2020 MD #181270
			 c_oldStatus='DQ'
			OTHERWISE			 
			 
			c_oldStatus= IIF(pl_QCWCase OR pl_QCLCase, 'PQ','')
			ENDCASE
			


	
IF pl_QCWCase OR pl_QCLCase
	LOCAL cOrdType as String
	IF pl_QCLCase
		cOrdType="L"
	ELSE
		cOrdType="C"
	endif
	
	c_sql="  exec [dbo].[qc_UpdateQCJobsStatus]  'PQ','"+ cOrdType + "','QQ', '" +  STR(n_weborder) + "', 'P'"
	l_lok=omed_res.SQLEXECUTE( c_sql,"")
	
ELSE
	c_sql=" exec dbo.QC_StatusUpdate '','" + STR(n_qcsequence) + "', '" + c_oldStatus + "'"
	l_lok=omed_res.SQLEXECUTE( c_sql,"")
endif			
			
RELEASE omed_res		
RETURN l_lok