PARAMETERS d_masterdate

LOCAL d_term as Datetime, c_retval as String
 c_retval =""
		DO CASE
*!*			CASE TYPE(d_masterdate)="D"
*!*				d_term=d_masterdate
		CASE TYPE("d_masterdate")="T"
			d_term=TTOD(d_masterdate)
		CASE TYPE("d_masterdate")="C"
			d_term=CTOD (d_masterdate)
		OTHERWISE
			d_term=d_masterdate
		ENDCASE

IF EMPTY( ALLTRIM(NVL(DTOC(d_term),''))) OR DTOC(d_term)="  /  /    "
 c_retval =""
ELSE
 c_retval =ALLTRIM( laMonth[MONTH(d_term)])+ ' '+ALLTRIM(STR( YEAR(d_term)))
ENDIF

RETURN  c_retval 



