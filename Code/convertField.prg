FUNCTION convertField
LPARAMETERS lxInField, lxOutField
DO CASE 
   CASE TYPE("lxInField")="C"
        lxOutField=convertToChar(lxOutField,1)
   CASE TYPE("lxInField")="N"
        lxOutField=convertToNum(lxOutField)
   CASE TYPE("lxInField")="D"
        lxOutField=convertToDate(lxOutField)
   CASE TYPE("lxInField")="T"
        lxOutField=convertToDate(lxOutField)
   CASE TYPE("lxInField")="L"
        lxOutField=convertToBool(lxOutField,2)
ENDCASE 
RETURN lxOutField
