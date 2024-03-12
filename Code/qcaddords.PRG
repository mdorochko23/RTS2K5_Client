**PROCEDURE qcaddords
**06/11/2012- Adds orders to the RTS for tags ordered via web
PARAMETERS c_webOrd

LOCAL c_str as String, loMedQ as Object, c_alias as String

loMedQ=CREATEOBJECT("request.medrequest")
STORE "" TO c_alias, c_str
c_alias=ALIAS()
loMedQ.closealias("qcTags")
c_str=" exec dbo.qc_GetQcTagbyWebOrder '" +c_webOrd + "'"

loMedQ.Sqlexecute(c_str, "qcTags")
IF USED("qcTags")
 SELECT qcTags
 
 SCAN 
 		DO setordtg WITH IIF(TYPE("qcTags.qc_tag")="C", VAL(qcTags.qc_tag),qcTags.qc_tag)
 
 SELECT qcTags
 ENDSCAN



ENDIF

RELEASE loMedQ
IF NOT EMPTY(c_alias)
SELECT (c_alias)
ENDIF

return