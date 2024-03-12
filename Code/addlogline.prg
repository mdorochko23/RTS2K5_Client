*********************************************************************************************
*PROCEDURE addlogline
*********************************************************************************************
PARAMETERS n_tg, c_spot, C_var
c_Temp = ADDBS(MLPriPro("R", "RTS.INI", "Data","JTEMP", "\")) + "TEMP\"
IF TYPE("n_tg") ="C"
C_TMP=c_Temp +ALLTRIM(PC_USERID) + ALLTRIM(STR(PN_LRSNO)) + "_" +ALLTRIM(n_tg) +".TXT"
ELSE
C_TMP=c_Temp +ALLTRIM(PC_USERID) + ALLTRIM(STR(PN_LRSNO)) + "_" +ALLTRIM(STR(n_tg)) +".TXT"
ENDIF




*!*	IF FILE (  C_TMP)
*!*		DELETE FILE (C_TMP)
*!*	ENDIF
STRTOFILE( CHR(10),C_TMP,1 )  && To write to file
IF TYPE("n_tg") ="C"
STRTOFILE(STR(PN_LRSNO) +"." + ALLTRIM(n_tg) + c_spot  +c_var,C_TMP,1)  && To write to file
ELSE
STRTOFILE(STR(PN_LRSNO) +"." + ALLTRIM(STR(n_tg)) + c_spot  +c_var,C_TMP,1)  && To write to file
ENDIF

RETURN
*********************************************************************************************