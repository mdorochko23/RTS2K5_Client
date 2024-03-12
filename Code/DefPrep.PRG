*PROCEDURE DefPrep
**CALLED TO PRINT CA NOTICES
PARAMETERS n_LitType
PRIVATE dbInit
* 04/24/03 DMA Tuneup to eliminate parameters, APPEND BLANK,
*              and inefficient &db.. notation
*
* Builds two temporary files for use in notice-set production:
*    CANAtty holds all notice-eligible non-plaintiff attorneys in the case
*        (this includes both defense and lead attorneys)
*    CAAtList holds all notice-eligible attorneys in the case
*
* Eligibility for notice receipt requires that:
*    1) Attorney's response code in TABills is "T" or "S"
*    2) Attorney is not the Plaintiff's Attorney for the case
*    3) Attorney does not have the NoNotice flag set in TABills

dbInit = SELECT()
oMstr=CREATEOBJECT("medMaster")
WAIT WINDOW "Preparing list of defense attorneys" NOWAIT NOCLEAR 

*USE ( f_TAMaster) AGAIN IN 0 ORDER Cl_Code ALIAS CaseData
*USE ( f_tabills) AGAIN IN 0 ORDER clac ALIAS AttyData
IF USED('NotcData')
SELECT NotcData
USE
ENDIF
USE ( f_CANType) AGAIN IN 0 ORDER (pc_CaseNot) ALIAS NotcData

IF USED( "CANAtty")
	SELECT canatty
	USE
ENDIF
IF USED( "CAAtList")
	SELECT caatlist
	USE
ENDIF
SELECT 0

*-- 01/21/2021 MD #218721
SET SAFETY OFF 
*-- 01/21/2021 MD #218721

CREATE TABLE C:\temp\canatty (at_code C(8), Cl_Code C(10))
INDEX ON at_code + Cl_Code TAG atty
INDEX ON at_code UNIQUE TAG notice
CREATE TABLE C:\temp\caatlist (at_code C(8), Cl_Code C(10), role C(1))
INDEX ON Cl_Code + IIF( role = "P", "1", "2") + at_code TAG atty



IF TYPE('pl_HSOnly')="U"
 pl_HSOnly=.F.
ENDIF
pc_CaseNot = IIF( pl_HSOnly, "ca_hscases", "ca_cases")
SELECT CANOTICE
SET ORDER TO (pc_CaseNot)


IF SEEK( DTOC( ldRunDate))
&&1/24/07
SCAN WHILE txn_date =ldRunDate 
**8/21/09 do not print civil lit with asbestos lit cases

DO case
	CASE n_LitType= 1
			IF CANotice.litigation <> "C  "
				LOOP
			endif			
	CASE n_LitType = 2
			IF CANotice.litigation = "C  "	
				LOOP
			endif		
		
endcase	

**8/21/09 end

	l_gotMasterid=oMed.sqlexecute("SELECT DBO.fn_GetID_tblmaster('" + fixquote(Canotice.Cl_Code) + "')", "MasterID")
	IF  NOT l_gotMasterid
		gfmessage( "Data processing error. Try again or contact IT dept."  )
		RETURN
	ENDIF

	oMstr.getitem(Masterid.EXP)


	SELECT MASTER
	* SEEK c_NotcCase
	l_Tabill=gettabill(MASTER.Cl_Code)
	IF NOT l_Tabill
		gfmessage( "Cannot get TAbills file to print Notices.")
		RETURN
	ENDIF
	SELECT tabills
	* IF SEEK( c_NotcCase)
	SCAN FOR INLIST( response, "T", "S") AND ;
			tabills.at_code <> MASTER.Rq_At_Code AND ;
			NOT nonotice WHILE tabills.Cl_Code == Canotice.Cl_Code
		IF tabills.CODE <> "P"
			INSERT INTO canatty ;
				( at_code, Cl_Code) ;
				VALUES ;
				( tabills.at_code,Canotice.Cl_Code)
		ENDIF
		INSERT INTO caatlist ;
			(at_code, Cl_Code, role) ;
			VALUES ;
			( tabills.at_code, Canotice.Cl_Code, tabills.CODE)
		SELECT tabills
	ENDSCAN
	* ENDIF
	
	&&&&1/24/07
	ENDSCAN
	
ENDIF
SELECT canatty
SET ORDER TO atty
SELECT caatlist
SET ORDER TO atty
*SELECT NotcData
*USE
IF USED ('Tabills')
	SELECT tabills
	USE
ENDIF
IF USED ('MASTER')
	SELECT MASTER
	USE
ENDIF
SELECT ( dbInit)
WAIT CLEAR
RETURN
