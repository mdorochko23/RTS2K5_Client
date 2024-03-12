*** Getdef.prg - Get the default field passed
*** MD 11/01/2005 conevrted from DOS

parameters fldname,fldtype
private retfld,curfile
curfile = alias()
lcDefaults=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","KOP", "\")))+"Defaults.dbf"
IF !FILE(lcDefaults)
   gfMessage("Can't Open "+ALLTRIM(lcDefaults))
   QUIT 
ENDIF 
SELECT 0
USE &lcDefaults ALIAS defaults AGAIN   
retfld = ""
locate for alltrim(upper(fldname))==alltrim(upper(defaults.fieldname))
if found()
   do case
      case upper(fldtype) = "N"
         retfld = defaults.fieldn
      case upper(fldtype) = "L"
         retfld = defaults.fieldl
      otherwise
         retfld = defaults.fieldc
   endcase
endif

USE IN defaults
if not empty(curfile)
   select (curfile)
endif

return retfld
