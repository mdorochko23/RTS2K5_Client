FUNCTION AtShare
*  Called by Orders, PrintCov
*  Assumes that gfGetCas has been called
*  02/24/2004  DMA  Complete rewrite to use new-format shares file
PARAMETERS c_Atty, c_Round, c_plBBAsb, c_BBDock
LOCAL llReturn, c_FullRCA, c_BBCombo, c_FirmCode

* 04/22/03 DMA Plaintiff's attorney is always approved
* 02/24/04 DMA Non-B&B cases are always approved
IF c_Atty = pc_platcod OR EMPTY(NVL(c_plBBAsb,""))
   RETURN .T.
ENDIF

dbInit = SELECT()

WAIT WINDOW "Checking attorney against Berry & Berry participant file." NOWAIT NOCLEAR 
llReturn = .F.
c_FullRCA = c_plBBAsb + c_Round
omed=CREATEOBJECT("transactions.medrequest")
STORE "" TO c_FirmCode, c_BBCombo
lcSQLLine="exec dbo.getFirmBBCombobyAtty '"++ALLTRIM(c_Atty)+"'"
oMed.sqlexecute(lcSQLLine,"viewFirm")
SELECT viewFirm
IF RECCOUNT()>0
   c_FirmCode=viewFirm.Firm_Code
   c_BBCombo=viewFirm.BB_combo
ENDIF 
USE IN  viewFirm

lc_path=MLPriPro("R", "RTS.INI", "Data","CAL", "\")
SELECT 0
lc_newShare=ADDBS(ALLTRIM(lc_path))+"newShare.dbf" 
USE &lc_newShare ALIAS newShare SHARED IN 0
SELECT NewShare
SET ORDER TO Lookup
** Check first for an exact match for the specified attorney
** using the case's ASB Number and round ID,
** and confirm that s/he is still participating in the case.
IF SEEK( c_FullRCA + c_BBCombo)
   llReturn = EMPTY( NewShare.date_out)
ENDIF
** Check next for an exact match for the specified attorney
** using the case's docket information and round ID,
** and confirm that s/he is still participating in the case.
IF NOT llReturn
   SET ORDER TO DockRound
   IF SEEK( c_BBDock + c_Round)
      SCAN WHILE NewShare.Docket + NewShare.Round_ID = c_BBDock + c_Round
         IF NewShare.BB_Combo = c_BBCombo
            IF EMPTY( NewShare.date_out)
               llReturn = .T.
               EXIT
            ENDIF
         ENDIF
      ENDSCAN
   ENDIF
ENDIF
IF NOT llReturn
   ** If no exact match was found, see if there is a valid
   ** participating attorney from the same firm.
   ** Accept matches based on either ASB ID or Docket information.
   ** This covers one-time orders placed before the shares
   ** file included the specific attorney.
  	lcSQLLine="exec dbo.getAttyBBComboByFirmCode '"+ALLTRIM(c_FirmCode)+"'"
	oMed.sqlexecute(lcSQLLine,"viewAttyData")
	
   SELECT DISTINCT viewAttyData.AT_Code ;
      FROM NewShare, viewAttyData ;
      INTO CURSOR AttyList ;
      WHERE ;
      (NewShare.ASB_ID =c_plBBAsb OR NewShare.Docket = c_BBDock) AND ;
      NewShare.Round_ID = c_Round AND ;
      EMPTY( NewShare.Date_Out) AND ;
      viewAttyData.BB_Combo = NewShare.BB_Combo
   IF _TALLY > 0
      llReturn = .T.
   ENDIF
   SELECT AttyList
   USE
   SELECT viewAttyData
   USE 
ENDIF
SELECT NewShare
USE
WAIT CLEAR
SELECT( dbInit)
RETURN llReturn
