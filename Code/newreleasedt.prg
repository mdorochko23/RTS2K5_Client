*FUNCTION newreleasedt

PARAMETERS  ld_Maildate, ln_hold
LOCAL  ln_newRelease AS DATETIME
	IF ln_Hold<>0 AND PC_ISSTYPE='S' AND pl_1st_Req
		PD_RPSPRINT=GFCHKDAT(ld_Maildate+1, .F., .F.)
	ELSE
		PD_RPSPRINT=ld_Maildate
	ENDIF
