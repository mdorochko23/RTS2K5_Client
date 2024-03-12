
PARAMETERS d_date, n_rt, n_Tg1, n_Tg2
LOCAL  c_alias AS STRING, mv2 as String
c_alias =ALIAS()
LOCAL c_PrintJob AS STRING
llHoldFlag=.F.
LOCAL oMed AS OBJECT
oMed = CREATEOBJECT("generic.medgeneric")
calias=ALIAS()
pl_noticng = .F.
oMed.closealias("MdLtr")
**7/20/2015- added  RT and tag range
mv2=""
DO CASE

CASE  n_rt<>0

	oMed.sqlexecute("exec dbo.MdReleaseLetterbyRt '" + STR(n_rt) + "','" + STR(n_Tg1) + "','" +  STR(n_Tg2) + "'" , "MdLtr")

CASE   n_rt=0
	oMed.sqlexecute("exec [dbo].[MdReleaseLetter] '"  + d_date+ "'", "MdLtr")


OTHERWISE
	IF  ALLTRIM(goApp.CurrentUser.orec.LOGIN) ='ELLEN' AND ALLTRIM( UPPER( goApp.CurrentUser.orec.pc_userdpt))=="IT"
		oMed.sqlexecute("exec [dbo].[MdReleaseLettertest] '"  + d_date+ "'", "MdLtr")
	ENDIF

ENDCASE



*!*	IF  ALLTRIM(goApp.CurrentUser.orec.LOGIN) ='ELLEN' AND ALLTRIM( UPPER( goApp.CurrentUser.orec.pc_userdpt))=="IT"
*!*		oMed.sqlexecute("exec [dbo].[MdReleaseLettertest] '"  + d_date+ "'", "MdLtr")
*!*	ELSE
*!*		oMed.sqlexecute("exec [dbo].[MdReleaseLetter] '"  + d_date+ "'", "MdLtr")
*!*	ENDIF
IF USED("MdLtr")

	SELECT MdLtr
	GO TOP
	IF EOF()
		gfmessage('No tag(s) to MD subpoenas to release .')
		RETURN
	ENDIF

	SCAN
		SCATTER MEMO MEMVAR
		pn_RpsMerge=0
		pn_RpsMerge=Merger11or44 (m.cl_code,m.tag ) && 07/21/15 replaced as need to check for the edited followups(txn 44) not just txn 11 :  RpsJob11(m.cl_code,m.tag ,m.RequestDate)

		DO GetCase IN mdnotice WITH m.cl_code
**get the latest deponent data
		DO getdeponent WITH m.mailid_NO,  m.dept IN qcissue

		SELECT pc_depofile
		IF EOF()
			RETURN ""
		ENDIF


		mv2= Md30days ( m.deponent,m.dept, m.LRS_NO, m.tag, m.mailid_NO, m.RequestDate)
		c_class="ReleaseLtr"
		DO prtenqa WITH mv2, c_class, "1" ,""

**add txn 44 for each tag 5/29/15-start
		C_STR= ""
		LOCAL d_txn44  AS DATETIME
		IF TYPE ("m.RequestDate")="D" OR TYPE ("m.RequestDate")="T"
			IF  TYPE ("m.RequestDate")="T"
				d_txn44=TTOD(m.RequestDate)
			ELSE
				d_txn44=m.RequestDate
			ENDIF
		ELSE
			d_txn44=CTOD(m.RequestDate)
		ENDIF
		C_STR= "Exec dbo.gfAddTxn '" +  DTOC( gfChkDat(d_txn44+ 1, .F., .F.) )+  " ', '" ;
			+ ALLTRIM(fixquote(MdLtr.deponent)) + "' ,'" +fixquote(MdLtr.cl_code) + "',' " ;
			+ ALLTRIM(STR(44)) + "','"  + ALLTRIM(STR(MdLtr.TAG)) + "','" ;
			+ MdLtr.mailid_NO + "','" + STR(0) + "','" ;
			+ ALLTRIM(STR(0)) +"','','" + ;
			+ ALLTRIM(STR(0)) + "', '"  + "" + "','" ;
			+ "S"+ "','" ;
			+ "(F)" +ALLTRIM(pc_UserID) + "','" ;
			+ MdLtr.id_tblRequests +"'"
		l_done=oMed.sqlexecute(C_STR,"")

**add txn 44 for each tag 5/29/15-end
		SELECT MdLtr
	ENDSCAN

	DO ExclReport WITH d_date
ENDIF   && used 'MdLtr'


IF NOT EMPTY(c_alias)
	SELECT (c_alias)
ENDIF
RELEASE oMed, pn_RpsMerge
RETURN

*********************************************************************************************



********************************
PROCEDURE ExclReport
PARAMETERS lcDate
PRIVATE   fso AS OBJECT
fso = CREATEOBJECT("Scripting.FileSystemObject")
LOCAL lcAlias AS STRING
lcAlias= ALIAS()
_SCREEN.MOUSEPOINTER=11

LOCAL oMed AS OBJECT
oMed = CREATEOBJECT("generic.medgeneric")
lcTEMP=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","CTemp", "\")))

lCTEMPFILE=lcTEMP + "MDRequestsReleased_" + STRTRAN(lcDate,"/","") + ".xls"
IF   fso.FileExists(ALLTRIM(lCTEMPFILE))
	RELEASE fso
	RETURN
ENDIF
IF USED('MdLtr')
	SELECT MdLtr
	SELECT  LRS_NO, CaseName, TAG,  deponent, RequestDate FROM  MdLtr  ORDER BY  LRS_NO, TAG  INTO CURSOR  Setsdata2  READWRITE


	SELECT Setsdata2
	GO TOP

	IF NOT EOF()
		COPY TO (STRTRAN(lCTEMPFILE,"'","")) TYPE XL5
		oMed.closealias("UserAcct")
		oMed.sqlexecute("exec  DBO.[GetUserByLogin] '" +	ALLTRIM( pc_UserID) + "'", "UserAcct")
		SELECT UserAcct
		IF NOT EOF()

			c_SendTo=STRTRAN(ALLT( UserAcct.Email),";",",")
*c_CopyTo="rpsverify@hotmail.com"
			c_CopyTo="efisher@recordtrak.com"
			c_FromName=ALLTRIM(UserAcct.FULLNAME )
			c_FromEmail=STRTRAN(ALLT( UserAcct.Email),";",",")
			c_Subject=ALLTRIM("List of MD RT/Tags Released on " + lcDate + "."   )
			c_Message=ALLTRIM("Please, see attached excel file.")
			STORE "" TO c_attachment,c_bCCList
			c_attachment=lCTEMPFILE
			DO sendwwemail WITH c_FromEmail, c_FromName, c_SendTo,c_CopyTo, c_bCCList, c_Subject, c_Message, c_attachment
		ENDIF

	ENDIF

ENDIF

RELEASE fso
RELEASE oMed
IF NOT EMPTY(lcAlias)
	SELECT (lcAlias)
ENDIF

_SCREEN.MOUSEPOINTER= 0

*****************************************8

FUNCTION Merger11or44
PARAMETERS lccl, ntgreq 
LOCAL n_RpsId AS INTEGER,  l_ok AS Boolean
LOCAL oMed AS OBJECT
ots2 = CREATEOBJECT("generic.medgeneric")
calias=ALIAS()
ots2.closealias('SeqID')
l_ok = ots2.sqlexecute("select [dbo].[getSpecId_MergeRpsJob] ('" + lccl+ "','" + STR(ntgreq) +"')", 'SeqID')
n_RpsId=0
IF USED('SeqID')
	SELECT SeqID
	IF NOT EOF()
		n_RpsId=NVL(SeqID.EXP,0)
	ENDIF
ENDIF


RELEASE ots2
IF !EMPTY(calias)
	SELECT (calias)
ENDIF
RETURN  n_RpsId
