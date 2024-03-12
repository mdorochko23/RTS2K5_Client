FUNCTION gfIsGlobal
* Returns .T. if user is working in global-view mode for the item created
* by office code ThisOffice. The value of ThisOffice can come from 
* tblMaster.lrs_NoCode, or from the Source field in a rolodex or other 
* lookup file. Returns .F. if the item is local for the user.
*	DMA	10/20/05	Initial code

LPARAMETERS ThisOffice AS Character 

LOCAL 	lCWorkOffice AS Character, ;
		lReturn AS Logical

lReturn = .T. 
lcWorkOffice = goApp.CurrentUser.oRec.OfficeCode

IF ThisOffice = lcWorkOffice
	lReturn = .F.
ELSE
	*/ KoP users can work on cases from Maryland, Pittsburgh,
	*/ Kentucky, and Texas offices
	IF lcWorkOffice = "P" AND ;
		INLIST( ThisOffice, "G", "M", "K", "T") THEN
		lReturn = .F.
	ENDIF
ENDIF
RETURN lReturn