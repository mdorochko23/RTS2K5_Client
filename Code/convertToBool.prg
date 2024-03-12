FUNCTION convertToBool 
LPARAMETERS lxField, lnSQLStyle
*  lnSQLStyle = 0 to convert to Y/N format
*  lnSQLStyle = 1 to convert to 0/1 format
*  lnSQLStyle = 2 to convert to .T./.F. format
DO CASE   
   CASE TYPE("lxField")="L"       
        lxField=IIF(lxField=.T.,lxField, .F.)           
   CASE TYPE("lxField")="N"
        lxField=NVL(lxField,0)
        lxField=IIF(lxField=1,.T., .F.)   
   CASE TYPE("lxField")="C"
        lxField=IIF(INLIST(NVL(lxField,""),"Y",".T.","T","1"),.T.,.F.)              
   OTHERWISE 
        lxField=.F.
ENDCASE 
DO CASE 
   CASE lnSQLStyle=0
        lxField=IIF(lxField=.T.,"Y","N")
   CASE lnSQLStyle=1
        lxField=IIF(lxField=.T.,1,0)     
ENDCASE         
RETURN lxField
