*--------------------------------------------------------------------
FUNCTION fOrigIss
*10/13/00 cert. issue
*--------------------------------------------------------------------
PARAMETERS lntag
LOCAL dIssue AS DATE, lgottag AS Boolean
lgottag=.F.


c_Alias = SELECT()
oMedTemp = CREATEOBJECT("generic.medgeneric")
dIssue={  /  /    }

lgottag=oMedTemp.sqlexecute("SELECT dbo.gfIssuDt('" + fixquote(pc_clcode) + "',' " +  STR(lntag ) + "')", "Timesheet2")

IF lgottag
	SELECT timesheet2
	dIssue=IIF(ISNULL(EXP),{  /  /    },CTOD(LEFT(DTOC(EXP),10)))
	SELECT timesheet2
	USE
	IF NOT USED('Timesheet')
		c_sql="exec  [dbo].[GetEntrybyClTag]'" + fixquote(pc_clcode) + "','" +ALLTRIM(STR(lntag) )+ "'"

		oMedTemp.sqlexecute(c_sql,'Timesheet')

		SELECT timesheet
		INDEX ON CL_code+STR(TAG)+STR(Txn_code) TAG AR ADDITIVE
		INDEX ON CL_code+"*"+STR(TAG) TAG cltag ADDITIVE
	ENDIF

	SELECT (c_Alias)
ELSE
	gfmessage("Cannot get Timesheet File Data.")
ENDIF
RELEASE oMedTemp
RETURN dIssue