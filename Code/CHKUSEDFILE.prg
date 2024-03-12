**PROCEDURE CHKUSEDFILE
PARAMETERS cfile, ccall
N_LTAG =PN_TAG
IF NOT USED(cfile)
	DO addlogline  WITH  N_LTAG,  "_" +cfile+ " does not exist ", " call place:" + ccall
ENDIF

RETURN

