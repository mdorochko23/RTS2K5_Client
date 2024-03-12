
PARAMETERS  lnTg, lcImgType
LOCAL  lcFile AS STRING, llRetaval AS Boolean
lcFile =""
llRetaval =.T.
lcFile =anyscans	(lnTg,lcImgType )
	IF EMPTY(ALLTRIM(lcFile ))	
		llRetaval  =.f.	
	ELSE
		llRetaval  =.T. && found images at pcx folders
	ENDIF


RETURN llRetaval
