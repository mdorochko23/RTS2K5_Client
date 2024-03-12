PARAMETERS cRq_At_Code

LOCAL  l_found1 as Boolean, c_str as String, omed_nj as Object
STORE .f. to  l_found1
omed_nj=CREATEOBJECT("medgeneric")
omed_nj.closealias("NJatty")
*c_str="select dbo.GetNJAddrbyReqFirm ('" + cRq_At_Code + "')"
c_str="exec dbo.GetNJAddrbyReqFirmCode '" + cRq_At_Code +"'"
omed_nj.sqlexecute(c_str,"NJatty")
*c_njAtty =NVL(NJatty.exp,'')
*IF c_njAtty<>cRq_At_Code
IF NOT eof()

	*pl_GetAt = .F.
	*DO gfatinfo WITH c_njAtty, "M"
	
	pc_Aty1Ad = ALLTRIM( NjAtty.Add1)
	pc_Aty2Ad = ALLTRIM( njAtty.Add2)
	pc_AtState=ALLTRIM( njAtty.State)
	pc_Atycsz = ALLTRIM( njAtty.City) + ;
		", " + ALLTRIM( njAtty.State) + "  " + ALLTRIM( njAtty.Zip)
	l_found1=.T.
endif
release omed_nj

RETURN l_found1