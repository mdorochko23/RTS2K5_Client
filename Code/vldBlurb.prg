*FUNCTION vldBlurb
**07/07/17: TX work- 60359
PARAMETERS lcAType, lcQType
LOCAL c_msg as String
c_msg="" && assume we have affidavit and written questions on a blurb

	IF EMPTY(lcAType)
		c_msg="TX affidavit"		
	ENDIF

	IF EMPTY(lcQType)	
		c_msg="TX DWQ"			
	ENDIF

	
	RETURN IIF(!EMPTY(c_msg), "The selected blurb requires a " + c_msg + " for TX subpoena issue. Contact your manager to update. "  , "")
	