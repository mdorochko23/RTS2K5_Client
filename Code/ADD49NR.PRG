
*****************************************************************************************************************
*PROCEDURE Add49 NR

** caleld from Main menu: adds txn 49 fot tag on Excel
*****************************************************************************************************************
PARAMETERS ntxncode, C_FILE
LOCAL  OMED AS OBJECT,  n_minutes AS INTEGER, c_comment AS STRING, lnCurArea AS String, c_date as String
c_date=""
lnCurArea=ALIAS()
_SCREEN.MOUSEPOINTER=11
PRIVATE OMED AS OBJECT
OMED=CREATEOBJECT("generic.medgeneric")
SELECT 0

DO closeexcel WITH "Excel.EXE"
*!*	IF ALLTRIM(goApp.CurrentUser.orec.LOGIN) ='ELLEN'
*!*		l_test =.T.
*!*	ELSE
	l_test=.F.
*!*	ENDIF

IF TYPE("PC_USERID")<>"C"
	PC_USERID=ALLTRIM(goApp.CurrentUser.orec.LOGIN)
ENDIF

	C_FILE="'" +C_FILE + "'"
	IF anyEXCEL(&C_FILE)=.F. 
    	IF NOT EMPTY(lnCurArea)
      	 SELECT (lnCurArea)  
    	endif 
    	WAIT WINDOW "Process canceled."
    RETURN ""
   ENDIF  

  SELECT anyexcel
  DELETE ALL FOR RT=0
  GO TOP
DO CLEARTMP
IF  EOF()
	WAIT WINDOW "No Data to process.."
	RETURN
ENDIF
IF  EMPTY(ALLTRIM(C_FILE))
	WAIT WINDOW "No excel file selected.."
	RETURN
ENDIF

SELECT anyexcel
USE
lcTEMP=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","CTemp", "\")))
USE (lcTEMP+ "NR" + ".dbf")  ALIAS LISTISSUE IN 0
SET DELETED ON

l_addrev=.T.



SELECT  LISTISSUE
SCAN

	STORE 0 TO n_minutes, N_RTTODO, ntag
	c_comment=""
	IF TYPE("LISTISSUE.RT")="C"
		N_RTTODO= VAL(ALLTRIM(LISTISSUE.RT))

	ELSE
		N_RTTODO= LISTISSUE.RT

	ENDIF
	PC_LRSNO=N_RTTODO

	IF TYPE("LISTISSUE.HOURS")="C"
		n_minutes= VAL(ALLTRIM(LISTISSUE.HOURS))

	ELSE
		n_minutes=LISTISSUE.HOURS

	ENDIF

	c_comment=ALLTRIM(LISTISSUE.COMMENT)
	c_date=ALLTRIM(LISTISSUE.txndate)
	DO GETMASTERTABLE WITH N_RTTODO

	IF MASTER.litigation<>'ZNK'
		GFMESSAGE( 'Invalid Litigation' )
		RETURN
	ENDIF


	IF TYPE("LISTISSUE.TAG")="C"
		Ntag= VAL(ALLTRIM(LISTISSUE.TAG))

	ELSE
		Ntag= LISTISSUE.TAG

	ENDIF


	IF NTAG =0
		GFMESSAGE( 'Invalid Tag Number' )
		SKIP
		LOOP
	ENDIF
&& for printing get a tag# from a list



	DO GETREQUEST  WITH MASTER.cl_code, ntag




	IF ADDTIMESHEET (ntxncode, NTAG, REQUEST.DESCRIPT, REQUEST.mailid_no, n_minutes, c_comment, c_date)=.F.
		GFMESSAGE( 'Cannot add txn49. Try again.' )
		RETURN
	ELSE


		LCSQLLINE="update tblRequest set  Revw_Stat='C',revcompby='" +ALLTRIM(PC_USERID) + "', edited='" + DTOC(DATETIME()) +"', editedby ='" + ;
		ALLTRIM(PC_USERID) + "' where id_tblrequests='"+REQUEST.id_tblRequests+"' AND Revw_Stat<>'C'  and active =1"




		OMED.SQLEXECUTE(LCSQLLINE)
	ENDIF
	
	
	
	
	
	SELECT LISTISSUE

ENDSCAN


RELEASE OMED
_SCREEN.MOUSEPOINTER=0

*********************************************************************************************
*********************************************************************************************
PROCEDURE GETMASTERTABLE
*********************************************************************************************
PARAMETERS LN_RTTODO
IF USED("master")
	USE IN MASTER
ENDIF
PRIVATE OMED2 AS OBJECT
IF TYPE("LN_RTTODO")<>"N"
	LN_RTTODO=VAL(LN_RTTODO)
ENDIF
OMED2=CREATEOBJECT("generic.medgeneric")
OMED2.SQLEXECUTE("exec dbo.GetMasterbyRTNumber '"+STR(LN_RTTODO) + "'" ,"Master")

PL_GOTCASE =.F.
DO GFGETCAS WITH .T.

RELEASE OMED2
RETURN
**********************************************************************************************
PROCEDURE GETREQUEST
*********************************************************************************************
LPARAMETERS lcClCode, lnTag
LOCAL CSQL AS STRING,  OMED2 AS OBJECT

IF USED("request")
	USE IN REQUEST
ENDIF

OMED2=CREATEOBJECT("generic.medgeneric")
CSQL="select  cl_code, tag, descript, mailid_no, id_tblRequestS, revw_stat from tblrequest WITH (NOLOCK) where cl_code='"+ALLTRIM(lcClCode) + "' and tag ='" + STR(lntag) + "' and active=1"
OMED2.SQLEXECUTE(CSQL ,"Request")

RELEASE OMED2
RETURN

*******************************************************************************************
PROCEDURE ADDTIMESHEET
PARAMETERS NTXN_CODE, NTAGNUM, CDESCRIPT,CMAILID, nUnits, cMemo, cdate
PRIVATE OMEDT AS OBJECT
PRIVATE CSQL AS STRING, C_TXNCODE AS STRING
OMEDT=CREATEOBJECT("generic.medgeneric")

IF TYPE('nUnits')="C"
   nUnits=VAL(ALLTRIM(nUnits))
ENDIF   

IF nUnits<>0
	*N_UNITS=GETunits(2, nUnits)
	*nUnits=ROUND(nUnits,2)
	N_UNITS= STR(NUNITS,4,2)

ELSE
	N_UNITS=STR(0)
ENDIF


IF VAL(ALLTRIM(N_UNITS))=VAL("0")
		RETURN
ENDIF

IF EMPTY(ALLTRIM(cdate))
cdate=DTOC(DATE())
endif

CSQL =""
CSQL= "Exec dbo.gfAddTxn '" + cdate+  "', '" ;
	+ LEFT(FIXQUOTE(CDESCRIPT) ,50)+ "','" + PC_CLCODE + "',' " ;
	+ ALLTRIM(STR(NTXN_CODE)) + "','"  + ALLTRIM(STR(NTAGNUM)) + "','" ;
	+ NVL(ALLTRIM(CMAILID),"") + "','" + N_UNITS + "','" ;
	+ ALLTRIM(STR(0)) + "','" +  "" + "','" ;
	+ ALLTRIM(STR(0)) + "', '"  + "" + "','" ;
	+ "A" + "','" ;
	+ ALLTRIM(PC_USERID) + "','" ;
	+ REQUEST.id_tblRequests +"'"
L_OK=OMEDT.SQLEXECUTE(CSQL,"")

IF !EMPTY(cMemo)

	IF USED('EntryID')
		SELECT EntryID
		USE
	ENDIF
		
	l_EntryID=OMEDT.sqlexecute("select dbo.fn_GetID_tblTimesheet ('" + PC_CLCODE + "','" ;
		+ STR(NTAGNUM) +"','" + STR(NTXN_CODE)+ "','" +cdate +"')", "EntryId")
	IF l_EntryID 
	CSQL =""
	CSQL="Exec DBO.gfAddCom '" + cdate+  "', '" ;
			+ LEFT(FIXQUOTE(CDESCRIPT) ,50) + "','" + PC_CLCODE + "',' " ;
			+ ALLTRIM(STR(NTXN_CODE)) + "','"  + ALLTRIM(STR(NTAGNUM)) + "','" ;
			+ NVL(CMAILID,"") + "','" + "" + "','" ;
			+ fixquote(NVL(cMemo,""))  + "','"  ;
			+ ALLTRIM(STR(0)) + "','"  ;
			+ ALLTRIM(PC_USERID) + "','" + EntryID.EXP +"'"
			
		l_Comm=oMedT.sqlexecute(CSQL)

		L_OK=l_Comm
	ENDIF

ENDIF

RELEASE OMEDT
RETURN L_OK



************************************************************************
FUNCTION GETTHEFILE
PARAMETERS LCFILE
************************************************************************
LNCURAREA=SELECT()

LCCURR=SYS(5) +SYS(2003)
LCDEFAULT=ALLTRIM(ADDBS(MLPRIPRO("R", "RTS.INI", "Data","cTemp", "\")))
SET DEFAULT TO &lcDefault


lcFileName = ''
*lcFile=GETFILE("XLS","Load Batch List")
IF NOT EMPTY(ALLTRIM(LCFILE))
	LOCAL n_div AS INTEGER, c_dir AS STRING
	n_div=0
	c_dir =""
	n_div =RAT("\",lcfile,1)
	c_dir =LEFT(lcfile, n_div)
	lcFile="'"+ALLTRIM(lcFile)+"'"
** CALL LOADEXCEL INSTEAD OF IMPORT?


	IMPORT FROM &lcFile XL5
	lcFileName=DBF()
	USE
	SET DEFAULT TO &lcCURR
	lcFileName="'"+ALLTRIM(lcFileName)+"'"

	USE &lcFileName ALIAS LISTISSUE EXCLUSIVE
	GO TOP
	DELETE NEXT 1
	INDEX ON A TAG lrs_no ADDITIVE
	SELECT LISTISSUE
	USE
ELSE

	SET DEFAULT TO &lcCURR
ENDIF && EMPTY
IF NOT EMPTY(lnCurArea)
	SELECT (lnCurArea)
ENDIF

RETURN (lcFileName)

********************************************************

***************************************************88
FUNCTION GETunits
LPARAMETERS ln_type, lc_value
LOCAL lsUnits, lc_time
IF TYPE('lc_value')="C"
   lc_value=VAL(lc_value)
ENDIF    


IF ln_type=1	
	lsUnits=lc_value
	IF lsUnits>0
	   lsUnits=(lsUnits)/60
	ENDIF
	lc_minutes=ALLTRIM(STR(lsUnits-INT(lsUnits),10,2))	
	IF INLIST( RIGHT( lc_minutes, 1), "1", "2", "3", "4")
	   lsUnits=ROUND(lsUnits,1)+0.1
	ELSE                   
	   lsUnits=ROUND(lsUnits,1)
	ENDIF          
ENDIF
IF ln_type=2
   lsUnits=IIF(lc_value>0, lc_value/60, 0)
ENDIF
RETURN lsUnits   



*********************************************************************************************
FUNCTION GETTMPFILE
PARAMETERS CTEMPFILE
PRIVATE C_FILE AS STRING
*c_tempFile="\ListIssue_1.xls"
C_ROOT=SYS(5) + "\"
N_NUM1=1

N_FILES = ADIR(A_FILES, C_ROOT +ALLTRIM(UPPER(CTEMPFILE)))
IF N_FILES > 0
	=ASORT(A_FILES)
	N_NUM1 =GETNUMBER(A_FILES(ALEN(A_FILES,1), 1), LEN(ALLTRIM("ListIssue_")))
ENDIF
C_FILE=LEFT(CTEMPFILE,LEN(CTEMPFILE)-5) + ALLTRIM(STR(N_NUM1+1)) +".xls"
RETURN C_FILE
*********************************************************************************************

PROCEDURE CLEARTMP

IF USED('ListIssue')
	SELECT  LISTISSUE
	USE
ENDIF

RETURN
*******************************************************************************
