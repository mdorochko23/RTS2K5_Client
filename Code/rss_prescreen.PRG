*******************************************************************************
*** Rss_images pre screening program
*** Origin date: 2/16/2009
*******************************************************************************

#DEFINE conConfigRTS "Config-RTS"
#DEFINE conConfigFirstLook "Config-FirstLook"
#DEFINE conLitSerzone "SRZ"
#DEFINE conLitLatex "O"
#DEFINE conLitPPA "5"
#DEFINE conLitPPAState "51"
#DEFINE conLitPPAFederal "52"
#DEFINE conLitRezulin "2"
#DEFINE conLitHRT "HRT"
#DEFINE conLitRemicade "RMD"
#DEFINE conLitVioxx "VIX"
#DEFINE conLitEnbrel "ENB"
#DEFINE conLitIntergel "IRG"
#DEFINE conLitCelebrex "CLX"
#DEFINE conLitBextra "BXA"
#DEFINE conLitGuidant "GUI"
#DEFINE conLitCivil "C"
#DEFINE conLitZyprexa "ZPX"
#DEFINE conLitHTS "HTS"
#DEFINE conLitMotley "MTL"
#DEFINE conLitEvra "EVR"
#DEFINE conLitEcoli "ECL"
#DEFINE conLitBice "BCE"  && Bice ligtigation
#DEFINE conLitSerqoquil "SRQ"  && Serqoquil ligtigation
#DEFINE conLitCAD "CAD"  && Charite AD
#DEFINE conLitDolobid "DLB"  && Dolobid
#DEFINE conLitRpdNJ "RPD"  && NJ Risperdal
#DEFINE conLitFlavor "FLR"  && popcorn
#DEFINE conLitLaRisperdal "RLA"  && LA Risperdal
#DEFINE conLitCRT "CRT"  && CRT
#DEFINE conAreaMotley "MOTLEY"  && Vioxx and Enbrel
#DEFINE conAreaMorgan "MORGAN"  && HRT litigation
#DEFINE conAreaKeeley "KEELEY"  && HRT litigation
#DEFINE conAreaCohen "COHEN"  && HRT litigation
#DEFINE conAreaMotleyCc "MOTLEY-CO-CNSL"  && Vioxx  Motley Cc
#DEFINE conAreaChambliss "CHAMBLISS"  && Chambliss
#DEFINE conAreaFlorida "FLORIDA"  && intergel
#DEFINE conAreaMinnesota "MINNESOTA"  && intergel
#DEFINE conAreaEgerton "EGERTON"  && Civil litigation
#DEFINE conAreaPlaintiff "PLAINTIFF"  && HTS litigation
#DEFINE conAreaPopcorn "POPCORN"  && Flavor litigation
#DEFINE conAreaPopcorn2 "POPCORN2"  && Flavor litigation, area popcorn2
#DEFINE conRtpath "w:\rt-docs\"
#DEFINE conRtFlpath "w:\rt-fl\"
#DEFINE conBatesRoot "j:\bates\"

*************************************************************************************
PARAMETERS n_lrs,n_Tag,c_lit,c_area,cerror

n_lrs=IIF(PCOUNT()<1, 50045,n_lrs)
n_tag=IIF(PCOUNT()<2, 229,n_Tag)
slit=IIF(PCOUNT()<3, "SRQ",c_lit)
sarea=IIF(PCOUNT()<4, "",c_area)

PRIVATE lcutomBates,c_error,serror
c_error=''

obmed=CREATEOBJECT('medgeneric')

CREATE CURSOR LitBates(sLitDir CHAR(50),sLitigation CHAR(20),sarea CHAR(20),sPrefix CHAR(20))

*--check for existing images
serror=''
checkexistingtag(n_lrs,n_tag,@serror)

IF NOT EMPTY(serror)
	c_error=IIF(not EMPTY(c_error),c_error+","+serror,serror)
ENDIF

serror=''
ValidateCaseName(n_lrs,n_tag,@serror)
IF NOT EMPTY(serror)
	c_error=IIF(not EMPTY(c_error),c_error+","+serror,serror)
ENDIF
serror=''
*--check for bates data
*!*	setupbates()
*!*	lcutomBates = FindLitArea(slit, sarea)
*!*	IF lcutomBates
*!*		sFile = ADDBS(ALLTRIM(LitBates.sLitDir)) + ALLTRIM(LitBates.sPrefix) + ALLTRIM(STR(n_lrs)) + ".txt"
*!*		sLockFile =ADDBS(ALLTRIM(LitBates.sLitDir)) + ALLTRIM(LitBates.sPrefix) + ALLTRIM(STR(n_lrs))+ ".sav"
*!*		IF FILE(sFile) AND NOT FILE(sLockFile)
*!*			lr=chkTaginfile(sFile,n_tag)
*!*			IF NOT lr
*!*				serror="tag not in bates file"
*!*				c_error=IIF(not EMPTY(c_error),c_error+","+serror,serror)
*!*			ENDIF 
*!*		ELSE
*!*			serror="bates file not found or there is a save file"
*!*			c_error=IIF(not EMPTY(c_error),c_error+","+serror,serror)
*!*		ENDIF
*!*	ELSE
*!*	ENDIF
cerror=c_error

*********************************************************************************
FUNCTION checkexistingtag
PARAMETERS nlrs,nTag,serror
LOCAL sDocPath, sConfig,npages,croot,crt,ctag,serror2
crt=ALLTRIM(STR(nlrs))
ctag=ALLTRIM(STR(nTag))
serror = ""
serror2=""
croot = IIF(pl_FrstLook, conRtFlpath, conRtpath)
sDocPath =croot+ADDBS(PADL(crt,8,'0'))+PADL(ctag,3,'0')
IF DIRECTORY(sDocPath)
	serror = "Deponent " +crt + "." + ctag + " was scanned (folder/files(s) exist)."
ELSE
*  make sure we don't have any record in sql server
	IF pl_FrstLook
		c_sql="select * from chon_rtfl..tbldocuments where ntag=&ctag. AND "+;
			"npatientid=(select npatientid from chon_rtfl..tblpatients WHERE smrn=&crt.) and dtdeleted is null"
	ELSE
		c_sql="select * from chon_rts..tbldocuments where ntag=&ctag. AND "+;
			"npatientid=(select npatientid from chon_rts..tblpatients WHERE smrn=&crt.) and dtdeleted is null"
	ENDIF
	nr=obmed.sqlexecute(c_sql,"scanimages")
	npages = RECCOUNT("scanimages")
	IF npages > 0 THEN
		serror = "Deponent " + crt + "." + ctag + " was scanned (records in SQL)."
	ENDIF
ENDIF
IF USED("scanimages")
	USE IN scanimages
ENDIF 	

c_sql="select * from tbltimesheet with (nolock) where cl_code=dbo.getclcodebylrs(" + ALLTRIM(STR(n_lrs)) + ") and tag=" + ;
	ALLTRIM(STR(n_Tag)) + " and txn_code in (1,41) and deleted is null"
nr=obmed.sqlexecute(c_sql,"txndata")
npages = RECCOUNT("txndata")
serror2=""
IF npages > 1 THEN
	serror2="Deponent " + crt + "." + ctag + " has more than one Txn 1/41 code."
	serror = IIF(EMPTY(serror),serror2,ALLTRIM(serror)+"; " + ALLTRIM(serror2))
ENDIF

IF USED("txndata")
	USE IN txndata
ENDIF 	

RETURN (serror)

*****************************************************************************
FUNCTION  ValidateCaseName
PARAMETER nlrs,ntag,serror
LOCAL nID,LAST, smlast
crt=ALLTRIM(STR(nlrs))
nID=0
sLast = ""
smlast = ""
serror = ""
IF ntag > 0 AND ntag < 1000
	IF pl_FrstLook
		c_sql = "Select * From chon_rtfl..tblPatients Where sMRN =&crt. And dtDeleted is NULL"
	ELSE
		c_sql = "Select * From chon_rts..tblPatients Where sMRN =&crt. And dtDeleted is NULL"
	ENDIF
	nr=obmed.sqlexecute(c_sql,'patient')
	IF RECCOUNT('patient')>0
		GO TOP IN patient
		sLast = LEFT(UPPER(ALLTRIM(patient.sLastName)),15)
	ELSE 
		RETURN ""
	ENDIF
	c_sql="exec dbo.GetMasterbyRT &crt."
	nr=obmed.sqlexecute(c_sql,'master')
	IF RECCOUNT('master')>0
		GO TOP IN MASTER
		smlast=UPPER(ALLTRIM(MASTER.name_last))
	ENDIF
*-- make sure barcode last name matches the last name on the svr'
	IF NOT sLast==smlast
		serror = "Last last does not match. RTS has:" + smlast + "  RSS has:" + sLast
	ENDIF

ELSE
	serror = "Invalid tag number-" + ALLTRIM(STR(n_tag))
ENDIF
RETURN (serror)

*****************************************************************************
FUNCTION FindLitArea
PARAMETERS cLit,cArea
cLit = UPPER(ALLTRIM(cLit))
cArea = UPPER(ALLTRIM(cArea))
lFindLitArea = .F.
SELECT LitBates
GO TOP
SCAN
	IF LitBates.sLitigation = cLit
*' lit specific bates'
		IF cLit <> conLitHRT AND cLit <> conLitVioxx AND cLit <> conLitCelebrex AND ;
				cLit <> conLitBextra AND cLit <> conLitGuidant AND cLit <> conLitCivil AND;
				cLit <> conLitIntergel AND cLit <> conLitZyprexa AND cLit <> conLitHTS AND;
				cLit <> conLitFlavor
			lFindLitArea = .T.	&&RECNO(LitBates)
			EXIT
		ENDIF
*' Area specific bates'
		IF LitBates.sarea = cArea
			lFindLitArea = .T. &&RECNO(LitBates)
			EXIT
		ENDIF
	ENDIF
ENDSCAN

IF cLit="Z"
	lFindLitArea=.f.
ENDIF 

RETURN lFindLitArea

*******************************************************************************
PROCEDURE setupbates
LOCAL sroot
sroot = conBatesRoot
Addbateslit(conLitRezulin, "", sroot + "Rezulin\", "")  &&Resulin
Addbateslit(conLitSerzone, "", sroot + "Serzone\", "")  &&Serzone
Addbateslit(conLitLatex, "", sroot + "RoundTxt\", "L")  &&Latex gloves
Addbateslit(conLitPPA, "", sroot + "Textfile\", "")  &&PPA
Addbateslit(conLitPPAState, "", sroot + "Textfile\", "")  &&PPA state
Addbateslit(conLitPPAFederal, "", sroot + "Textfile\", "")  &&PPA federal
Addbateslit(conLitIntergel, conAreaFlorida, sroot + "Intergel\", "")  &&Intergel Florida
Addbateslit(conLitIntergel, conAreaMinnesota, sroot + "Intrglmn\", "")  &&Intergel Minnesota
Addbateslit(conLitHRT, conAreaMorgan, sroot + "HrtMorgn\", "")  &&HRT Morgan
Addbateslit(conLitHRT, conAreaKeeley, sroot + "HrtKeely\", "")  &&HRT Keeley
Addbateslit(conLitHRT, conAreaCohen, sroot + "HrtCohen\", "")  &&HRT Cohen
Addbateslit(conLitRemicade, "", sroot + "Remic\", "")  &&Remicade
Addbateslit(conLitVioxx, conAreaMotley, sroot + "Vixmotly\", "")  &&Vioxx
Addbateslit(conLitVioxx, conAreaMotleyCc, sroot + "Vixmotcc\", "")  &&Vioxx Motley CC
Addbateslit(conLitEnbrel, conAreaMotley, sroot + "Enbmotly\", "")  &&Enbrel
Addbateslit(conLitHTS, conAreaMotley, sroot + "HtsMotly\", "")  &&HTS
Addbateslit(conLitHTS, conAreaPlaintiff, sroot + "HtsPlain\", "")  &&HTS Plaintiff
Addbateslit(conLitCelebrex, conAreaMotleyCc, sroot + "Clxmotcc\", "")  &&Celebrex Motley CC
Addbateslit(conLitBextra, conAreaMotleyCc, sroot + "Bxamotcc\", "")  &&Bextra Motley CC
Addbateslit(conLitBextra, conAreaMotley, sroot + "Bxamotly\", "")  &&Bextra Motley
Addbateslit(conLitGuidant, conAreaMotleyCc, sroot + "Guimotcc\", "")  &&Guidant Motley CC
Addbateslit(conLitCivil, conAreaChambliss, sroot + "Civilchb\", "")  &&Civil Chambliss
Addbateslit(conLitCivil, conAreaEgerton, sroot + "CEgerton\", "")  &&Civil Egerton
Addbateslit(conLitZyprexa, conAreaMotley, sroot + "Zpxmotly\", "")  &&Zyprexa Motley
Addbateslit(conLitMotley, "", sroot + "Motley\", "")  &&Motley litigation (Motley Rice)
Addbateslit(conLitEvra, "", sroot + "Evrortho\", "")  &&Evra litigation
Addbateslit(conLitEcoli, "", sroot + "Ecoli\", "")  &&Ecoli litigation
Addbateslit(conLitSerqoquil, "", sroot + "Seroquel\", "")  &&Serqoquil litigation
Addbateslit(conLitBice, "", sroot + "Bice\", "")  &&Bice litigation
Addbateslit(conLitCAD, "", sroot + "ChariteAD\", "")  &&ChariteAD litigation
Addbateslit(conLitDolobid, "", sroot + "Dolobid\", "")  &&Dolobid litigation
Addbateslit(conLitRpdNJ, "", sroot + "Rpdnj\", "")  &&RPD NJ litigation
Addbateslit(conLitFlavor, conAreaPopcorn, sroot + "flavpop\", "")  &&Flavor popcorn
Addbateslit(conLitFlavor, conAreaPopcorn2, sroot + "flavpop2\", "")  &&Flavor area popcorn2
Addbateslit(conLitLaRisperdal, "", sroot + "LaRisp\", "")
Addbateslit(conLitCRT, "", sroot + "CrtBates\", "")  &&CRT bates

******************************************************************
PROCEDURE Addbateslit
PARAMETERS cLit,cArea,cDir,cPre
lADD = .T.
IF DIRECTORY(cDir) THEN
	INSERT INTO LitBates ;
		(sLitDir,sLitigation,sarea ,sPrefix) ;
		VALUES ;
		(ALLTRIM(cDir),UPPER(ALLTRIM(cLit)),UPPER(ALLTRIM(cArea)),ALLTRIM(cPre))
ELSE
	lADD = False
ENDIF
RETURN lADD

******************************************************************
FUNCTION chkTaginfile
PARAMETERS lc_Filetxt,n_Tag
LOCAL ctag,lfound
lfound=.F.
ctag=PADL(ALLTRIM(STR(n_Tag)),3,'0')
ln_Fhndle = FOPEN(lc_Filetxt)
IF m.ln_Fhndle > 0
	ln_counter = 1
	DO WHILE NOT FEOF(ln_Fhndle)
		lc_CurTxt = FGETS(ln_Fhndle)
		IF ln_counter > 4 AND LEN( lc_CurTxt) >= 3 ;
				AND LEFT(lc_CurTxt,3)==ctag
			lfound=.T.
			EXIT
		ENDIF
		ln_counter=ln_counter+1
	ENDDO
	FCLOSE(ln_Fhndle)
ENDIF
RETURN (lfound)
