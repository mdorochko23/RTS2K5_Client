*****************************************************************************
* gfMailn.prg - return rolodex name for a mailid
*
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
* 02/03/98  HN    Initial release
* Called by AFaxRMD, BillCovr, Code30B, gfMailPh, PrtTxLg,
*           PrtTxQst, RepRqCov, Subp_CA, Subp_Lib, Subp_PA, TXReprin
*****************************************************************************
LPARAMETER lcMailid
LOCAL lcCode, lcMailf

lcCode = UPPER(LEFT(lcMailid,1))
DO CASE
	CASE lcCode = "H"
		lcMailf = "MAILH"
	CASE lcCode = "A"
		lcMailf = "MAILA"
	CASE lcCode = "E"
		lcMailf = "MAILE"
	OTHERWISE
		lcMailf = "MAILD"
ENDCASE
RETURN lcMailf
