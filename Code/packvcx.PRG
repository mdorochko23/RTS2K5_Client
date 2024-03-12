***************************************************************
* PROCEDURE Packs all VCX files.
***************************************************************
PARAMETER p_dir
PRIVATE   ALL LIKE l_*

SET CLASSLIB TO
CLOSE DATA ALL
CLEAR ALL
RELEASE ALL
CLEAR
SET TALK OFF

l_error = ON("ERROR")
l_safe  = SET("SAFETY")
SET RESO OFF
SET SAFE OFF
ON ERROR

DIME p_arr[1]
p_dir = IIF(PARAM()=0 OR EMPTY(p_dir),GETDIR(),p_dir)

IF EMPTY(p_dir)
	RETURN .F.
ENDIF

l_num = ADIR(l_dbfs,(p_dir+"*.vcx"))

FOR l_row = 1 TO l_num
  WAIT "Packing Library: "+l_dbfs[l_row,1] WIND NOWA
  *l_alias= LEFT(l_dbfs[l_row,1],(ATC('.',l_dbfs[l_row,1])-1))
  USE (p_dir+l_dbfs[l_row,1]) EXCLU
	PACK
ENDFOR

CLOSE DATA ALL
ON ERROR &l_error
SET SAFE &l_safe
WAIT CLEAR

RETURN

