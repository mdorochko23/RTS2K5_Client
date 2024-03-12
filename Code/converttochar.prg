FUNCTION convertToChar
LPARAMETERS lxField, lnSQLStyle
*  lnSQLStyle = 0 to convert to Y/N format
*  lnSQLStyle = 1 to convert to 0/1 format
*  lnSQLStyle = 2 to convert to .T./.F. format

DO CASE 
   CASE TYPE("lxField")="C"
        lxField=ALLTRIM(NVL(lxField,""))
   CASE TYPE("lxField")="N"
        lxField=ALLTRIM(STR(NVL(lxField,0)))
   CASE TYPE("lxField")="D"
        lxField=dtoc(NVL(lxField,{}))
   CASE TYPE("lxField")="T"
        lxField=ttoc(NVL(lxField,{}))
   CASE TYPE("lxField")="L"
        DO CASE 
           CASE lnSQLStyle=0
                lxField=IIF(lxField=.T.,"Y", "N")
           CASE lnSQLStyle=1
                lxField=IIF(lxField=.T.,"1", "2")  
           CASE lnSQLStyle=2
                lxField=IIF(lxField=.T.,"T", "F")  
           OTHERWISE 
                lxField=IIF(lxField=.T.,"Y", "N")                           
         ENDCASE         
   OTHERWISE 
        lxField=""
ENDCASE 
RETURN lxField
