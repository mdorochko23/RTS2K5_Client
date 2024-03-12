*******************************************************************
*** gfLkup.prg - A general popup routine to look up one field in a file
*** and return another field from file (such as description)
*** Works only on character fields
*** The limitation of smaller files has been removed.

** fname   = Name of the file to bring up
** retfld  = The field to be returned from the file
** fldname = The field to be looked up
** initval = The value of the field to be looked up

** Author: Hume

** 12/08/2005 MD modified for VFP

parameters fname,retfld,fldname,initval

LOCAL rettxt, lnCurArea, lc_initval

lnCurArea=SELECT()
LOCAL objgen as Object 
objgen=CREATEOBJECT("medgeneric")

lc_initval=""
do case
   case type('initval')="N"
      lc_initval=ALLTRIM(STR(initval,LEN(ALLTRIM(STR(initval)))+3,2))
   case type('initval')="L"
      lc_initval=IIF(initval=.T.,"1","0")
   case type('initval')="D" 
     lc_initval=DTOC(initval)
   case type('initval')="T"
     lc_initval=TTOC(initval)
   case type('initval')="Y" 
     lc_initval=ALLTRIM(STR(mton(initval),LEN(ALLTRIM(STR(initval)))+5,4))              
   CASE TYPE('initval')="C"
     lc_initval=ALLTRIM(initval)
ENDCASE

do case
   case type('retfld')="N"
      rettxt = 0
   case type('retfld')="L"
      rettxt = .F.
   case type('retfld')="D" OR type(retfld)="T"
      rettxt = {}
   CASE TYPE('retfld')="Y"
       retval=0.0000
   otherwise
      rettxt = ""
ENDCASE

lsSQLLine="Select ["+ALLTRIM(retfld)+"] as retval from "+ALLTRIM(fname)+" where "+ALLTRIM(fldname)+"='"+ALLTRIM(lc_initval)+"' and active=1"
objgen.sqlexecute(lsSQLLine,"viewtbl")
SELECT viewtbl
IF RECCOUNT()>0
   rettxt=viewtbl.retval
endif   
RELEASE objgen
SELECT(lnCurArea)

return rettxt
