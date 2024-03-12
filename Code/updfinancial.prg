*FUNCTION updFinancial
*11/17/2021 #255663  WY (update tblQCExtraTagData.financial)
PARAMETERS tnIdTblQcExtraTagData, tnLrsNo, tnTag, tnFinancial, tcUser

LOCAL loMed as object, lcSql as string
loMed=CREATEOBJECT("generic.medgeneric")
lcSql = " exec [dbo].[UpdateFinanical] " + ALLTRIM(STR(tnIdTblQcExtraTagData)) + "," + ;
						+ ALLTRIM(STR(tnLrsNo)) + ", " + ALLTRIM(STR(tnTag)) + ", " + ;
	 					ALLTRIM(STR(tnFinancial)) + ", '" + Alltrim(tcUser) + "'"
loMed.SqlExecute(lcSql, '')
RELEASE loMed 

