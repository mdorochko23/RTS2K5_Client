**PROCEDURE IssueNotc: called from the issuereq.prg, frmDeponentdetails.issuerequest
**3/03/2011 -EF- added pl_RisPCCP
**3/28/2011 -EF - Added pl_QCSameRT: generate notices without asking a question ;
while QCer works with the tags on the same RT.
**05/06/2011 - removed pl_QCSameRT- they wnat a question back.
PARAMETERS c_SSN, d_today1
LOCAL c_Alias AS STRING
PRIVATE oMed_n AS OBJECT
oMed_n=CREATEOBJECT("generic.medgeneric")
c_Alias=SELECT()
IF TYPE("pl_CivSubp")<>"L"
	pl_CivSubp=.F.
ENDIF
pl_StopPrtIss=.F.
LOCAL l_SendNot AS Boolean

l_SendNot=IIF(pl_Zicam , .T.,.F.)
pl_RepNotc=.F.

IF pl_CambAsb
&&EF -09/24/2010 -Cambria County-Asbstso only need one notice per a case -

*oMed_n.sqlexecute("Select count(tag) as cnt3 from tblPSNotice where cl_code ='" + pc_clcode + "' and active =1","CambriaNot")
	oMed_n.sqlexecute ("exec dbo.GetNoticeCount '" + pc_clcode + "'","CambriaNot")
	SELECT CambriaNot
	IF CambriaNot.cnt3>=1  && ONLY ONE ISSUE GETS NOTICED
		l_SendNot=.T.
	ENDIF


ENDIF



IF l_SendNot                    && force notices to be generated
	DO TheNotic WITH .F., c_SSN, d_today1, .F.
*!*	ELSE


*!*	&&06/22/11- removed a guestion and a process
*!*		IF NOT pl_CivSubp  AND NOT pl_CambAsb  AND NOT pl_RisPCCP

*!*	&&3/28/07 EF -skip civil/subp issues - SKIP CAMBRIA NOTICES(-09/24/2010)
*!*			IF gfmessage("Do you want to generate notices?",.T.)=.T.
*!*				_SCREEN.MOUSEPOINTER=11

*!*				DO TheNotic WITH .F., c_SSN, d_today1, .F.
*!*			ENDIF
*!*
*!*
*!*			_SCREEN.MOUSEPOINTER=0
*!*		ENDIF  &&3/28/07 EF -skip civil/subp issues

ENDIF

pl_prtnotc=.F.
RELEASE oMed_n
IF !EMPTY(c_Alias)
	SELECT(c_Alias)
ENDIF
RETURN
