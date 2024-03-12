***********************************************
**FUNCTION getdescript && update description of a tag
** 09/01/2015 - MD added check for lc_depart type and return blank if its not char
*****************************************************************************************
PARAMETERS lc_depart
LOCAL c_newdesc as String
c_newdesc =""

IF TYPE(" lc_depart")<>"C"
  	RETURN c_newdesc
ENDIF
  	
				DO CASE
				CASE lc_depart = "C"					
					c_newdesc = " (CATH)"
					
				CASE lc_depart = "E"
					
					c_newdesc = " (ECHO)"
					
				CASE lc_depart = "R"					
					c_newdesc =  " (RAD)"
			
				CASE lc_depart = "P"
					
					c_newdesc =  " (PATH)"
					
				CASE lc_depart = "B"
					
					c_newdesc =  " (BILL)"
					
				CASE lc_depart = "M"
					
					c_newdesc =  " (MED)"
					
				ENDCASE
				
			
	RETURN c_newdesc