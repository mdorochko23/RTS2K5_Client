**Function GetTxDWQ
**09/29/2017: edited to look at Request's data as well as txn 11's data
PARAMETERS  ccl , ntg
LOCAL lc_Alias AS STRING, lc_Type as string, l_retval as Boolean
LOCAL  omed as Object
lc_Alias=ALIAS()
omed=CREATEOBJECT('medgeneric')
********get a blurb's dwq
omed.closealias("txBlurb")
lc_Type=""
l_retval=.f.
l_retval=omed.sqlexecute("Exec [dbo].[GetTXDWQ2] '" + ccl  + "','" + STR(ntg) + "'", "txBlurb")

IF NOT l_retval
gfmessage("Failed to get a blurb's data.")
		RETURN
ENDIF

SELECT TxBlurb
IF NOT EOF()	
	lc_type=ALLTRIM(TxBlurb.DWQ)
ENDIF
	
IF NOT EMPTY(Lc_Alias)
	SELECT (lc_Alias)
ENDIF
RELEASE omed
RETURN lc_Type
