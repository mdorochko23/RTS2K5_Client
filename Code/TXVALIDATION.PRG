**Function TxValidation #60359
**TX-docs: 06/07/2017 TX courts issue need Bar# and email address for a RQ Atty
LOCAL c_rqat AS STRING, l_Cancel AS Boolean, l_nobar AS Boolean, l_noemail  AS Boolean, c_reason  AS STRING
c_rqat=""
 c_msg =""
**07/27/2017: Per new instruction on Asana's "Validate Attorney Email For Documents Message Modification" show a new msg for missing emails.
l_Cancel=.F. && assume we are ok to continue and check the rules below
STORE .F. TO l_nobar , l_noemail  && assume we have barno and email address
IF  !EMPTY(NVL(pc_rqatcod,''))
	c_rqat=pc_rqatcod

	DO CASE
	CASE  EMPTY(ALLTRIM(pc_barno))
		l_nobar=.T.
	CASE  EMPTY(TxRqemail(0,c_rqat))
		l_noemail =.T.
	ENDCASE

	DO CASE
	CASE  l_nobar=.T. AND l_noemail=.T.
		c_reason= "Email and Bar #"
		 c_msg =  "The " +  c_reason + " is missing and is required to issue this subpoena.  Please enter this information to proceed. "
	CASE  l_nobar=.T. AND l_noemail=.F.
		c_reason= "Bar #"
		 c_msg =  "The " +  c_reason + " is missing and is required to issue this subpoena.  Please enter this information to proceed. "
	CASE  l_nobar=.F. AND l_noemail=.T.
		c_reason="Email"
		c_msg="The Attorney Email for Documents is missing for atcode [" +c_rqat + "] and is required to issue this subpoena. Please enter this information to proceed. " 
	OTHERWISE
		 c_msg =""
		c_reason=""
		l_Cancel=.F.
	ENDCASE


	
	IF EMPTY(RqSignTX(c_rqat))
		c_reason= "Attorney's signature"
		 c_msg =  "The " +  c_reason + " is missing and is required to issue this subpoena.  Please enter this information to proceed. "
	ENDIF



	IF !EMPTY(ALLTRIM( c_reason))
		*gfmessage( "The " +  c_reason + " is missing and is required to issue this subpoena.  Please enter this information to proceed. " )
		gfmessage( c_msg )

		l_Cancel=.T.

	ENDIF
ENDIF

** check court's data as well 07/27/17


	IF !VldCourt(pC_COURT1)
		l_Cancel=.T.
	ENDIF






RETURN l_Cancel
