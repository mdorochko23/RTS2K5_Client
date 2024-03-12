**EF 03/29/07 - Added a tag 0 for the move check option/Added casedeponent.frmgettag.
**EF 06/16/05 -gets tags to copy scanned docs from to a new tag.
**Called by the 'Add New' on the frmadddeponent
*********************************************************************

PARAMETERS cClcode, l_show0tag
LOCAL nPickTag as Number, loGetTag as Object 
nPickTag =-1

loGetTag=CREATEOBJECT("casedeponent.frmgettag", cClcode, l_show0tag)
loGetTag.show
nPickTag=loGetTag.xRetVal
loGetTag.release


*!*	nPickTag =0
*!*	oMed = CREATEOBJECT("generic.medgeneric")
*!*	c_code=oMed.cleanstring(cClcode)
*!*	c_sql="Select Descript as name, tag, status as StatusName from tblRequest " ;
*!*	+ " with (NOLOCK,index(IX_tblRequests_2)) Where cL_code =" +  c_code  ;
*!*	+ " and active=1 Order by tag"
*!*	l_Request = oMed.sqlexecute(c_sql,"RequestPick")

*!*	INSERT INTO RequestPick VALUES ('',0,'')

*!*	IF NOT l_Request THEN
*!*	 gfmessage("No Tag was found")
*!*	RETURN
*!*	ENDIF

*!*	SELECT RequestPick
*!*	GO top
*!*	SET SAFETY OFF
*!*	cFile = SYS(5) +  "\ALLTAGS.dbf"
*!*	SELECT .F. AS SELECT, name, STATUSname, TAG ;
*!*		FROM requestpick ;
*!*		ORDER BY TAG ;  
*!*		INTO TABLE &cFile


*!*	SET SAFETY ON
*!*	SELECT AllTags
*!*	GO TOP
*!*	DEFINE WINDOW w_tags FROM 22,35 TO 39,87;
*!*		FONT "Arial",9 COLOR SCHEME 10 ;
*!*		CLOSE FLOAT GROW ZOOM 

*!*	ON KEY LABEL "Esc"
*!*	ON KEY LABEL "Ctrl+W"
*!*	BROWSE FIELDS ;
*!*		SELECT  :H= "Select" :P=.T., ;
*!*		TAG :R :H="Tag", name :45 :R :H=SPAC(2) + "Deponent", ;
*!*		StatusName :R :H="Status" ;
*!*		FREEZE SELECT ;
*!*		TITLE " <T/F> to Select/Deselect; <Ctrl+W> to Save; <Esc> to Cancel " ;
*!*		WINDOW w_tags
*!*	DEACTIVATE WINDOW w_tags
*!*	RELEASE WINDOW w_tags

*!*	IF LASTKEY() = 27 &&Esc key
*!*		DO clrtmp WITH cFile

*!*	ELSE
*!*		SELECT AllTags
*!*		GOTO TOP
*!*		SCAN FOR SELECT
*!*			nPickTag =AllTags.TAG
*!*			SELECT AllTags
*!*		ENDSCAN
*!*	ENDIF

*!*	DO clrtmp WITH cFile

*!*	*SET DATASESSION TO lndataId

RETURN nPickTag
*****************************************************************
PROCEDURE clrtmp
PARAMETERS lcTmpFile


IF FILE (lcTmpFile)
	SELECT AllTags
	USE
	DELETE FILE (lcTmpFile)
ENDIF

RETURN

