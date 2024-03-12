**FUNCTION txcourtcap
LOCAL c_alias as String,  l_OK as Boolean, mv_court AS String
c_alias =ALIAS()	
c_cty=fixquote(NVL(pc_c1Cnty,''))
 l_OK=.f.
mv_court=""
**12/14/2017: edited 2nd line #70136
**10/17/2017:  Judicial vs. County court
	Do PRINTFIELD With mv_court, "County", Upper(C_CTY)
	Do PRINTFIELD WITH mv_court, "Crttype", Alltrim(PC_TXCRTTYPE)
	
	IF ALLTRIM(PC_DISTRCT) = "."		&& 1/11/2023, ZD #300721, JH
		C_CAP2 = ""						&& 1/11
	ELSE
		Do Case
		Case ALLTRIM(PC_TXCRTTYPE)= "COUNTY"
			C_CAP2="AT LAW NO. " +   Upper(Allt( PC_DISTRCT)) + PC_SUFFIX
		Case ALLTRIM(PC_TXCRTTYPE)="DISTRICT"
			C_CAP2= Upper(Allt( PC_DISTRCT)) +   PC_SUFFIX +" JUDICIAL"  +" DISTRICT"
		Case ALLTRIM(PC_TXCRTTYPE)="PROBATE"		&& 8/9/2022, ZD #282566, JH
			C_CAP2= ""
		Otherwise
			C_CAP2="Not Programmed"
		ENDCASE
	ENDIF   
	Do PRINTFIELD With mv_court,"CaseDist",C_CAP2
	
	IF !EMPTY(ALLTRIM(c_cap2))
	 l_OK=.t.
	 ENDIF 
	
**10/17/2017:  Judicial vs. County court
 IF !EMPTY(c_alias)
SELECT (c_alias)
ENDIF 
RETURN mv_court
