**FUNCTION DepToPrint
PARAMETERS  cdeponame
LOCAL o_name as Object,  c_dname as String, c_depn as String, c_drname as String

STORE "" to c_dname, c_depn, c_drname
**05/21/2012- print deponent's name on a KOP cover page insted of txn 11 line ( per Alec)

*IF TYPE('pc_deptype')<>"C"
		IF NOT ISDIGIT( LEFT( ALLT( pc_mailid), 1))
			pc_deptype = LEFT( ALLT( pc_mailid), 1)
		ELSE
			pc_deptype = "D"
		ENDIF
*	ENDIF
**05/21/2012 -Add Dr. when needed
c_dname=ALLTRIM(cdeponame)
IF pc_deptype == "D"
	c_drname=gfdrformat(c_dname)
	c_depn = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
ELSE
	c_depn = ALLTRIM(c_dname)
ENDIF
RELEASE o_name


RETURN c_depn
