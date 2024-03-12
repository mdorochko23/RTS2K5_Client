LOCAL c_Name AS STRING, l_GotSign AS Boolean, ln_Off AS INTEGER
c_Name=""
ln_Off=0

ln_Off = goApp.OpenForm("Issued.frmCAOffPick", "M")
DO CASE
	CASE ln_Off=1
		pc_offcode="C"
	CASE ln_Off=2
		pc_offcode="S"
	OTHERWISE
		RETURN

ENDCASE



oGenMed=CREATEOBJECT("medgeneric")
strsql="Select name_serv from tblMailPers with (nolock)  where " ;
	+ " Active =1 and  date_serv ='"  + DTOC(DATE()) + "' and officecode ='" + pc_offcode + "'"
l_GotSign = oGenMed.sqlexecute(strsql,"MailPers")
IF NOT l_GotSign
	RETURN
ENDIF

c_Name= MailPers.NAME_SERV

IF NOT EMPTY (c_Name)
	c_MailPers = c_Name
	gfmessage("Today's signer is " + ALLTRIM(PROPER(c_MailPers))+". ")
	RETURN
ENDIF
**default signers for each office

IF pc_offcode="C"
	c_MailPers  = "Dorothy Mays"         
&& added "Dorothy Mays" 1/5/17 #55914
ELSE
	c_MailPers  = "Joanne Vento"
ENDIF



c_Name=ALLTRIM(goApp.OpenForm("issued.frmcasigner", "M",c_MailPers,c_MailPers))
IF  EMPTY(c_Name)
	l_Upd=.f.
ELSE

strsql="Exec dbo.AddCASigner '" + c_Name + "','"+ ALLTRIM(pc_offcode)  + "','" + ALLTRIM(C_MEDUSER.LOGIN) + "'"

l_Upd = oGenMed.sqlexecute(strsql,"")
endif
IF NOT l_Upd
	gfmessage("Did not get a signer for today's documents.")
ELSE
	gfmessage("A courier's name has been assigned.")
ENDIF
RELEASE oGenMed
RETURN
