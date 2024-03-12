PROCEDURE AFaxRmd
	***************************************************************************
	** MD  07/11/07 - Modified to create c_mark as Litigation + userctrl.initials
	** EF  04/24/07 - Added a call to the rpslitdata 		
	** EF  04/09/07 - Added a Phone for Propulsid.
	** EF  03/20/07 - Added SpecMark and new Phone to the 'SQR' lit cases.
	** EF  12/27/05 - Switched to SQL
	***************************************************************************
	** DMA 08/18/04 - Use long plaintiff name
	** EF  08/04/04 - Make it return to a current 'Set Procedure'
	** EF  05/16/03 - Add an ATTN line for all requests
	** EF  05/13/03 - Add call for gfgetatt()
	** EF  04/23/03 - Autofax Reminder Letter
	***************************************************************************
	* Called from: subp_pa
	* Calls: gfGetatt, ta_lib, gfMailN, gfLkUp
	*****************************************************************************
	PARAMETERS lcLrs, lnTag, lcRequest, mv, lcClass, lcFaxno, lc_Attn
	PRIVATE lc_Alias, lc_Office, lcCaseName, lcAddr1, lcAddr2, ;
		lcCity, lcSt, lcZip, lcCurproc, c_mailnam, c_mark, c_depname
	STORE "" TO lc_Alias, lc_Office, lcCaseName, lcAddr1, lcAddr2, lcCity, ;
		lcSt, lcZip, c_mark, c_depname
	lc_Alias = ALIAS()

	** deponent's fax number
	*IF getPub("pl_autofax")
	IF TYPE("pl_autofax")="P"
		lc_Faxno = "1" + STR( lcFaxno)
	ELSE
		c_fax    = STRTRAN( lcFaxno, " ", "")
		c_temp   = STRTRAN( c_fax, "-", "")
		c_temp2  = STRTRAN( c_temp, "(", "")
		lc_Faxno = STRTRAN( c_temp2, ")", "")
	ENDIF


	**  print an attn line
	IF EMPTY(lc_Attn)
		lc_Attn = gfGetAtt(pc_deptype)
	ENDIF
	c_mark=""
	
	** find an office
*!*			
*!*		DO CASE	   	    
*!*			CASE INLIST(pc_offcode, "P", "M", "G")
*!*				l_GetRps= Acdamnumber (pc_amgr_id)
*!*				 IF l_getrps
*!*					lc_Office= IIF(ISNULL(LitRps.RpsOffCode) or EMPTY(LitRps.RpsOffCode), 'P', LitRps.RpsOffCode)
*!*				    *c_mark= IIF(ISNULL(LitRps.RpsMark),'',LitRps.RpsMark)		    
*!*				 ENDIF			 
*!*				 c_mark=ALLTRIM(UPPER(NVL(pc_litcode,"")))+"."+ALLTRIM(UPPER(NVL(pc_Initials,"")))		 			
*!*			CASE pc_offcode = "C"
*!*				lc_Office = "C"
*!*				
*!*			CASE pc_offcode = "S"
*!*				lc_Office = "S"
*!*				
*!*			CASE pc_offcode = "T"
*!*				lc_Office = "T"			
*!*		ENDCASE
*!*		
 c_mark=ALLTRIM(UPPER(NVL(pc_litcode,"")))+"."+ALLTRIM(UPPER(NVL(pc_Initials,"")))	
	**08/21/2017: New ACD Lines #67249
lc_Office=RpsLoc()
**08/22/2017: New ACD Lines #67249
IF EMPTY(ALLTRIM(lc_Office))
	lc_Office=pc_Offcode
ENDIF
	
	
	
	
	** case name
	lcCaseName = "Re: " + pc_plnam

	** deponent's address
	SELECT pc_DepoFile
	lcAddr1 = ALLT(add1)
	lcAddr2 = ALLT( add2)
	lcCity =  City
	lcSt =    State
	lcZip =   Zip
	SET PROCEDURE TO ta_lib ADDITIVE
	** print a reminder letter
	DO PrintGroup WITH mv, "AFaxRmd"

	DO PrintField WITH mv, "Loc", lc_Office
	DO PrintField WITH mv, "SpecMark", c_mark
	DO PrintField WITH mv, "IssDate", DTOC( pd_reqdate)

	DO PrintField WITH mv, "InfoText", lcRequest

	DO PrintGroup WITH mv, "Control"
	DO PrintField WITH mv, "LrsNo", ALLT( STR( lcLrs))
	DO PrintField WITH mv, "Tag", STR( lnTag)
	DO PrintField WITH mv, "Date", DTOC( DATE())

	DO PrintGroup WITH mv, "Deponent"
	IF pc_deptype == "D"
		c_drname=gfdrformat( pc_descrpt)
		c_depname = IIF(NOT "DR."$c_drname,"DR. "+ALLTRIM(c_drname),c_drname)
	ELSE
		c_depname = ALLTRIM( pc_descrpt)
	ENDIF

	DO PrintField WITH mv, "Name", c_depname


	DO PrintField WITH mv, "Addr", IIF( EMPTY(lcAddr2), ;
		lcAddr1, szadd1 + CHR(13) + lcAddr2)
	DO PrintField WITH mv, "City", lcCity
	DO PrintField WITH mv, "State", lcSt
	DO PrintField WITH mv, "Zip", lcZip
	DO PrintField WITH mv, "Extra", IIF( EMPTY(lc_Attn), "",lc_Attn)

	DO PrintGroup WITH mv, "Plaintiff"

	DO PrintField WITH mv, "FirstName", pc_plnam
	DO PrintField WITH mv, "MidInitial", ""
	DO PrintField WITH mv, "LastName", ""
	DO PrintField WITH mv, "Addr1", pc_pladdr1
	DO PrintField WITH mv, "Addr2", pc_pladdr2
	IF TYPE('pd_pldob')<>"C"
		pd_pldob=DTOC(pd_pldob)
	ENDIF
	DO PrintField WITH mv, "BirthDate", pd_pldob
	DO PrintField WITH mv, "SSN", "###-##-" + RIGHT( ALLT( pc_plssn), 4)
	IF TYPE('pd_pldod')<>"C"
		pd_pldod=DTOC(pd_pldod)
	ENDIF
	DO PrintField WITH mv, "DeathDate",  pd_pldod
	DO PrintField WITH mv, "Extra", ;
		IIF( EMPTY( pc_maiden1), "", "A.K.A: " + pc_maiden1)

	gcCl_code = pc_clcode
	DO PrtEnQa IN ta_lib WITH mv, lcClass, "2", ALLTRIM( lc_Faxno)

	IF NOT EMPTY(lc_Alias)
		SELECT (lc_Alias)
	ENDIF
	RETURN
