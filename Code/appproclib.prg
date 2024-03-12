#Include app.h

**********************************************************************************************
* Procedure....: ChgSysdata
* Called by...: Various programs
*
* Abstract....: Change a value of a non-table key value in SYSDATA table.
*
* Returns.....: RetVal - The value of the desired field & record from SYSDATA.
*
* Parameters..: tsFile - The lookup value cooresponding to SysData.File.
*								tsField - The field in SysData to change.
*								txValue - The new value to write to sysdata.
*
**********************************************************************************************
Procedure ChgSysdata
LParameters tsFile, tsField, txValue
Local loMediator

*//Instantiate the SysData mediator
loMediator = CreateObject("medSysData")

*//TEMPORARY LOGIC
*//TODO: Hookup stored procedure when available

Local lcSQL

lcSQL = ("Update [dbo].[sysdata] Set [" + ;
				 tsField + "] = " + SQLConvToStr(txValue) + ;
				 " Where [file] = " + SQLConvToStr(tsFile))

*//Retrieve record
loMediator.SQLExecute(lcSQL)

*//TEMPORARY LOGIC

Return

*EOF ChgSysdata
**********************************************************************************************

**********************************************************************************************
* Procedure....: GetSysdata
* Called by...: Various programs
*
* Abstract....: Return a value from the SYSDATA table.
*
* Returns.....: RetVal - The value of the desired field & record from SYSDATA.
*
* Parameters..: tsFile - The lookup value cooresponding to SysData.File.
*								txField - The field in SYSDATA to retrieve a value from.
*
**********************************************************************************************
Procedure GetSysData
LParameters tsFile, tsField
Local loMediator, lxRetVal

*//Instantiate the SysData mediator
loMediator = CreateObject("medSysData")

*//Retrieve record
loMediator.GetItem(tsFile)

*//Did we find our record?
If !IsNull(SysData.File)
	lxRetVal = &tsField.
Else
	Error "SysData record not found."
Endif

Return lxRetVal
*EOP GetSysdata

*____________________________________________________________________
*____________________________________________________________________
* Procedure: SQLConvToStr
*
*	Description: Formats a variant value so that is may be used for SQL Server pass-through.
*
* Returns: Character - Formatted value.
*
* Parameters: txValue - The value to be formatted.
*____________________________________________________________________
Procedure SQLConvToStr
LParameters txValue
Local lcDType, lcRetVal

*//Default values
lcRetVal = ""

*//Get the data type of the value that has been passed in.
lcDType = Type("txValue")

Do Case

Case IsNull(txValue)

	*//Add the NULL keyword
	lcRetVal = ("NULL")

Case (lcDType == T_CHARACTER)

	*//Add character delimiters
	lcRetVal = ("'" + txValue + "'")

Case (lcDType == T_DATE)

	*//Do we have an empty date value?
	If Empty(txValue)
	
		*//Use NULL
		lcRetVal = ("NULL")
	
	Else

		*//Convert to string and add date delimiters
		lcRetVal = ("'" + DToC(txValue) + "'")
	
	Endif

Case (lcDType == T_DATETIME)

	*//Do we have an empty datetime value?
	If Empty(txValue)
	
		*//Use NULL
		lcRetVal = ("NULL")
	
	Else
	
		*//Convert to string and add datetime delimiters
		lcRetVal = ("'" + TToC(txValue) + "'")
	
	Endif

Case InList(lcDType, T_NUMERIC, T_DOUBLE, T_CURRENCY)

	*//Convert to a string
	lcRetVal = Str(txValue, 20, 8)

Case (lcDType == T_LOGICAL)

	*//Convert to string and add date delimiters
	lcRetVal = IIf(txValue, "1", "0")

Otherwise

	Error ("Unsupported data type: " + lcDType)

EndCase

Return lcRetVal
*EOP SQLConvToStr

*____________________________________________________________________
*____________________________________________________________________
* Procedure: SQLExecute
*
*	Description: Generic SQLExec.
*
* Returns: None.
*
* Parameters: tsSQL - The SQL statement to execute.
*							tsAlias - [Optional] Result alias.
*
* Notes: All statements will be handled by the Administration mediator.
*____________________________________________________________________
Procedure SQLExecute
LParameters tsSQL, tsAlias
Local loMediator, lbSuccess

*//Create our administration mediator
loMediator = Create("medAdministration")

*//Execute our statement
lbSuccess = loMediator.SQLExecute(tsSQL, IIf((Type("tsAlias") == T_CHARACTER), tsAlias, loMediator.MasterAlias))

Return lbSuccess

*<cai_fpw26>
***********************************************************************************************
***********************************************************************************************
* Function....: OfficeName
* Called by...: Various Reports - to display the office name.   
*
* Abstract....: Returns Name of current office from sysdata.  Sysdata.Name is where we
*				store the name of the current office.
*
* Returns.....: Office Name - Character
*
* Parameters..: None.
*
* Notes.......:  Assumes sysdata is on the correct record - where file = "NYSBG".
*				 The intent for this routine is to be used on report forms underneath 
*				the nysbg/cai logo in the upper left corner of the reports - to display
*				which office the report was printed from.   All our reports are printed
*				by calling XREPORT, which in turn calls SYSTEMHEADER - which positions
*				sysdata on the record where file = "NYSBG".   SO, there is no need to
*				reposition sysdata, when it is used on reports.   If used somewhere
*				other than reports, the calling program must position sysdata correctly
*				in order to get the correct results from this function.
*
* Changes.....:	12/12/2003 - Changed this to display sysdata.Name.
***********************************************************************************************
Procedure OfficeName
Local lsName

lsName = SysData.Name

Return lsName

*<cai_fpw26>
***********************************************************************************************

*____________________________________________________________________
*____________________________________________________________________
* Procedure: AutoIncrement
*
*	Description: Increments an identity in the SYSDATA table.
*
* Returns: Integer - Newly incremented value.
*
* Parameters: tsFile - Identity value to increment.
*____________________________________________________________________
Procedure AutoIncrement
LParameters tsFile
Local lnRetval, lsSQL, loMediator

*//Build SQL statement
lsSQL = ("dbo.usp_AutoIncrement NULL" + ", " + ;
				 SQLConvToStr(tsFile) + ", " + ;
				 SQLConvToStr(1))

*//Get results
loMediator = Create("medAdministration")
loMediator.SQLExecute(lsSQL, "result")

*//Default values
lnRetval = result.NewNumber

Return lnRetval

*____________________________________________________________________
*____________________________________________________________________
* Procedure: CloseAlias
*
*	Description: Closes any open table/cursor in specified alias.
*
* Returns: None
*
* Parameters: tsAlias - Alias to close.
*____________________________________________________________________
Procedure CloseAlias
LParameters tsAlias

*//Alias in use?
If Used(tsAlias)
	
	*//Close it
	Use In (tsAlias)

Endif

*____________________________________________________________________
*____________________________________________________________________
* Procedure: DisplayKey
*
*	Description: Safely displays a primary/foriegn key value as a string.  
*							 Deals with eliminating NULL propagation.
*
* Returns: String - Primary key.
*
* Parameters: tsPK - Primary key.
*____________________________________________________________________
Procedure DisplayKey
LParameters tsPK
Local lsPK

If IsNull(tsPK)

	lsPK = "Value is NULL."

Else
	
	lsPK = tsPK

Endif

Return lsPK

*____________________________________________________________________
*____________________________________________________________________
* Procedure: IsEmptyKey
*
*	Description: Tests for an empty key value.
*
* Returns: Logical.
*
* Parameters: tsKey - Primary/Foriegn key value.
*
* Notes: Empty string or NULL results in an empty key.
*____________________________________________________________________
Procedure IsEmptyKey
LParameters tsKey
Local lbIsEmpty

*//Empty key value?
lbIsEmpty = IsNull(tsKey) Or Empty(tsKey)

Return lbIsEmpty

*____________________________________________________________________
*____________________________________________________________________
* Procedure: FirstOfMonthDate
*
*	Description: Returns a date value specifying the first of the month
*							 of the date value specified.
*
* Returns: Date - First of month.
*
* Parameters: tdDate - Date value.
*
*	Notes: Call the SQL Server user defined function fn_FirstOfMonthDate.
*____________________________________________________________________
Procedure FirstOfMonthDate
LParameters tdDate
Local ldFirstOfMonth, lsSQL, loMediator

*//Build SQL statement
lsSQL = ("Select dbo.fn_FirstOfMonthDate(" + SQLConvToStr(tdDate) + ") As FirstOfMonth")

*//Get results
loMediator = Create("medAdministration")
loMediator.SQLExecute(lsSQL, "result")

*//Default values
ldFirstOfMonth = TToD(result.FirstOfMonth)

Return ldFirstOfMonth
*____________________________________________________________________
*____________________________________________________________________
* Procedure: AddNote
*
*	Description: Adds a note to the notes table.
*
* Returns: None.
*
* Parameters: tsCompanyKey - Company key.
*							tsEmployeeKey - Employee key.
*							tsPassKey - User (pass) key.
*							tnCSRNumber - CSR code (number).
*							tsDept - Department (code).
*							tsNote - Note/message to be added.
*
*	Notes:
*____________________________________________________________________
Procedure AddNote
LParameters tsCompanyKey, tsEmployeeKey, tsPassKey, tnCSRNumber, tsDept, tsNote
Local lsCSReasonKey, lsDeptKey, lsSQL, ;
			loCSReason As medCSReason Of CSReason, ;
			loDept As medDept Of Dept

*//Cleanup parameters
tsCompanyKey = IIf(IsEmptyKey(tsCompanyKey), NULL, tsCompanyKey)
tsEmployeeKey = IIf(IsEmptyKey(tsEmployeeKey), NULL, tsEmployeeKey)
tsPassKey = IIf(IsEmptyKey(tsPassKey), NULL, tsPassKey)

*//Default values
lsCSReasonKey = NULL
lsDeptKey = NULL
loCSReason = Create("medCSReason")
loDept = Create("medDept")

*//Translate CSR code to a key value
If !Empty(tnCSRNumber)

	*//Lookup code
	If loCSReason.GetItemBy(MED_CSREASON_GET_ITEM_BY_NUMBER, tnCSRNumber)

		lsCSReasonKey = loCSReason.PrimaryKeyValue

	Endif

Endif

*//Translate Department to a key value
If !Empty(tsDept)

	*//Lookup code
	If loDept.GetItemBy(MED_DEPT_GET_ITEM_BY_DEPT, tsDept)

		lsDeptKey = loDept.PrimaryKeyValue

	Endif

Endif

*//Build SQL statement
lsSQL = ("dbo.usp_AddNote " + ;
				 SQLConvToStr(tsCompanyKey) + ", " + ;
				 SQLConvToStr(tsEmployeeKey) + ", " + ;
				 SQLConvToStr(tsPassKey) + ", " + ;
				 SQLConvToStr(lsDeptKey) + ", " + ;
				 SQLConvToStr(lsCSReasonKey) + ", " + ;
				 SQLConvToStr(tsNote))

*//Execute SQL
= SQLExecute(lsSQL)

Return

*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴*
* Function....: LongDate
* Called by...: -many-
*
* Abstract....: Returns long date, ie, February 14, 1995
*
* Returns.....: string
*
* Parameters..:
*
* Notes.......: restores previous SET CENTURY Setting.
*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴*
Procedure LongDate
LParameter txDate
Local lsLongDate, lsCurrSetCentury

*//Hold onto current SET CENTURY setting
lsCurrSetCentury = SYS(2001,'CENTURY')

If lsCurrSetCentury <> "ON"
	Set Century On
Endif

*//Convert to long date
lsLongDate = MDY(txDate)

*//Restore SET CENTURY setting
If lsCurrSetCentury <> "ON"
	Set Century Off
Endif

Return lsLongDate

***********************************************************************************************
* Function....: PreviousWorkDay
* Called by...: Various
*
* Abstract....: Return the Previous Work Day.   This takes into account weekends also.
*				If Today is Monday, it will return 3 days ago - Friday's Date.  If today
*				is not Monday, it simply returns 1 day prior to today as the date.
*				NOTE:  This does not take HOLIDAYS into account.
*
* Returns.....: The previous work day (as a date value).
*
* Parameters..: pdDate - The date to find the previous work day for.
*
* Notes.......:
***********************************************************************************************
Procedure PreviousWorkDay
LParameters pdDate
Local ldPreviousWork

ldPreviousWork = IIf(DOW(pdDate) = 2, pdDate-3, pdDate-1)

Return ldPreviousWork

*EOF PrevWorkDay
