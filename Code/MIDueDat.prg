******************************************************************************
* Calculate the due date for MI subpoenas by skipping 28 business days
******************************************************************************
*FUNCTION MIDueDat
PARAMETERS ld_start
PRIVATE icnt, ldStart, ldEnd

ldStart = gfChkDat( ld_start, .F., .F.)
** 12/10/03 IZ changed from 28 to 14 by Megan's request
ldEnd = gfChkDat( ldStart+14, .F., .F.)
RETURN ldEnd
