**FUNCTION bcbs

LOCAL c_text as String
c_text=""
c_text ="The information below must be included in the request language:" + CHR(13) + CHR(10) +  ;
			"1. Type of case (i.e.: malpractice, product liability, etc.) " + CHR(13) + CHR(10) + ;
			"2. Product involved, if any (i.e.: Zofran) " + CHR(13) + CHR(10) + ;
			"3. The injuries the member is claiming and/or the onset of those injuries " + CHR(13) + CHR(10) + ;
			"Send a Status to Counsel Letter if any item is missing. "
RETURN c_text 