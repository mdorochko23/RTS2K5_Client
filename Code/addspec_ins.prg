FUNCTION AddSpec_ins
**Called from the subp_pa.
			
PARAMETERS c_TSID, c_clcode,n_tag, c_descript, c_reqType, c_mid, c_dept, c_request
LOCAL l_specid as Boolean
LOCAL o_med as Object
*--d_today=DATE()
IF TYPE("pcPublicBlurb")!="C"
   pcPublicBlurb=""
ENDIF 
IF EMPTY(ALLTRIM(c_request)) 
   IF EMPTY(ALLTRIM(pcPublicBlurb))
      gfmessage("Blurb is missing.  Please notify IT department!")
   ELSE 
      c_request=ALLTRIM(pcPublicBlurb)
   ENDIF    
ENDIF    

o_med = CREATEOBJECT("generic.medgeneric")		
C_STR="Exec dbo.EditSpecIns  NULL " + ",'" + c_TSID	+ ;
					"', '" + fixquote(c_clcode) + "','" + STR(n_tag) + "','" + ;
					fixquote(c_request)+ "','"  + fixquote(c_descript) + "','" + ;
					DTOC(d_today) + "','" +  c_reqType + "'," + STR(1)+ ",'"  + ;
					c_mid + "','" + c_dept + "','" +	ALLTRIM(pc_CertTyp) + "','" +STR(0) + "','" + ;
					DTOC(d_today)+ "','" + pc_UserID + "'," +	STR(1) + "," + STR(0) + ",'" + "" + "'"

l_specid=o_med.sqlexecute(C_STR,"EditSp")


*!*	**06/07/13 -store blurb codes
*!*	IF !EMPTY(NVL(EditSp.id_tblspec_ins,""))
*!*		l_ok=blurbdetl (c_clcode, n_tag, pc_blurbcodes, EditSp.id_tblspec_ins)
*!*	endif
**06/07/13 -store blurb codes

RELEASE o_med
RETURN l_specid