FUNCTION FixQuote
* 9/12/08 - REMOVE NON-ASCI
* Original code 11/8/05 DMA
* Accepts an input string, and converts all free-standing single-quote marks
* into pairs of single-quotes for passing into SQL.
LPARAMETERS	InString AS String
LOCAL OutString	AS String
IF AT ("'", InString) = 0
	RETURN InString
ENDIF
* If the string already includes any adjacent pairs of single quotes,
* temporarily replace them with the Ctrl-A character
*9/12/08 OutString = STRTRAN( InString, "''", CHR(01))
OutString = STRTRAN( InString, "''", "'")
* Next, convert individual single quotes to pairs
OutString = STRTRAN( OutString, "'", "''")
* Finally, restore the previously-existing pairs, if any
**9/12/08OutString = STRTRAN( OutString, CHR(01), "''")
RETURN OutString
