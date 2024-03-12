
**7/14/09 -FUNCTION chkdubp
PARAMETERS csocsec, cdob, clit, cname_first,cname_last
PRIVATE omedtmp
omedtmp=CREATEOBJECT("medmaster")
c_today=DTOC(DATE())
LOCAL c_socsec, c_dob, n_select, c_rt
STORE "" TO c_socsec, c_dob, c_rt

	c_socsec=alltrim(NVL(csocsec,''))
	IF TYPE("cdob")="C"
		c_dob=alltrim(cdob)
	ELSE	
		c_dob=alltrim(DTOC(cdob))
	ENDIF
	IF EMPTY(c_socsec) AND EMPTY(c_dob)
		return
	ENDIF
	
	
	IF NOT EMPTY(c_socsec)
		n_select=SELECT()		
		c_SQL="SELECT lrs_no, soc_sec, plaintiff,brth_date as dob, name_last,name_first From " + ;
		" tblmaster WHERE ISNULL(soc_sec,'')='"+c_socsec+"' and litigation ='" + clit + "'  AND active=1"
		omedtmp.sqlexecute(c_SQL,"viewss1")			
	
		IF RECCOUNT('viewss1')>0 AND NVL(viewss1.soc_sec,'')=c_socsec
			c_rt =STR(viewss1.lrs_no)
		ENDIF
		SELECT (n_select)
	ELSE
	
	IF NOT EMPTY(c_dob) AND EMPTY(c_socsec)
		n_select=SELECT()		
		c_SQL="SELECT  lrs_no, soc_sec, plaintiff,brth_date as dob, name_last,name_first " + ;
		"  from tblmaster WHERE ISNULL(brth_date,'')='"+ c_dob  + ;		
		"' and litigation ='" + clit + ;
		"' and LTRIM(RTRIM(name_last))='" + alltrim(cname_last) + "' and  LTRIM(RTRIM(name_first))='" + alltrim(cname_first) + ;
		"'  AND active=1"
		omedtmp.sqlexecute(c_SQL,"viewdob")		
	
		IF RECCOUNT('viewdob')>0 AND NVL(DTOC(viewss.dob),'')=c_dob 
			c_rt =STR(viewss1.lrs_no)
		ENDIF
		SELECT (n_select)
		
	ENDIF
	endif
	RELEASE omedtmp
	RETURN ALLTRIM(c_rt)