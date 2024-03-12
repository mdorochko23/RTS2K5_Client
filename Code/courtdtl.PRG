**FUNCTION CourtDtl
**added as a part of the #5152 project 
PARAMETERS  c_court
LOCAL  OMED AS OBJECT,   lnCurArea AS STRING,  ll_NOLtr AS Boolean, lc_sql AS STRING
lnCurArea=ALIAS()
_SCREEN.MOUSEPOINTER=11
PRIVATE OMED AS OBJECT
OMED=CREATEOBJECT("generic.medgeneric")
SELECT 0

ll_NOLtr=.F.	&& default is to print RPS Rq Cover letter 
lc_sql= ""
OMED.closealias ('CourtDtl')
c_sql= "select dbo.CourtRtCoverStatus('" + fixquote(ALLTRIM(c_court))+ "')"
OMED.sqlexecute(c_sql, "CourtDtl")
IF USED('CourtDtl')
	SELECT CourtDtl
	ll_NOLtr=	NVL(CourtDtl.EXP,.F.)=.T.

ENDIF

_SCREEN.MOUSEPOINTER=0
RELEASE OMED

RETURN ll_NOLtr
