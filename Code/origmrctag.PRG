**FUNCTION OrigMrcTag
PARAMETERS c_lrs, ntag
_SCREEN.MOUSEPOINTER=11
PRIVATE OMED3 AS OBJECT
OMED3=CREATEOBJECT("generic.medgeneric")
SELECT 0
LOCAL n_mrcnum as Number
** chcek if the tasg os an original MRC tag
IF TYPE('c_lrs')="N"
c_lrs=STR(c_lrs)
endif
		omed3.closealias("MRCTag")
		omed3.sqlexecute("select dbo.ChkMRCtagTable('" + C_LRS  + "','" + STR(ntag) + "')", "MRCTag")
		n_mrcnum =0
		IF USED("MRCTag") AND NOT EOF()	
			n_mrcnum=NVL(MRCTag.exp,0)
		ENDIF
	RELEASE OMED3	
	_SCREEN.MOUSEPOINTER=0
RETURN n_mrcnum