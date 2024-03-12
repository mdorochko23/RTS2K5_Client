LPARAMETERS ln_type, lc_value,lc_hours
LOCAL lsUnits, lc_time
IF TYPE('lc_value')="C"
	lc_value=VAL(lc_value)
ENDIF


IF PCOUNT()>2
	IF TYPE('lc_hours')="C"
		lc_hours=VAL(lc_hours)
	ENDIF
	lc_value=lc_value+(60*lc_hours)
ENDIF
IF ln_type=1
	lsUnits=lc_value
	
	IF lsUnits>0
		lsUnits= ROUND(lsUnits/60,2)
	ENDIF

	lc_minutes= ALLTRIM(STR(lsUnits,4,2) )

	n_all =LEN(lc_minutes)
	n_beforedot=LEFT(lc_minutes, 1)
	n_afterdot=RIGHT(lc_minutes,1)


	DO CASE
	CASE  INLIST( n_afterdot, "1", "2", "3", "4", "5")
		lsUnits= SUBSTR(lc_minutes,1,n_all-1)+ "5"
	CASE INLIST(n_afterdot, "6", "7", "8", "9")
		lsUnits=ROUND(lsUnits,1)
	OTHERWISE
		lsUnits=ROUND(lsUnits,2)
	ENDCASE
ENDIF
IF TYPE ('lsUnits')="N"
 lsUnits=STR(lsUnits,4,2)
ENDIF


RETURN lsUnits
