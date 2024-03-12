FUNCTION convertToNum
LPARAMETERS lxField
DO CASE    
   CASE TYPE("lxField")="N"
        lxField=NVL(lxField,0)
   CASE TYPE("lxField")="C"
        lxField=VAL(NVL(lxField,""))   
   CASE TYPE("lxField")="L"
        lxField=IIF(lxField=.T.,1,0)
   OTHERWISE 
        lxField=0
ENDCASE 
RETURN lxField
