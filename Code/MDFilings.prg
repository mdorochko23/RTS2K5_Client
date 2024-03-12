FUNCTION  MDFilings
******************************************************************************************
** EF 04/8/15  Print the MD court set : cover page and notice of service
******************************************************************************************
PARAMETERS  &c_List, d_MDate
PRIVATE lc_Alias, ln_Ok, c_Order,  c_cov,	 c_Print, ll_Retval, c_serv
STORE "" TO c_Print,pc_BatchRq, c_cov, c_subs2,  c_serv

lc_Alias = ALIAS()
pl_PrtOrigSubp=.T.
oMed = CREATEOBJECT("generic.medgeneric")

pl_MdCourtset=.t.

	SELECT (c_List) 
	GO top
	IF EOF()
		gfmessage( "No tags to file. ")
		
		RETURN
	ENDIF
	
_SCREEN.MOUSEPOINTER=11
	SET PROCEDURE TO TA_LIB ADDITIVE
	PL_1ST_REQ=.F.
	l_Prt2Req=.F.
	pl_SkipBatchPRT=.T.
	pl_noticng=.T.
	pc_EmailAdd=""

	SELECT (c_List)
	INDEX ON STR(lrs_no) TAG RT ADDITIVE
	c_Order=" RT"
	SET ORDER TO &c_Order
	SCAN
	SCATTER memvar
		STORE "" TO  MV,  c_serv,  c_cov ,  c_Print
		gcCl_code =m.CL_CODE
		gntag =0
		ll_Retval = GetCase (m.CL_CODE  )
		IF ll_Retval   &&valid case
		    c_cov = mdfcov(d_MDate)
		    c_serv = mdservice(d_MDate) 		    
		    c_Print = c_cov + c_serv
		*  DO prtenqa WITH c_PrintJob , "KOPTest_IT", "1" , ""	
		ENDIF
		SELECT (c_List)
	ENDSCAN
	
	



_SCREEN.MOUSEPOINTER=0
IF USED(lc_Alias)
	SELECT (lc_Alias)
ENDIF
pl_MdSubset=.f.
RELEASE oMed
WAIT CLEAR
RETURN c_Print