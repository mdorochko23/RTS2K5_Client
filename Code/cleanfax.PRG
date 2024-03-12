PARAMETERS c_faxnum
**7/14/09 remove all formating characters from a fax number 
LOCAL c_cleanfax as String
c_cleanfax=""
c_fax = STRTRAN( c_faxnum, " ", "")
				c_temp = STRTRAN( c_fax, "-", "")
				c_temp2 = STRTRAN( c_temp, "(", "")
				c_cleanfax = STRTRAN( c_temp2, ")", "")
			
RETURN c_cleanfax