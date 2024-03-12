PROCEDURE printbarcode
PARAMETERS lnSelection
LOCAL lcRTNum, lcOffice
DIMENSION arbline[3]
EXTERNAL ARRAY artext

lcRTNum=GOAPP.TEmpmastercaseformreference.CASEHEADER1.TXtRTNum.Value 
omed=CREATEOBJECT('medgeneric')
omed.sqlexecute("SELECT lrs_nocode FROM tblmaster WHERE lrs_no=&lcRTNum. AND active=1 AND deleted IS null","master")
IF RECCOUNT('master')>0
*!*	lcOffice=GOAPP.CUrrentuser.ORec.OfficeCode
*!*	pl_KoPVer=.T.
*!*	pl_CAVer=.F.
*!*	IF INLIST(ALLTRIM(UPPER(lcOffice)),"C","S")
*!*	   pl_KoPVer=.F.
*!*	   pl_CAVer=.T.
*!*	ENDIF    

	n_Tag=0
	pn_tag=0
	pl_KoPVer=.T.
	pl_CAVer=.F.
	IF INLIST(ALLTRIM(UPPER(master.lrs_nocode)),"S","C")
	   pl_KoPVer=.F.
	   pl_CAVer=.T.
	ENDIF

	arbline[1]="001"
*--	arbline[1]="000"
	arbline[2] = ALLTRIM(lcRTNum)
	&& Check Length of LRS_No
	IF LEN( arbline[2]) < 8
	   arbline[2] = arbline[2] + REPLICATE( "-", 8 - LEN( arbline[2]))
	ENDIF
	arbline[3]=PADL(ALLTRIM(STR(lnSelection)),3,"0") 
	DO lfPrtCode IN PrintCov WITH arbline
ENDIF
IF USED('master')
	USE IN master
ENDIF
RETURN 
