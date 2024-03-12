***************************************************************************
**Print Flavioring/Popcorn2 doc


DO PrintGroup WITH mv, "FGenPage"
DO PrintField WITH mv, "Name", pc_plnam
DO PrintField WITH mv, "Caption",pc_plcaptn

IF TYPE('pd_pldob')<>"C"
	pd_pldob=DTOC(pd_pldob)
ENDIF
IF TYPE('pd_pldod')<>"C"
	pd_pldod=DTOC(pd_pldod)
ENDIF

DO PrintField WITH mv, "PlaintiffDOB", LEFT(pd_pldob,10)
DO PrintField WITH mv, "PlaintiffSSN", ALLT( pc_plssn)

WAIT WINDOW "Flavoring  General doc .. printing.." NOWAIT

RETURN


