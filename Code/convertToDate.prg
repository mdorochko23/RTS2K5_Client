FUNCTION convertToDate
LPARAMETERS lxField
DO CASE    
   CASE TYPE("lxField")="D"
        lxField=NVL(lxField,{})
   CASE TYPE("lxField")="T"
        lxField=TTOD(NVL(lxField,{}))
   CASE TYPE("lxField")="C"
        lxField=ctod(NVL(lxField,{}))      
   OTHERWISE 
        lxField={}
ENDCASE 
RETURN lxField
