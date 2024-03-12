*FUNCTION qc_getTagsNote
PARAMETERS l_webord, c_BBWebNo, nTag 
LOCAL l_retval as Boolean, c_tag as String
LOCAL o_SqlCon AS OBJECT
o_SqlCon = CREATEOBJ("generic.medgeneric")
l_retval=.f.
c_sql= ""
IF TYPE("nTag")="N"
c_tag=STR(ntag)
ELSE
c_tag=ALLTRIM(ntag)
ENDIF


o_SqlCon.closealias("TagNotes")
IF l_webord
	c_sql= "Select [dbo].[qc_GetExcelComments] ('" + c_BBWebNo + "')"
else  &&THISFORM.ExtraF2data OR THISFORM.extraexcldata
	c_sql= " exec [dbo].[qc_GetExtraTagNotes] '" + c_tag+ "','" + c_BBWebNo  + "'"

ENDIF
	
o_SqlCon.sqlexecute(c_sql, "TagNotes")

IF USED( "TagNotes")
SELECT TagNotes
IF NOT EOF() AND NOT EMPTY(ALLTRIM(NVL(TagNotes.EXP,'')))
	l_retval=.t.
endIf
ENDIF

RELEASE o_SqlCon

RETURN l_retval