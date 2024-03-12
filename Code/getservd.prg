
PARAMETERS dIssdate as Date, l_HandSrv as Boolean

PRIVATE  d_servdate as date, c_alias as string
IF l_HandSrv 
	d_ServDate =gfChkDat(dIssdate +5,.f.,.f.)
	
ELSE
	d_ServDate =gfChkDat(dIssdate +10,.f.,.f.)
	
ENDIF

RETURN d_servdate