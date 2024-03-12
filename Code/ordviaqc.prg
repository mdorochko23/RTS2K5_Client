**PROCEDURE ordersviaqc
**08/17/2012- Adds orders to the RTS for tags ordered via web
PARAMETERS cclcode

LOCAL c_str as String, loMedQ as Object, c_alias as String

loMedQ=CREATEOBJECT("request.medrequest")
STORE "" TO c_alias, c_str
c_alias=ALIAS()
loMedQ.closealias("Tags")
c_str=" exec dbo.GetNotIssTags '" +cclcode + "'"

loMedQ.Sqlexecute(c_str, "Tags")
IF USED("Tags")
 SELECT Tags
 
 SCAN 
*!*			loMedQ.closealias("OrdTags")
*!*	 		c_str=" select [dbo].[CheckOrderExistence] ('" + cclcode + "','" + IIF(TYPE("Tags.tag")="C", Tags.tag,STR(Tags.tag)) + "')"
*!*			loMedQ.Sqlexecute(c_str, "OrdTags")
*!*			
*!*			IF NVL(OrdTags.EXP,0)=0 
 			DO setordtg WITH IIF(TYPE("Tags.tag")="C", VAL(Tags.tag),Tags.tag)
*!*	 		endif
 
 SELECT Tags
 ENDSCAN



ENDIF

RELEASE loMedQ
IF NOT EMPTY(c_alias)
SELECT (c_alias)
ENDIF

return