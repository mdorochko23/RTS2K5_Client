

PROCEDURE getFfile
PARAMETERS lcToName, lcDate
LOCAL  OMED AS OBJECT,  lnCurArea AS String, lcsql as String, lCTEMPFILE as String, lcSafety as String,  lcTEMP as String
STORE "" TO lCTEMPFILE, lnCurArea, lcsql, lcSafety,  lcTEMP
lnCurArea=ALIAS()
_SCREEN.MOUSEPOINTER=11
PRIVATE OMED AS OBJECT 

SELECT 0

_SCREEN.MOUSEPOINTER=11
PRIVATE   fso AS Object
fso = CREATEOBJECT("Scripting.FileSystemObject")
lcTEMP=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","CTemp", "\")))

lCTEMPFILE=lcTEMP + "FilingSet_" + STRTRAN(lcToName,"/","") + ".xls"
IF   fso.FileExists(ALLTRIM(lCTEMPFILE))
	RELEASE fso
	RETURN
ENDIF

CREATE CURSOR Setsdata (RTNum int, TagNum int,   Court c(50) NULL, include L, Suppress  L)
INDEX ON RTnUM+TagNum TAG RTTag ADDITIVE

OMED=CREATEOBJECT("generic.medgeneric")
omed.CLOSEALIAS("SetList")

**3/20/15 -added suppess colum to track 'Noprint' tags

lcsql=" exec [dbo].[FillingsReportExcl] '" + lcDate+ "'"
omed.SQLEXECUTE( lcsql,"SetList")
	
    SELECT Setsdata
	lcSafety = SET("Safety")
	SET SAFETY OFF	
	ZAP
	INSERT INTO Setsdata SELECT * FROM SetList 
	
	IF NOT empty(lcSafety)
	SET SAFETY &lcSafety
	ENDIF
	
	

RELEASE fso
	
	RELEASE OMED
**********************************************************

IF NOT EMPTY(lnCurArea)
	SELECT (lnCurArea)
ENDIF
_SCREEN.MOUSEPOINTER= 0
*********************************************************
PROCEDURE sendffile
PARAMETERS lcDate
PRIVATE   fso AS Object
fso = CREATEOBJECT("Scripting.FileSystemObject")
LOCAL lcAlias as String
lcAlias= ALIAS()
_SCREEN.MOUSEPOINTER=11


lcTEMP=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","CTemp", "\")))

lCTEMPFILE=lcTEMP + "FilingSet_" + STRTRAN(lcDate,"/","") + ".xls"
IF   fso.FileExists(ALLTRIM(lCTEMPFILE))
	RELEASE fso
	RETURN
ENDIF
IF USED('Setsdata')
SELECT Setsdata

SELECT  * FROM  Setsdata WHERE include =.t.  ORDER BY rtnum, tagnum  INTO CURSOR  Setsdata2 
select Setsdata2
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
endif

ENDIF

RELEASE fso
IF NOT EMPTY(lcAlias)
	SELECT (lcAlias)
ENDIF

_SCREEN.MOUSEPOINTER= 0