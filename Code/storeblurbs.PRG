***********************************************************************************
FUNCTION storeblurbs
PARAMETERS n_header, n_jobid, n_rt, n_tg, c_blurb
LOCAL o_medExc4 AS OBJECT
** store blurbs from the excel column - blurbs are like B01;B02;M02;E03 -max of 4 codes allowed.
o_medExc4=CREATEOBJECT("medgeneric")


LOCAL c_code AS STRING, c_retval as String
c_retval=""
nall=0

nall=LEN(ALLTRIM(c_blurb))
IF nall<>3  AND RIGHT(c_blurb,1)<>";"
	c_blurb= c_blurb + ";"
ENDIF
c_blurb=STRTRAN(c_blurb, " ",'')
FOR icnt=1 TO nall
	STORE "" TO c_code
	STORE 0 TO n_div, n_div2, n_cut
	


	IF icnt=1
		n_div =AT(";",c_blurb,1)
		n_div2 =AT(";",c_blurb,2)
		c_code  =UPPER(ALLTRIM(SUBSTRC(c_blurb, 1, n_div-1 )))
		IF nall=3 
			c_code=c_blurb && IN CASE USER FOGROT TO PUT ; AT THE END OF A BLURBCODE
		ENDIF
	ELSE
		n_div =AT(";",c_blurb,icnt-1) +1
		n_div2 =AT(";",c_blurb,icnt)
		n_cut=IIF(n_div2=0, nall, n_div2) -n_div
		c_code  =UPPER(ALLTRIM(SUBSTRC(c_blurb, n_div,n_cut )))
	ENDIF
	
	
	IF EMPTY(c_code) 
		EXIT
	*ELSE
		*c_retval=c_retval+'; ' + c_code
	ENDIF

	
	lc_sql ="Insert into tblQCExcelBlurbData  (id_w2header, id_w2location, Lrs_No, tag, BlurbCode, CreatedBy,Created , active) Values('"  ;
			+ STR(n_header)+ "','" + STR(n_jobid) +  "' ,'" + STR( n_rt) + "','" + STR(n_tg) + "','" + c_code + "','QcExcel','"  + DTOC(DATETIME()) + "',1)"
*!*			PN_LRSNO=n_rt
*!*			DO addlogline  WITH  0 , Lc_sql, " _STEP3EXCL"	
	o_medExc4.SQLEXECUTE( lc_sql,"")

	IF n_div2=0
		EXIT
	ENDIF

NEXT

RELEASE o_medExc4
RETURN c_code
*RETURN c_retval
