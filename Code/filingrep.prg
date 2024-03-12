&&PROCEDURE Filingrep
PARAMETERS lcDate
LOCAL  OMED AS OBJECT,  lnCurArea AS String, lcsql as String, lCTEMPFILE as String, lcSafety as String,  lcTEMP as String
STORE "" TO lCTEMPFILE, lnCurArea, lcsql, lcSafety,  lcTEMP
lnCurArea=ALIAS()
_SCREEN.MOUSEPOINTER=11
PRIVATE OMED AS OBJECT, fso AS Object
fso = CREATEOBJECT("Scripting.FileSystemObject")

SELECT 0
*lcDate=ALLTRIM(DTOC(DATE()))
_SCREEN.MOUSEPOINTER=11
*DO closeexcel WITH "Excel.EXE"
CREATE CURSOR Setsdata (RTNum int, TagNum int,   Court c(50) NULL, include L)
INDEX ON RTnUM+TagNum TAG RTTag ADDITIVE
lcTEMP=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","CTemp", "\")))

lCTEMPFILE=lcTEMP + "FilingSet_" + STRTRAN(lcDate,"/","") + ".xls"
IF   fso.FileExists(ALLTRIM(lCTEMPFILE))

RELEASE fso
RETURN
ENDIF
OMED=CREATEOBJECT("generic.medgeneric")
omed.CLOSEALIAS("SetList")
*lcsql=" exec [dbo].[KOPCourtSetReport] '" + lcDate+ "'"
**12/27/13- added include to filter for not reelased tags due to any rps/rules/missing images issues
lcsql=" exec [dbo].[FillingsReport] '" + lcDate+ "'"
omed.SQLEXECUTE( lcsql,"SetList")
	
    SELECT Setsdata
	lcSafety = SET("Safety")
	SET SAFETY OFF	
	ZAP
	INSERT INTO Setsdata SELECT * FROM SetList 
	IF NOT empty(lcSafety)
	SET SAFETY &lcSafety
	ENDIF
	GO top	
	IF NOT EOF()
		COPY TO (STRTRAN(lcTEMPFILE,"'","")) TYPE XL5
		omed.closealias("UserAcct")
		omed.sqlexecute("exec  DBO.[GetUserByLogin] '" +	ALLTRIM( pc_UserId) + "'", "UserAcct")
		SELECT UserAcct
		IF NOT EOF()

			c_SendTo=STRTRAN(ALLT( UserAcct.Email),";",",")
			c_CopyTo="rtverifyoutbound@recordtrak.com"
			c_FromName=ALLTRIM(UserAcct.FULLNAME )
			c_FromEmail=STRTRAN(ALLT( UserAcct.Email),";",",")
			c_Subject=ALLTRIM("List of RT/Tags for KOP Filings on " + lcDate + "."   )
			c_Message=ALLTRIM("Please, see attached excel file.")
			STORE "" TO c_attachment,c_bCCList
			c_attachment=lCTEMPFILE
			DO sendwwemail WITH c_FromEmail, c_FromName, c_SendTo,c_CopyTo, c_bCCList, c_Subject, c_Message, c_attachment
		ENDIF
		GFMESSAGE("Please review the " + lcTEMPFILE + " Excel file or/and check the email that had been sent to you.")

	ENDIF

	
	RELEASE OMED
**********************************************************

IF NOT EMPTY(lnCurArea)
	SELECT (lnCurArea)
ENDIF
_SCREEN.MOUSEPOINTER= 0
