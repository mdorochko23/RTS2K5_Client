PROCEDURE ReprtCer
**EF 5/9/06 -Added to the VFP project.
*******************************************************************************
***EF  04/29/2005 Fill global var for RPQJOBS file
***DMA 07/09/2004 Replace gsCertType with pc_CertTyp
***DMA 06/04/2004 Add call to gfGetDep to fill in tag-level global variables
***EF  04/30/2004  Fix a bug: update only selected record in the spec-ins file
***EF  04/17/2003  Add call to gfGetcas in order to fix a problem with
***              calling public var in printcer.
***EF  04/05/2001  Add an ability to update spec_ins file.
***EF  02/21/2001 reprtcer.prg - General RTS utilities.
**********************************************************************************
** Called by GenUtils
** Calls printcer.prg, ReprtCer.spr
***********************************************************************************
** Reprint a certification for RT/tag

l_OK=goapp.OpenForm("generic.frmreprtcer", "M")
*do updtype.spr

if NOT l_OK
	return
ENDIF





