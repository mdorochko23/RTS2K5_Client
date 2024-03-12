
PARAMETERS  lcFile, cBatchNum, lNeedsreview, cImgFolder, cOffice
LOCAL c_CurArea AS STRING,  c_Default AS STRING, c_sql AS STRING, ;
	l_ok AS Boolean, n_id_tblw2header AS INTEGER, N_ORDERID AS INTEGER, ;
	C_EXTRADATA AS STRING, c_fax AS STRING, c_phone AS STRING, c_fax2 AS STRING, ;
	c_temp AS STRING, c_temp2 AS STRING,c_phone2 AS STRING, n_CurRT AS INTEGER, ;
	c_litruleres AS STRING, C_TEMPFILE AS STRING, c_path AS STRING, lc_locMID AS String, lc_Note AS String

STORE "" TO c_Default, c_CurArea, c_sql, C_EXTRADATA, c_litruleres, C_TEMPFILE,c_path , lc_Note
LOCAL omedExc3 AS OBJECT, c_SendTo AS STRING,c_CopyTo AS STRING, c_attachment AS STRING,;
	c_FromName AS STRING,c_FromEmail AS STRING, c_Subject AS STRING, c_bCCList AS AS STRING, c_DrLastN as String, c_DrFirstN as String
STORE .F. TO l_ok
N_ORDERID=0
c_CurArea=ALIAS()
omedExc3=CREATEOBJECT("medgeneric")

_SCREEN.MOUSEPOINTER= 11

IF NOT EMPTY(ALLTRIM(lcFile))
	*6/28/15-added 1000 for tag comemts
	*c_path=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","QCTemplExcel", "\"))) &&use as 9/11/2012- edired dr address to be 50 characters
	c_path=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","TemplExcel", "\"))) 
	IF USED('step1file')
		SELECT step1file
	ELSE
		USE (c_path+"E_GSKFile.dbf"  )  ALIAS step1file IN 0
	ENDIF
	

	IF USED ('TodoFile')
		SELECT TodoFile
		USE
	ENDIF
	IF USED ('casesToAdd')
		SELECT casesToAdd
		USE
	ENDIF

	lcFileName= "'"+ALLTRIM(lcFile)+"'"
	SELECT 0
	USE &lcFileName ALIAS TodoFile EXCLUSIVE
*!*			**03/23/2011 -EXCEL OUTPUT
	IF USED('TodoTags2')
		SELECT TodoTags2
		USE
	ENDIF
	SELECT TodoFile
	SELECT  TOP 1 *, 000 AS TagNum FROM TodoFile INTO CURSOR TodoTags2  READWRITE ORDER BY 1
	SELECT TodoTags2
	DELETE ALL
	DO Prepexcl &&*03/23/2011 -EXCEL OUTPUT



	SELECT TodoFile
	INDEX ON AY TAG Ulrs_no UNIQUE ADDITIVE

	GO TOP

	SCAN  
		n_CurRT=0
		n_CurRT=TodoFile.ay
		l_newcase=.F.
		d_needby =DTOC(TodoFile.aw)
		l_newcase =IIF(lNeedsreview,.T.,TodoFile.aZ)

		lc_sql ="" &&12/20/2010 ---- some cases may be still in a "New cases" queue -

		lc_sql =" exec [dbo].[qc_GetStatusofNewCase] '" +STR(TodoFile.aY)  +"'"
		omedExc3.SQLEXECUTE( lc_sql,"StillPQ")
		IF !EOF()
			IF NVL(StillPQ.casenum ,0)<>0
				l_newcase=.T. && if a case was not released from a PQ queue it is still considered a new one
			ENDIF
		ENDIF   &&12/20/2010 ---- some cases may be still in a "New cases" queue
**1- add a case to header plus newcases table
		IF d_needby='  /  /    '  OR TYPE(d_needby)<>"C"
			d_needby=''
		ENDIF
** if the same case add as the same web order #
		n_id_tblw2header=0
		lc_sql =""
**3/22/2011 - added RUSH as a C/T/N instead of logical on excel files


		lc_sql ="exec [dbo].[qc_LoadExcelW2HeaderNewCaseRecord]   '" + STR(TodoFile.aY) +"','"+ NVL(cBatchNum,'') + "','A','" + ;
			ALLTRIM(LEFT(fixquote(TodoFile.ac),200) )+  ' ' + FIXQUOTE(ALLTRIM(TodoFile.Av ))+ "','"  + ;
			IIF(l_newcase=.T.,'C','N') + "','" + TodoFile.AE + "','"  + ;
			FIXQUOTE(ALLTRIM(TodoFile.AH )) +"','" + FIXQUOTE(ALLTRIM(TodoFile.AG )) + ;
			"','" + FIXQUOTE(ALLTRIM(TodoFile.AI ))  + "'," + IIF(UPPER(TODOFILE.BD)="C", STR(1),STR(0)) + ;
			",'" + d_needby + "'"


		omedExc3.SQLEXECUTE( lc_sql,"NewId")
		IF NOT EOF()
			n_id_tblw2header=NVL(NewId.EXP,0)
			L_OK=.T.
		ELSE
			L_OK=.F.
		ENDIF

**********************01/06/2011 - add all tags for the same case as one web order
		SELECT *, 000 AS TagNum, 000000000 AS newlocid FROM todofile WHERE todofile.aY =n_CurRT INTO CURSOR TodoTags READWRITE

		SELECT TodoTags
		IF EOF()
			gfMessage("Adding tags from the Excel file has failed.")
			RETURN
		ENDIF

		GO TOP
		SCAN
			STORE "" TO c_fax , c_phone , c_fax2 , c_temp , c_temp2 ,c_phone2 , lc_sql, c_SendTo, ;
				c_CopyTo, c_FromName,c_FromEmail, c_Subject, lc_locMId, c_DrLastN, c_DrFirstN
	
			IF L_OK AND n_id_tblw2header<>0
**09/20/11-start using Mailid in BH column : call ExcLocbyMid  to get a deponent's name

				IF !EMPTY(ALLTRIM(NVL(TodoTags.F,'')))				
					c_location=ALLTRIM(TodoTags.F )+ IIF(!EMPTY( TodoTags.G), "(" + ALLTRIM( TodoTags.G) + " " + ALLTRIM( TodoTags.H)  + ")" , "")
				ELSE
				
					c_location = IIF(EMPTY(ALLTRIM(NVL(TodoTags.G,'')) ),'',"DR.") +ALLTRIM(NVL(TodoTags.G,'')) +  " " + ALLTRIM(NVL(TodoTags.H,''))
				ENDIF
				
				
				IF NOT EMPTY(NVL(TodoTags.BH,''))
					c_location=""
					** get a department by a blurb code ( multiple codes get "Z" dept)
					IF len(ALLTRIM(TodoTags.BG)) =3 OR 	len(ALLTRIM(TodoTags.BG)) =4			
						c_depart=deptbyblurb(left(ALLTRIM(TodoTags.BG),1))
					ELSE
						c_depart="Z"
					ENDIF
					
					lc_locMID=ExcLocbyMid (TodoTags.BH, c_depart) + " " 
				ENDIF
				
				lc_loc =FIXQUOTE( LEFT(lc_locMID+ c_location,50))
*!*						lc_loc =FIXQUOTE( LEFT(c_location,50))

**4 add locations
&&remove all extra characters from a phone/fax number

				IF !EMPTY(ALLTRIM(NVL(TodoTags.o,'')))&&fax
					c_fax2 = STRTRAN( ALLTRIM(TodoTags.o), " ", "")
					c_temp = STRTRAN( c_fax2, "-", "")
					c_temp2 = STRTRAN( c_temp, "(", "")
					c_fax = STRTRAN( c_temp2, ")", "")
				ENDIF
				IF !EMPTY(ALLTRIM(NVL(TodoTags.N,''))) && phone
					c_phone2 = STRTRAN(ALLTRIM(TodoTags.N), " ", "")
					c_temp = STRTRAN( c_phone2, "-", "")
					c_temp2 = STRTRAN( c_temp, "(", "")
					c_phone = STRTRAN( c_temp2, ")", "")
				ENDIF
				lc_sql =""				
				lc_sql =" exec [dbo].[qc_LoadExcelLocations2] '" + STR(n_id_tblw2header) + "','" + ;
					lc_loc + "','" +FIXQUOTE(ALLTRIM(NVL(TodoTags.i,''))) + "','" + FIXQUOTE(ALLTRIM(NVL(TodoTags.j,''))) + "','"  + ;
					FIXQUOTE(ALLTRIM(NVL(TodoTags.k,''))) +"','" + FIXQUOTE(ALLTRIM(NVL(TodoTags.l,'')))  + "','" + ;
					FIXQUOTE(ALLTRIM(NVL(TodoTags.m,''))) + "','" + c_phone + "','" + ;
					c_fax + "','" + FIXQUOTE(ALLTRIM(NVL(TodoTags.P,''))) + "','" + ;
					STR((NVL(TodoTags.ab,0))) + "','" +	;
					FIXQUOTE(ALLTRIM(NVL(LEFT(TodoTags.u,400),''))) + "','"  + NVL(TodoTags.BH,'') + "'"

				l_ok=omedExc3.SQLEXECUTE( lc_sql,"LocRecord")

				REPLACE newlocid WITH NVL(LocRecord.EXP,0) IN TodoTags
**5 Add additional attorneys


				IF !EMPTY (ALLTRIM(TodoTags.be))
					l_atty =attystoadd(n_id_tblw2header, ALLTRIM(TodoTags.be),.f.,  "", "", "", "","", "", "", "", "" )
				ENDIF
**5a Add indirect billing attorneys		
		IF !EMPTY (ALLTRIM(TodoTags.ad))
					l_atty =attystoadd(n_id_tblw2header, ALLTRIM(TodoTags.ad), .t., TODOFILE.AY, ;
					LEFT(ALLTRIM(TodoTags.ae),8), 	LEFT(ALLTRIM(TodoTags.af),20),LEFT(ALLTRIM(TodoTags.ag),20), ;
					LEFT(ALLTRIM(TodoTags.ah),16), LEFT(ALLTRIM(TodoTags.ai),20), 	;
					IIF(EMPTY(NVL(TodoTags.aj,{})),"",ALLTRIM(DTOC(TodoTags.aj))), ;
					LEFT(ALLTRIM(TodoTags.ak),16), LEFT(ALLTRIM(TodoTags.ap),50) )
								
						
				ENDIF					
		
				
			ENDIF
			SELECT TodoTags
		ENDSCAN
**6 final step- submit an order

		IF l_ok

			lc_sql =" exec dbo.qc_SubmitRTOrder  '" + 	STR(n_id_tblw2header)+ "'"
			omedExc3.SQLEXECUTE( lc_sql,"")

		ENDIF

		SELECT TodoTags	&& upadate newly created locations with an extra data
		GO TOP
		SCAN
		STORE "" TO c_DrLastN,c_DrFirstN
	
** 3/22/2011- added "T" for rush
**09/10/2012 -store DR names separatly
				c_DrLastN= ALLTRIM( TodoTags.H)
				c_DrFirstN= ALLTRIM( TodoTags.G)

			lc_sql="" 

			**06/01/2012- store med provider id as string
			
			lc_sql=" exec [dbo].[qc_UpdateQC_by_ExcelStep3] '" + FIXQUOTE(ALLTRIM(NVL(LEFT(TodoTags.P,3),''))) + "','"  + ;
				STR(NVL(TodoTags.ab,0),6,2) + "','" + ALLTRIM(LEFT(TodoTags.r,10)) + "','" +  ALLTRIM(LEFT(TodoTags.T,10)) + "','" +;
				ALLTRIM(pc_userid) + "',"  +  IIF(NVL(TodoTags.w,.F.)=.T., STR(1), STR(0))  +  "," + ;
				IIF(NVL(TodoTags.V,.F.)=.T., STR(1), STR(0)) + "," + IIF(NVL(TodoTags.Y,.F.)=.T., STR(1), STR(0)) + ",'" + ;
				fixquote(NVL(ALLTRIM(TodoTags.x),''))   + "','" +  fixquote(NVL(ALLTRIM(TodoTags.z),''))  + "'," + ;
				IIF(INLIST(UPPER(TodoTags.BD),"T","C"), STR(1),STR(0)) + ",'" +  STR(n_id_tblw2header) + "','" + ;
				STR(NVL(TodoTags.newlocid,0)) + "'"


			omedExc3.SQLEXECUTE( lc_sql,"")


**7) work on the images
			IF TYPE('n_id_tblw2header')="N"
				ll_imgDone =step4excl(n_id_tblw2header ,NVL(TodoTags.newlocid,0),  cImgFolder)
**03/28/2011 removed per Sarah/Alec , do not display a msg anymore.
*IF NOT ll_imgDone
*gfMessage("Images were not created.")
*ENDIF
			ELSE
				gfMessage("Wrong Order id type [n_id_tblw2header].")
			ENDIF

*** get tag number
			lc_sql=""
			lc_sql=" exec [dbo].[qc_GetTagExclStep4] '" +STR(n_id_tblw2header) + "','" + STR(NVL(TodoTags.newlocid,0)) + "'"

			omedExc3.SQLEXECUTE( lc_sql,"TagNum")

			REPLACE TagNum WITH TagNum.qc_tag IN todotags

			SELECT TodoTags
			SCATTER MEMVAR
			**test
			*DO STORETEST 
			***test
			lc_blcode=""
**6a Add blurbs
&& 08/17/2011- added blurbs to excel
			IF !EMPTY (ALLTRIM(TodoTags.bg))
				lc_blcode= storeblurbs (  n_id_tblw2header, TodoTags.newlocid, TodoTags.ay,TodoTags.TagNum, ALLTRIM(TodoTags.bg))

			ENDIF


****6b store extra qc_blurb when  needed
			lc_sql ="exec  [dbo].[qc_CombineBlurbsCerts_Excel2]'" + STR(n_id_tblw2header) + "','" ;
				+ STR(todotags.newlocid) + "','" + cOffice+ "','" + fixquote(ALLTRIM(TodoTags.u)) + "'"
			omedExc3.SQLEXECUTE( lc_sql,"")
			
****6c 10/11/2011 add extra tag's data to QC
		
			lc_Note=""
			lc_Note=FIXQUOTE(ALLTRIM(TodoTags.bi)) && tag comments
				lc_sql=""		
				lc_sql=" exec dbo.qc_AddExcelExtraTagData '" +STR(0) + "','"  + STR(TodoFile.aY)  + "','" + ;
					STR(TodoTags.TagNum) + "','" + ALLTRIM(pc_userid) + "','" + lc_Note + "','" + c_DrFirstN + "','" + c_DrlastN + "'"
				omedExc3.SQLEXECUTE( lc_sql,"")


			
			
			***06/01/2012 store med provider id as string
			LOCAL lcmedid as string
			lcMedid=''
			lcMedid=NVL(TodoTags.ao,'')			
			
			IF !EMPTY(ALLTRIM(lcMedid) )
				lc_sql=""		
				lc_sql=" exec dbo.qc_AddMedProvider '" +STR(0) + "','"  + STR(TodoFile.aY)  + "','" + ;
					STR(TodoTags.TagNum) + "','" + ALLTRIM(pc_userid) + "','" + ALLTRIM(lcmedid)+ "'"
				omedExc3.SQLEXECUTE( lc_sql,"")
			ENDIF
			***06/01/2012
									
			SELECT Todotags2
		
			
			INSERT INTO Todotags2 (plfirst,	pllastn, akas, ssN,	dob,	facility,	firstnam,	lastname, ;
				address1,	address2,	city,	state,	zip,	phonenmb,	fax,	provider,	dateofd,;
				scopefro,	executor,	scopeto,	includei,	usespeci,	usebase,	authofil,	usecase,;
				casedocu,	middlein,	paralegal,	notes,	indirect,	billto,	orderedb,	insured,	;
				claimnum,	adjuster,	accident,	clientma,	docketN,	court,	depodate,	medprovi,	lawfirm,;
				filenumb,	pladdress,	plcity,	plstate,plzip,	plpriorad,	duedate,	trialdat,	lrs_no, ;
				newcase,	[group],	[comment],	requestin,	expedite,	additiona,	tagnum, blurbcode , mailid, tagcomme) ;
				VALUES ( ALLTRIM(m.a), ALLTRIM(m.b), ALLTRIM(m.c), m.d, m.e,ALLTRIM(m.f), ALLTRIM(m.g), ;
				m.h, m.i, m.j, m.k, m.l, m.m, m.n, m.o, m.p,m.q, m.r, m.s, ;
				m.T, m.u, m.v, m.w, m.x, m.y, m.z, m.aa, m.ab, ALLTRIM(m.ac), m.ad, m.ae, m.af, ;
				m.ag, m.ah, m.ai, m.aj, m.ak, m.al, m.am, m.an, ALLTRIM(M.AO), m.ap, m.aq, m.ar, m.as, m.at, ;
				m.au, m.av, m.aw, m.ax,m.ay, m.az, m.ba, ALLTRIM(m.bb), m.bc, m.bd, m.be, ;
				m.tagnum, ALLTRIM(m.bg), NVL(m.bh,''),NVL(lc_Note,''))



			SELECT TodoTags

		ENDSCAN

*** continue with the cases
		SELECT TodoFile
	ENDSCAN
******************************************************3/21/2011 -email an excel output file
	SELECT TodoTags2
	GO TOP
	
	C_TEMPFILE=LEFT(ALLTRIM( PC_TODOFILE),LEN(ALLTRIM( PC_TODOFILE))-8) + "_output.xls"

	IF NOT EOF()
		COPY TO (STRTRAN(C_TEMPFILE,"'","")) TYPE XL5
		omedExc3.closealias("UserAcct")
		omedExc3.sqlexecute("exec  DBO.[GetUserByLogin] '" +	ALLTRIM( pc_UserId) + "'", "UserAcct")
		SELECT UserAcct
		IF NOT EOF()

			c_SendTo=STRTRAN(ALLT( UserAcct.Email),";",",")
			c_CopyTo="rtverifyoutbound@recordtrak.com"
			c_FromName=ALLTRIM(UserAcct.FULLNAME )
			c_FromEmail=STRTRAN(ALLT( UserAcct.Email),";",",")
			c_Subject=ALLTRIM("Output File for Batch#: " + cBatchNum )
			c_Message=ALLTRIM("Please, see attached excel file.")
			STORE "" TO c_attachment,c_bCCList
			c_attachment=C_TEMPFILE
			DO sendwwemail WITH c_FromEmail, c_FromName, c_SendTo,c_CopyTo, c_bCCList, c_Subject, c_Message, c_attachment
		ENDIF
		GFMESSAGE("Please review the " + C_TEMPFILE + " Excel file or/and check the email that had been sent to you.")

	ENDIF
	USE
**********************************************************3/21/2011
	SELECT TodoFile
	USE
ENDIF && EMPTY
IF NOT EMPTY(c_CurArea)
	SELECT (c_CurArea)
ENDIF
_SCREEN.MOUSEPOINTER= 0

RELEASE omedExc3
RETURN
***********************************************************************************
FUNCTION addattys
PARAMETERS n_headerid, c_att
LOCAL o_medExc4 AS OBJECT

o_medExc4=CREATEOBJECT("medgeneric")
LOCAL c_at_type AS STRING, c_firm_code AS STRING, c_newfirst AS STRING, c_newinit AS STRING, c_newlast AS STRING, ;
	c_attorneyname AS STRING, c_firm_name AS STRING, c_add1 AS STRING,c_add2 AS STRING, c_city AS STRING, ;
	c_state AS STRING, c_zip AS STRING, c_phone AS STRING, c_fax_no AS STRING, c_atcode AS STRING

nall=0

IF  RIGHT(c_att,1)<>";"
	c_att =c_att + ";"
ENDIF


nall=LEN(c_att)
FOR icnt=1 TO nall
	STORE "" TO c_at_type, c_firm_code, c_newfirst, c_newinit, c_newlast, c_attorneyname , c_firm_name ,;
		c_add1 ,c_add2, c_city, c_state, c_zip, c_phone, c_fax_no, c_atcode
	STORE 0 TO n_div, n_div2, n_cut


	IF icnt=1
		n_div =AT(";",c_att,1)
		n_div2 =AT(";",c_att,2)
		c_atcode  =ALLTRIM(SUBSTRC(c_Att, 1, n_div-1 ))
	ELSE
		n_div =AT(";",c_att,icnt-1) +1
		n_div2 =AT(";",c_att,icnt)
		n_cut=IIF(n_div2=0, nall, n_div2) -n_div
		c_atcode  =ALLTRIM(SUBSTRC(c_Att, n_div,n_cut ))
	ENDIF
	IF EMPTY(c_atcode)
		EXIT
	ENDIF


	lc_sql =" EXEC	[dbo].[QC_AddAditionalExcelAttys]'" +STR(n_headerid) + "','" + fixquote(c_atcode) + "'"
*!*		PN_LRSNO=TodoFile.aY
*!*		DO addlogline  WITH  0 , Lc_sql, " _STEP3EXCL"

	o_medExc4.SQLEXECUTE( lc_sql,"")
	IF n_div2=0
		EXIT
	ENDIF

NEXT

RELEASE o_medExc4
RETURN

***********************************************************************
PROCEDURE Prepexcl
LOCAL llExit AS Boolean, lnFldCnt AS INTEGER, lnTotColumns AS INTEGER, lcField3  AS STRING
llExit=.F.
lnTotColumns=AFIELDS(laEXCLFile,"Todotags2")
lnFldCnt=1

IF llExit=.F.
	SELECT Todotags2
********************************************************************

	FOR lnFldCnt=1 TO  lnTotColumns
		lcField2=""
		lcField=ALLTRIM(FIELD(lnFldCnt))
		lcField =laEXCLFile		(	lnFldCnt,1)
		lctype=	laEXCLFile		(	lnFldCnt,2)
		lnlenth =laEXCLFile		(	lnFldCnt,3)

		lcField2=  renameexl(lcField, lctype, lnlenth)

		SELECT Todotags2
		IF !EMPTY(ALLTRIM(lcField2))
			ALTER TABLE Todotags2 DROP COLUMN &lcField
			ALTER TABLE Todotags2 ADD COLUMN &lcField2
		ELSE
			llExit=.T.
			IF lcField<>"TAGNUM"
				ALTER TABLE Todotags2 DROP COLUMN &lcField
*ALTER TABLE Todotags2 ADD COLUMN "TagNum" N(6)
			ENDIF
		ENDIF
	NEXT
ENDIF
RETURN
******************************************************************************
FUNCTION renameexl
PARAMETERS lcFieldName,  c_type, n_lenth
LOCAL retval AS STRING, c_Field2 AS STRING, c_attrb AS STRING
c_alias =ALIAS()
STORE "" TO  retval, c_Field2, c_attrb

IF !EMPTY(lcFieldName)
	SELECT step1file
	SET ORDER TO excelh
	IF SEEK (ALLTRIM(UPPER(lcFieldName)))
		c_Field2=CHRTRAN(LEFT(ALLTRIM(step1file.customh),9)," ","")
		c_Field2=CHRTRAN(c_Field2,"'","")
		c_Field2=CHRTRAN(c_Field2,"#","N")
		c_attrb=" " + c_type + "(" + ALLTRIM(STR(n_lenth)) + ")"
		retval=c_Field2+c_attrb
	ENDIF

ENDIF
SELECT (c_alias)
RETURN UPPER(ALLTRIM(retval))
**plfirst	pllastn	akas	ss	dob	facility	firstnam	lastname	address1	address2	city	state	zip	phonenmb	fax	provider	dateofd	scopefro	executor	scopeto	includei	usespeci	usebase	authofil	usecase	casedocu	middlein	paralegal	notes	indirect	billto	orderedb	insured	claimnum	adjuster	accident	clientma	docket	court	depodate	medprovi	lawfirm	filenumb	pladdress	plcity	plstate	plzip	plpriorad	duedate	trialdat	lrs_no	newcase	group	comment	requestin	expedite	additiona	tagnum

***********************************************************************************
FUNCTION attystoadd
PARAMETERS n_headerid, c_att, l_3rdb, c_rt, c_billto, c_ordby, c_insur, c_claim, c_adjust, c_accdate, c_clmatter, c_lawfn
LOCAL o_medExc4 AS OBJECT

o_medExc4=CREATEOBJECT("medgeneric")
LOCAL c_at_type AS STRING, c_firm_code AS STRING, c_newfirst AS STRING, c_newinit AS STRING, c_newlast AS STRING, ;
	c_attorneyname AS STRING, c_firm_name AS STRING, c_add1 AS STRING,c_add2 AS STRING, c_city AS STRING, ;
	c_state AS STRING, c_zip AS STRING, c_phone AS STRING, c_fax_no AS STRING, c_atcode AS STRING

nall=0

IF TYPE('c_rt')="N"
c_rt=STR(c_rt)
ENDIF

IF  RIGHT(c_att,1)<>";"
	c_att =c_att + ";"
ENDIF


nall=LEN(c_att)
FOR icnt=1 TO nall
	STORE "" TO c_at_type, c_firm_code, c_newfirst, c_newinit, c_newlast, c_attorneyname , c_firm_name ,;
		c_add1 ,c_add2, c_city, c_state, c_zip, c_phone, c_fax_no, c_atcode
	STORE 0 TO n_div, n_div2, n_cut


	IF icnt=1
		n_div =AT(";",c_att,1)
		n_div2 =AT(";",c_att,2)
		c_atcode  =ALLTRIM(SUBSTRC(c_Att, 1, n_div-1 ))
	ELSE
		n_div =AT(";",c_att,icnt-1) +1
		n_div2 =AT(";",c_att,icnt)
		n_cut=IIF(n_div2=0, nall, n_div2) -n_div
		c_atcode  =ALLTRIM(SUBSTRC(c_Att, n_div,n_cut ))
	ENDIF
	IF EMPTY(c_atcode)
		EXIT
	ENDIF


	lc_sql=""
	lc_sql =" EXEC	[dbo].[QC_AddAdditionalExcelAttys] '" +STR(n_headerid) + "','" + fixquote(c_atcode) + "',"  + ;
		IIF(l_3rdb, STR(1), STR(0)) 	+ ",'" 	
	lc_sql2=  c_rt + "','" + c_billto + "','" +  FIXQUOTE(c_ordby) + "','" + FIXQUOTE(c_insur)+ "','" 	
	lc_sql3=  c_claim + "','" +  FIXQUOTE(c_adjust) + "','" + c_accdate + "','" + c_clmatter + "','" + c_lawfn + "'"	
	
*!*		IF l_3rdb
*!*		PN_LRSNO=99999
*!*		DO addlogline  WITH  0 , lc_sql+lc_sql2+lc_sql3, " _STEP3EXCL"
*!*		ENDIF
	o_medExc4.SQLEXECUTE( lc_sql+lc_sql2+lc_sql3,"")
	
	
	IF n_div2=0
		EXIT
	ENDIF

NEXT

RELEASE o_medExc4
RETURN

*!*	***********************************************************************
FUNCTION deptbyblurb
PARAMETERS c_blcode
**tblBlurbCounter
LOCAL lc_depart as String

c_alias=ALIAS()

DO case
CASE c_blcode="B"
	lc_depart="B"
CASE c_blcode="P"
	lc_depart="P"
CASE c_blcode="R"
	lc_depart="R"

OTHERWISE 
	lc_depart="Z"
ENDCASE

SELECT (c_alias)
RETURN lc_depart
******************************************************************************
PROCEDURE STORETEST

C_ALIAS=ALIAS()
SELECT (C_ALIAS)
IF NOT USED ("EXL3")
	COPY STRUCTURE TO H:\WP51\TEMP\EXL3.DBF
	USE "H:\WP51\TEMP\EXL3.DBF" IN 0
ENDIF
SELECT EXL3
APPEND BLANK
GATHER MEMVAR

SELECT (C_ALIAS)			
				

RETURN

 

