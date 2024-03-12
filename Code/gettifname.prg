FUNCTION gettifname

suspend
lcfile =alltrim(STR(pn_lrsNo))+"A*."+PADL(ALLTRIM(STR(ntag)), 3, "0")
n_Files = ADIR(a_files, F_pcx +ALLTRIM(UPPER(lcFile)))
IF n_Files > 0
	=ASORT(a_files)		
	n_Lastnum1 =getnumber(a_files(ALEN(a_files,1), 1), LEN(ALLTRIM(STR(pn_lrsNo))))	
ENDIF
c_newfile=alltrim(STR(pn_lrsNo))+"A"+ALLTRIM(STR(n_Lastnum1+1)) + "." + PADL(ALLTRIM(STR(ntag)), 3, "0")
RETURN

******************************************************************
FUNCTION getnumber
PARAMETER c_Document, n_Lencase
LOCAL n_Pos , c_Num
n_Pos = AT( ".", c_Document)
n_Lencase = n_Lencase + 2
c_num = SUBSTR(c_Document, n_Lencase, n_Pos - n_Lencase)
RETURN VAL(c_num)
*******************************************************************

