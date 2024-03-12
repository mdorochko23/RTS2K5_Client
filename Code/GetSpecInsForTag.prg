*FUNCTION GetSpecInsForTag
PARAMETERS n_tag
LOCAL oMedTMP AS OBJECT
WAIT WINDOW "Getting special instruction blurb.. Please wait" NOWAIT NOCLEAR
_SCREEN.MOUSEPOINTER=11
c_alias = ALIAS()
oMedTMP = CREATEOBJECT("generic.medgeneric")
c_EdtReq = ""
l_GetSpIns=oMedTMP.sqlexecute( " exec [dbo].[GetSpecInsByClCodeTag] '" + fixquote(pc_clcode) + "','" + STR(n_Tag) + "'", "Spec_ins")
IF NOT l_GetSpIns
	gfmessage("Cannot get Special Instruction Table. Contact IT dept.")
	RETURN
ENDIF
crequest = ALLTRIM(spec_ins.spec_inst)
c_EdtReq = gfAddCR( crequest)
RELEASE oMedTMP
RETURN c_EdtReq
