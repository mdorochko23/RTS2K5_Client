PARAMETERS c_type, l_screen
** Gets the special (Bill/med) blurbs for the BB cases - added in September of 2009
**l_screen=.t. when called from a RTS screen (when we print a text on a Attachment #3 page then we do not need to show the line1)
LOCAL oMedBlurb as Object, c_Comment as String, l_retval as Boolean
l_retval=.f.
c_Comment=""
_SCREEN.MOUSEPOINTER=11
oMedBlurb = CREATEOBJECT("generic.medgeneric")

IF USED('ExtraText')
	SELECT ExtraText
	USE
ENDIF
SELECT 0
*s_str= "Select *  from tblCaextrablurb  Where DeptType= '" + c_type + "' and active=1"
s_str= "exec dbo.GetCAExtraBlurbsbyDept '" +c_type + "'"
l_retval=oMedBlurb.sqlexecute (s_str, "ExtraText")

IF NOT l_retval
	gfmessage("Failed to get an extra blurb's text")
		RETURN
ENDIF

SELECT ExtraText
IF NOT EOF()	
	c_Comment =IIF(l_screen, ALLTRIM(NVL(ExtraText.line1,'')) + CHR(13) + CHR(10),"") +  ALLTRIM(NVL(ExtraText.line2,'')) + CHR(13)+ ALLTRIM(NVL(ExtraText.line3,'')) ;
	+ CHR(13)+ ALLTRIM(NVL(ExtraText.line4,'')) + CHR(13)+ALLTRIM(NVL(ExtraText.line5,'')) + CHR(13)+ ALLTRIM(NVL(ExtraText.line6,'')) + CHR(13)+ALLTRIM(NVL(ExtraText.line7,'')) ;
	+ CHR(13)+ ALLTRIM(NVL(ExtraText.line8,''))+ CHR(13) +ALLTRIM(NVL(ExtraText.line9,'')) + CHR(13)+ALLTRIM(NVL(ExtraText.line10,''))
ENDIF
	
RELEASE oMedBlurb
_SCREEN.MOUSEPOINTER=0

RETURN c_Comment