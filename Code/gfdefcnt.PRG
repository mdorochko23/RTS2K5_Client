FUNCTION gfDefCnt
** gfDefCnt
** Count attorneys participating in a case
** Called from Subp_PA, Subp_CA
***************************************************************************
***************************************************************************
PARAMETERS l_NotcType
* l_NotcType: .T. when called from Subp_PA and counts all attorneys
*             .F. when called from Subp_CA and counts defense attorneys only

IF PARAMETERS() = 0 OR TYPE("l_NotcType") = "U"
   l_NotcType = .F.
ENDIF

PRIVATE dbInit, n_count, l_isDiet, c_reqatty

dbInit = SELECT()
n_count = 0
l_isDiet = INLIST( pc_litcode, "D  ", "E  ")
c_reqatty = pc_RqAtCod

DO gettabilL2 WITH pc_clcode

SELECT tabills
IF SEEK( pc_clcode)
   SCAN WHILE tabills.cl_Code = pc_clcode
*IF SEEK( c_ClntCode)
*   SCAN WHILE tabills.cl_Code = c_ClntCode
      DO CASE

         CASE tabills.At_Code == c_reqatty
            * Always skip requesting attorney
            LOOP

         CASE NOT l_NotcType
            * For CA, count only defense attorneys who are participating,
            * other than the requesting attorney
            IF tabills.Code <> "D"
               * Skip non-defense attorneys
               LOOP
            ENDIF
            IF NOT INLIST( tabills.Response, "T", "S")
               * Skip non-participating attorneys
               LOOP
            ENDIF

         CASE l_isDiet
            * For KoP Diet Drug, count non-defense attorneys,
            * other than the requesting attorney,
            * regardless of participation status
            IF tabills.Code = "D"
               * Skip defense attorneys
               LOOP
            ENDIF

         OTHERWISE
            * For all other KoP cases, count all attorneys other
            * than requesting attorney

      ENDCASE
      n_count = n_count + 1
   ENDSCAN
ENDIF

SELECT ( dbInit)
RETURN n_count
************************************************************************
PROCEDURE GetTabill2

PARAMETERS c_client
LOCAL l_RetVal as Boolean, l_done as Boolean, C_STR as String, oMedBill as Object
oMedBill= CREATEOBJ("generic.medgeneric")
c_Clcode=oMedBill.cleanstring(c_client)

STORE .f. to l_RetVal, l_done
C_STR="exec [dbo].[GetBillsNoInhibitNoticeAttys]  " +  c_Clcode	
 
 
l_done=oMedBill.sqlexecute(C_STR, "Tabills")
IF l_done THEN
	l_RetVal=.T.	
	=CURSORSETPROP("KeyFieldList", "ID_TblBills,Cl_code, AT_code", "Tabills")
	INDEX ON CL_CODE + AT_CODE TAG clac ADDITIVE
	INDEX ON CL_CODE TAG CL_CODE ADDITIVE
ENDIF
RELEASE oMedBill
RETURN l_RetVal
	



