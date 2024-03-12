PROCEDURE FLook_PA
**************************************************************************
* Program FLOOK_PA.PRG
**  Called from AdmUtil
**  Uses screen Flook_PA
**************************************************************************
CLEAR
CLOSE ALL

PUBLIC mv, dLrs, dTag, c_action
PRIVATE lType, dbInit, lcType, lcClCode

SET NEAR ON
SET TALK OFF
dlrs=0
dTag=0
lnContinue = 1

DO flook_pa.spr
IF EMPTY(dtag) OR EMPTY(dlrs) OR ISNULL(dtag) OR ISNULL(dlrs)
RETURN
ENDIF
IF lnContinue <> 1
   CLOSE DATA
RETURN
ENDIF
slrs=STR(dlrs)

STORE DATE() TO mdate
IF USED("tamaster")
   SELECT tamaster
   SET ORDER TO lrs_no
ELSE
   SELECT 0
   USE (f_tamaster) ORDER lrs_no
ENDIF

IF SEEK( dlrs)
   lcCl_code=tamaster.cl_code
ENDIF

*wait window "Printing First Look. Please wait." nowait
SET PROCEDURE TO ta_lib
dbInit = ALIAS()

lType = IIF(tamaster.litigation == "C  ", .F., .T.)
lcType = ALLTRIM(tamaster.litigation)
mv = ""

DO CASE

   CASE tamaster.lrs_nocode = "P" AND lcType == "G" && state diet drug
      DO FLookPrint WITH dbInit, lcCl_Code, dTag, lcType

   CASE tamaster.lrs_nocode = "P" AND lcType == "S" && pedicle screw
      DO FLookPrint WITH dbInit, lcCl_Code, dTag, lcType

ENDCASE

DO flook_pa
RETURN

**************************************************************************
***** PROCEDURE: FLOOKPRINT
****  PROGRAMMER: EF
****  DATE: 03/23/00
****  ABSTRACT:  First Look letter for Philadelphia office
**************************************************************************
PROCEDURE FLookPrint
PARAMETER dbTamaster, lcClCode, lnTag, lctype, d_deliv, n_days
LOCAL c_Days1, c_Days, lnCurArea
STORE "" TO c_Days1, c_Days, lacctm, lphone

lnCurArea=SELECT()

IF PARAMETERS() < 5
ELSE
   mdate = d_deliv
ENDIF
IF PARAMETERS() < 6
   c_Days = "twenty (20) "
ELSE
   c_Days1 = LOWER(gfNumWd(n_days, "NUMBER"))
   c_Days = ALLTR(STR(n_days))
   c_Days = c_Days1 +  " (" + c_Days + ") "
ENDIF

IF lctype == "G"
   DO printgroup IN ta_lib WITH mv, "FLookStateDD"
ELSE
   DO printgroup IN ta_lib WITH mv, "FLookPedicleScrew"
ENDIF

DO openMaster
lcacctm = ALLTRIM(viewTaMaster.sim_last)
mProvider=lookProvider(lcClCode,lntag )

* 07/23/04 DMA Use long plaintiff name
pc_fullnam = ALLT(viewTaMaster.Plaintiff)
STORE "" TO pc_plfname, pc_pllname, pc_plminit, pc_plgiven
DO gfBrkNam WITH pc_fullnam, ;
   pc_pllname, pc_plfname, pc_plminit, pc_plgiven
pc_plnam = IIF( NOT EMPTY(NVL(pc_plgiven,"")), pc_plgiven + " ", "") ;
      + pc_pllname
mPlaintiff = pc_plnam
mTerm = (viewTaMaster.Term_date)
mRt = ALLT( STR(viewTaMaster.Lrs_no))

lookMgrInfo(@lcAcctM, @lPhone)


=pullAttyInfo(IIF(NVL(pl_FrstLook,.F.) AND NOT EMPTY (NVL(pc_TflAtty,"")), ;
      pc_TflAtty, viewTaMaster.pl_at_code))
SELECT viewTaAtty
IF RECCOUNT()>0        
   mName=ALLTRIM(UPPER(viewTaAtty.newfirst)) + " " + ;
      ALLTRIM(UPPER(viewTaAtty.newlast))
   mata1=ALLTRIM(UPPER(viewTaAtty.firm))
   mata2=ALLTRIM(UPPER(viewTaAtty.newadd1)) + " " + ;
      ALLTRIM(UPPER(viewTaAtty.newadd2))
   mcsz=ALLTRIM(UPPER(viewTaAtty.newcity)) + ", " + ALLTRIM(viewTaAtty.newstate) ;
      + " " + ALLTRIM(viewTaAtty.newzip)
ENDIF

IF NVL(pl_Softimg,.F.)    
    _ASCIIROWS=58    
	REPORT FORM printFirstLook TO FILE (pc_softdir + "2_2flpa.txt") ASCII
ELSE
	REPORT FORM printFirstLook TO PRINTER NOCONSOLE 
ENDIF

select viewTaAtty
USE 
SELECT viewTaMaster
USE 
SELECT (lnCurArea)

RETURN
*********************************************************************************
PROCEDURE openMaster
LOCAL lcSQLLine, lnCurArea, lloGen
lnCurArea=select()
IF TYPE("oGen")!="O"
   lloGen=.T.
   oGen=CREATEOBJECT("medgeneric")
ENDIF
lcSQLLIne="select * from tblMaster where cl_code='"+ALLTRIM(lcClCode)+"' and active=1"
oGen.sqlexecute(lcSQLLine, "viewTaMaster")
IF lloGen=.T.
   RELEASE oGen
ENDIF 
SELECT (lnCurArea)
RETURN
************************************************************************************   
FUNCTION lookProvider
LPARAMETERS lcClCode, lnTag
LOCAL lcSQLLine, lnCurArea, lloGen, retval
lnCurArea=select()
retval=""
IF TYPE("oGen")!="O"
   lloGen=.T.
   oGen=CREATEOBJECT("medgeneric")
ENDIF
lcSQLLine="select descript from tblRequest where cl_code='"+ALLTRIM(lcClCode)+"' and tag='"+ALLTRIM(STR(lnTag))+"' and active=1"
oGen.sqlexecute(lcSQLLine, "viewReq")
SELECT viewReq
IF RECCOUNT()>0
   retval=ALLTRIM(descript)
ENDIF    
USE 
IF lloGen=.T.
   RELEASE oGen
ENDIF 
SELECT (lnCurArea)
RETURN retval
***********************************************************************************
PROCEDURE lookMgrInfo
LPARAMETERS lcacctm, lcphone
LOCAL lnCurArea, lcSQLLine, lloGen
lnCurArea=SELECT()

IF TYPE("oGen")!="O"
   lloGen=.T.
   oGen=CREATEOBJECT("medgeneric")
ENDIF

lcSQLLine="select fullName, directDial from tblUserCtrl where login='"+ALLTRIM(fixQuote(lcacctm))+"' and active=1"
oGen.sqlexecute(lcSQLLine, "viewInfo")
SELECT viewInfo
IF RECCOUNT()>0
   lcacctm=ALLTRIM(fullName)
   lPhone=ALLTRIM(directDial)
ENDIF    
USE 
IF lloGen=.T.
   RELEASE oGen
ENDIF 
SELECT (lnCurArea)
RETURN 
**************************************************************************
PROCEDURE pullAttyInfo
LPARAMETERS lcAttyCode
LOCAL lcSQLLine, lnCurArea, lloGen
lnCurArea=select()
IF TYPE("oGen")!="O"
   lloGen=.T.
   oGen=CREATEOBJECT("medgeneric")
ENDIF
lcSQLLIne="exec dbo.GetAttyInfo '"+ALLTRIM(fixQuote(lcAttyCode))+"'"
oGen.sqlexecute(lcSQLLine, "viewTaAtty")
IF lloGen=.T.
   RELEASE oGen
ENDIF 
SELECT (lnCurArea)
RETURN
************************************************************************************   