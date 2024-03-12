PARAMETERS  c_clcode, n_tag, c_text, n_ID_tblSpec_ins, c_certs, n_mode
**n_mode =1 -only update last blurb
**n_mode =2 - all blurbs
PRIVATE C_STR as String, l_Upd as Boolean
LOCAL oMed AS Object
oMed=createobject("medgeneric")
STORE "" TO C_STR
l_Upd=.f.

IF n_mode =2

C_STR=" exec dbo.UpdSpecInstruction_All      '" + n_ID_tblSpec_ins + "','"  + fixquote(alltrim(c_text) )+ "','" + ;
 fixquote( c_clcode) + "','" + STR(n_tag) + "','"  + ALLTRIM(pc_UserID)  + "','" + ALLTRIM(c_certs) + "'"
ELSE
C_STR=" exec dbo.UpdSpecInstruction    '" + n_ID_tblSpec_ins + "','"  + fixquote(alltrim(c_text) )+ "','" + ;
 fixquote( c_clcode) + "','" + STR(n_tag) + "','"  + ALLTRIM(pc_UserID)  + "','" + ALLTRIM(c_certs) + "'"
ENDIF


l_Upd = oMed.sqlexecute( C_STR ,"")



RELEASE oMed
RETURN l_upd



