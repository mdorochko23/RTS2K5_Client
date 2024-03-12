*****************************************************************************************************************

* PROCEDURE AddMagnaFlds					&& 04/16/2020, ZD #168026, JH.

* called from forms:  qcaipjobs.frmIssue1, casedeponent.frmRequestDetails

* parameters:  either CL_CODE or LRS_No must be provided; tag; fromMagna=1 (set to Magna), =0 (clear).

* Will set tblRequest.web_order to 'Magna' or ''.

*****************************************************************************************************************

PARAMETERS pClCode,pLrsNo,pTag,pcFromMagna	&& Either one, pClCode or pLrsNo must be provided.  pnFromMagna: 1-set, 0=clear.

LOCAL OMED AS OBJECT, lnCurArea AS String, lsLrsNo as string, lsTag as string, lcSqlLine as string, lnRC as integer, lcErrMsg as string

_SCREEN.MOUSEPOINTER=11
PRIVATE OMED AS OBJECT

lnCurArea = ALIAS()

lsLrsNo = ""
IF NOT EMPTY(RTRIM(pLrsNo))
    IF TYPE("pLrsNo") = 'N'
       lsLrsNo = STR(pLrsNo)
    ELSE
       IF TYPE("pLRsNo") = 'C'
	       lsLrsNo = pLrsNo
       ELSE
	  GFMESSAGE('Invalid LrsNo parameter sent to AddMagnaFlds.  Must be Str or Int..')
	  _SCREEN.MOUSEPOINTER=0
	  RETURN
       ENDIF
    ENDIF
ELSE
    IF EMPTY(RTRIM(pClCode))
	  GFMESSAGE('Both Cl Code and LRS Number can not be blank for parameters sent to AddMagnaFlds.  One must be provided.')
	  _SCREEN.MOUSEPOINTER=0
	  RETURN
    ENDIF
ENDIF


lsTag = ""
IF TYPE("pTag") = 'N'
   lsTag = STR(pTag)
ELSE
   IF TYPE("pTag") = 'C'
      lsTag = pTag
   ELSE
      GFMESSAGE('Invalid Tag parameter sent to AddMagnaFlds.  Must be Str or Int..')
      SCREEN.MOUSEPOINTER=0
      RETURN
   ENDIF
ENDIF

OMED=CREATEOBJECT("generic.medgeneric")
SELECT 0

lcSqlLine="exec dbo.SetMagnaWebOrd '"+pCLCode+"','"+lsLrsNo+"','"+ALLTRIM(lsTag)+"','"+ALLTRIM(pcFromMagna)+"','"+AllTrim(PC_USERID)+"'"
OMED.SQLEXECUTE(LCSQLLINE,"UpdWebOrd")

_SCREEN.MOUSEPOINTER=0
if UpdWebOrd.retval != 0
   lcErrMsg = "Error "+STR(UpdWebOrd.retval)+" returned from SetMagnaWebOrd procedure."
   GFMESSAGE(lcErrMsg)
ENDIF
OMED.CloseAlias("UpdWebOrder")

SELECT (lnCurArea)  
RELEASE OMED
RETURN

******************************************************************************************
