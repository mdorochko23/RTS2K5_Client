PARAMETERS cclass2 as String, ctext as String,cAddr AS STRING, cclcode as String, ntag as Integer, cuserid as String
**EMAIL MNOTICE FOR A LIST OF ADDRESSES
LOCAL l_emaildone  as Boolean, c_addclass as String
c_addclass=""
l_emaildone =.t. 
c_alias=ALIAS()


**3/3/2011 added Risperdal/Pccp
	DO CASE 
	
	CASE pl_CambAsb	
		c_addclass='AsbCamb'
	CASE  pl_RisPccP
		c_addclass='Risp'
	OTHERWISE
		c_addclass="Email" && defaul email notice class
	ENDCASE
	
IF !USED("EmailAddr")
	l_emaildone 	=.f.
ELSE
	
	
SELECT EmailAddr
IF NOT EOF()
		
			SCAN 
				pc_EmailAdd=ALLTRIM(EmailAddr.EXP)
				cclass2 = IIF(EMPTY(ALLTRIM(pc_EmailAdd)),"Notice", c_addclass + "Not")	
				zclass=cclass2
				DO Job_Add WITH 1, 1, ctext, cAddr, cclcode, ntag, cuserid
			ENDSCAN
ELSE
	l_emaildone 	=.f.
	**removed msg below per ALec's request on 6.29.2011
	*gfmessage('No email address to email the notices has been found.')
ENDIF
ENDIF
			
IF NOT EMPTY(c_alias)
	SELECT (c_alias)
ENDIF

RETURN l_emaildone 		