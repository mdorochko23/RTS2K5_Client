**FUNCTION FillCAaff
PARAMETERS  c_dept, c_cert

IF EMPTY(ALLTRIM(c_cert))
* Determine which form is to be used by dept type (old way)
	DO CASE
	CASE c_dept = "R"
		DO fillaffidavit WITH "R","B","Y", "D", "G", "1","3","5"
*!*		DO PrintField WITH mv, "What", "R"
*!*		DO PrintField WITH mv, "What2", "B"
*!*		DO PrintField WITH mv, "What3", "Y"
*!*		DO PrintField WITH mv, "What4", "D"
*!*		DO PrintField WITH mv, "What5", "G"
*!*		DO PrintField WITH mv, "Tense1", "1"
*!*		DO PrintField WITH mv, "Tense2", "3"
*!*		DO PrintField WITH mv, "Tense3", "5"

	CASE c_dept = "P"
		DO fillaffidavit WITH "P","C","Z", "E", "H", "2","4","6"


	OTHERWISE
		DO fillaffidavit WITH "M","A","X", "A", "F", "1","3","5"

	ENDCASE
ELSE

	DO CASE
	CASE c_cert= "X"
		DO fillaffidavit WITH "R","B","Y", "D", "G", "1","3","5"

	CASE c_cert = "P"
		DO fillaffidavit WITH "P","C","Z", "E", "H", "2","4","6"

	OTHERWISE
		DO fillaffidavit WITH "M","A","X", "A", "F", "1","3","5"
	ENDCASE






ENDIF

***************************************************************************
PROCEDURE fillaffidavit

PARAMETERS cWhat, cWhat2, cWhat3, cWhat4, cWhat5, cTense1,cTense2, cTense3

DO PrintField WITH mv, "What", cWhat
DO PrintField WITH mv, "What2", cWhat2
DO PrintField WITH mv, "What3", cWhat3
DO PrintField WITH mv, "What4", cWhat4
DO PrintField WITH mv, "What5", cWhat5
DO PrintField WITH mv, "Tense1", cTense1
DO PrintField WITH mv, "Tense2", cTense2
DO PrintField WITH mv, "Tense3", cTense3

RETURN


