*------------------------------------------------------------*
*// SQL stored procedure scripting utility.
*//
*// 	E.g. = Util_Script(1, "Employee")
*// 			 = Util_Script(1, "Deposits", "Deposit", "DepositKey")
*//
*//	Parameters:
*//
*//		tiType - Type of stored procedure to generate.
*//							1) Put (Note: ONLY option supported as of 2004.12.03)
*//
*//		tsTable - Actual table name that stored procedure is 
*//							generated for.
*//
*//		tsTAlias - Optional table alias name to be used for the 
*//							 generated code.  If left empty, tsTable will be used.
*//
*//		tsPKey - Optional primary key field name to be used for the 
*//						 generated code.  If left empty, tsTable + "Key" 
*//						 will be used.
*//
*// Note: This is a developer utility.
*//				
*//				tsTable and/or tsTAlias is case sensitive with regard 
*//				to the generated code only.
*//
*------------------------------------------------------------*
LParameters tiType, tsTable, tsTAlias, tsPKey
Local lbOK, liConn, lsSQL, lsFile

#DEFINE CONN_STR		"driver=SQL Server;server=meiudsql02;database=RecordTrak"

*//Cleanup parameters
tiType = 1  && Hard code for now
tsTable = IIf((Type("tsTable") == "C"), AllTrim(tsTable), "")
tsTAlias = IIf((Type("tsTAlias") == "C"), AllTrim(tsTAlias), tsTable)
tsPKey = IIf((Type("tsPKey") == "C"), AllTrim(tsPKey), (tsTable + "Key"))

*//Default values
lbOK = .T.

*//Validate parameters
If lbOK

	lbOK = InList(tiType, 1)
	If !lbOK
		=gfmessage("Invalid Type specified: " + AllTrim(Str(tiType)))
*--		= MessageBox("Invalid Type specified: " + AllTrim(Str(tiType)), 16)
	Endif

Endif

If lbOK

	lbOK = !Empty(tsTable)
	If !lbOK
		=gfmessage("Table name cannot be empty.")
*--		= MessageBox("Table name cannot be empty."), 16)
	Endif

Endif

If lbOK

	*//Build file name
	Do Case
	Case (tiType == 1)
		lsFile = "Put" + tsTAlias + ".sql"
	EndCase

	*//Attempt to connect
	liConn = SQLStringConnect(CONN_STR)

	If liConn > 0

		*//Build SQL statement to retrieve table definition for specified table
		lsSQL = "select f.[name] as field_name, d.[name] as data_type, f.length, f.xprec, f.xscale " + ;
						"	from sysobjects t " + ;
						" inner join syscolumns f on t.id = f.id " + ;
						" inner join systypes d on f.xtype = d.xtype " + ;
						" where t.[name] = '" + tsTable + "'" + ;
						"	order by f.colid "

		If SQLExec(1, lsSQL, "c_TableDef") > 0
			
			*//Script stored procedure
			Do Case
			Case (tiType == 1)
				= ScriptPut(lsFile, tsTable, tsTAlias, tsPKey)
			EndCase
			
			
			Modify File (lsFile) NoWait
		
		Else
			=gfmessage("Error in SQL:"+lsSQL)
*--			= MessageBox(lsSQL, 16, "Error - Bad SQL")

		Endif	

		*//Disconnect
		= SQLDisconnect(liConn)

	Else
		
		=gfmessage("Unable to connect.")
*--		= MessageBox("Unable to connect.", 16)
		
	Endif

Endif

**************************************************************
Procedure ScriptPut
LParameters tsFile, tsTable, tsTAlias, tsPKey
Local lsProcName, lsDateStamp, lbFirstFieldIsPK

*//Default values
lbFirstFieldIsPK = .F.
lsProcName = "Put" + tsTAlias
lsDateStamp = AllTrim(Str(Year(Date()))) + "." + ;
							PadL(AllTrim(Str(Month(Date()))), 2, "0") + "." + ;
							PadL(AllTrim(Str(Day(Date()))), 2, "0")

*//Make sure the table definition alias is selected
Select c_TableDef

*//Turn on text merging
Set TextMerge On NoShow
Set TextMerge To (tsFile)

\SET QUOTED_IDENTIFIER OFF 
\GO
\SET ANSI_NULLS OFF 
\GO
\
\
\
\CREATE     PROCEDURE dbo.<<lsProcName>>
\  @xml AS text = Null
\/******************************************************************************************
\
\	Name: 			  <<lsProcName>>
\
\	Purpose: 		  Saves/Inserts a <<tsTAlias>> record.
\	
\	Parameters:	  @xml - Contains the <<tsTAlias>> record.
\					
\	Common Usage:	Declare @xml
\								EXEC dbo.<<lsProcName>> @xml
\
\	Return:			  None
\
\	Dependencies: None
\
\	Comments:		  None
\
\	History:		  <<lsDateStamp>>		Util_Script   initial creation
\
\*******************************************************************************************/
\AS
\
\-- Control variables
\DECLARE @iFilterDoc int
\
\-- Data mapping variables
Scan
	\DECLARE @<<AllTrim(field_name) + Space(1) + GetDataType(data_type, length)>>
EndScan
\
\BEGIN
\
\	EXEC sp_xml_preparedocument @iFilterDoc OUTPUT, @xml
\
\	SELECT	
Scan
\				<<IIf(Recno() > 1, ", ", "	") + "@" + AllTrim(field_name)>> = <<GetFieldMapping(field_name, data_type)>>
EndScan
\	FROM OPENXML (@iFilterDoc, '/VFPDataSet/<<lower(tsTAlias)>>', 2) 
\     WITH (
Scan
\					<<IIf(Recno() > 1, ", ", "	") + Lower(AllTrim(field_name))>> <<GetXMLDataType(data_type, length)>>
EndScan
\					)
\
\  IF @<<tsPKey>> IS NULL
\
\		BEGIN
\
\			-- Generate new primary key
\    	SET @<<tsPKey>> = NewID()
\
\			-- Insert record
\			INSERT INTO <<tsTable>>
\					(
Scan
\					<<IIf(Recno() > 1, ", ", "	") + "[" + AllTrim(field_name) + "]">>
EndScan
\					)
\				VALUES 
\					(
Scan
\					<<IIf(Recno() > 1, ", ", "	") + "@" + AllTrim(field_name)>>
EndScan
\					)
\
\    END
\    
\  ELSE
\  
\    BEGIN
\
\			-- Update record
\			UPDATE <<tsTable>> SET
Scan
	*//Ignore the primary key field
	If Upper(AllTrim(field_name)) == Upper(AllTrim(tsPKey))
		lbFirstFieldIsPK = (Recno() == 1)
	Else
\					<<IIf((Recno() > 1 And !lbFirstFieldIsPK) Or (Recno() > 2), ", ", "	") + "[" + AllTrim(field_name) + "]">> = @<<AllTrim(field_name)>>
	Endif
EndScan
\				WHERE <<tsPKey>> = @<<tsPKey>>
\
\    END
\
\	-- Return <<tsPKey>>
\	SELECT @<<tsPKey>> AS <<tsPKey>>
\
\	EXEC sp_xml_removedocument @iFilterDoc 
\
\END
\
\
\
\GO
\SET QUOTED_IDENTIFIER OFF 
\GO
\SET ANSI_NULLS ON 
\GO

Set TextMerge To
Set TextMerge Off

Return

**************************************************************
Procedure GetDataType
LParameters tsType, tiLength
Local lsType, lsDefinition

*//Default values
lsType = AllTrim(tsType)

Do Case
Case (Upper(lsType) == "CHAR")
	lsDefinition = (lsType + "(" + AllTrim(Str(tiLength)) + ")")
Case (Upper(lsType) == "TEXT")
	lsDefinition = ("varchar(8000)")
Case (Upper(lsType) == "VARCHAR")
	lsDefinition = (lsType + "(" + AllTrim(Str(tiLength)) + ")")
Otherwise
	lsDefinition = lsType
EndCase

Return lsDefinition

**************************************************************
Procedure GetXMLDataType
LParameters tsType, tiLength
Local lsType, lsDefinition

*//Default values
lsType = AllTrim(tsType)

Do Case
Case (Upper(lsType) == "BIT")
	lsDefinition = "varchar(5)"
Case (Upper(lsType) == "CHAR")
	lsDefinition = (lsType + "(" + AllTrim(Str(tiLength)) + ")")
Case (Upper(lsType) == "TEXT")
	lsDefinition = ("varchar(8000)")
Case (Upper(lsType) == "UNIQUEIDENTIFIER")
	lsDefinition = "varchar(36)"
Case (Upper(lsType) == "VARCHAR")
	lsDefinition = (lsType + "(" + AllTrim(Str(tiLength)) + ")")
Otherwise
	lsDefinition = lsType
EndCase

Return lsDefinition

**************************************************************
Procedure GetFieldMapping
LParameters tsName, tsType
Local lsType, lsName, lsMapping

*//Default values
lsName = AllTrim(tsName)
lsType = AllTrim(tsType)

Do Case
Case (Upper(lsType) == "BIT")
	lsMapping = "dbo.fn_CharToBit(" + lsName + ")"
Case (Upper(lsType) == "DATETIME")
	lsMapping = "dbo.fn_ScrubDate(" + lsName + ")"
Case (Upper(lsType) == "UNIQUEIDENTIFIER")
	lsMapping = "dbo.fn_CharToUniqueIdentifier(" + lsName + ")"
Otherwise
	lsMapping = lsName
EndCase

Return lsMapping
