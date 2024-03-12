FUNCTION NewTag
** Newtag.prg - Determines next available tag number
**              and returns it to the calling program
** Tamaster must be open and should be placed on the case's record.
** Record.dbf and correct entryN.dbf should be open.
** Called by Subp_PA (during direct issue of a new tag),
**           AddRec (during initial creation of a new tag)
** Calls GFUse, GFUnUse, MastUpd
** Assumes that gfGetCas has been called

**  04/02/02 DMA Double-check TAMaster positioning
**  11/14/01 DMA Update public vbl pn_depcnt
**  09/25/00 DMA Add annotations; update global TAMaster
*-----------------------------------------------------------------
*- bellow code was commented 
*------------------------------------------------------------------
 
*!*	PRIVATE n_curtag, recused, n_nexttag, c_key,c_clcode c_str
*!*	oMed = CREATE("generic.medgeneric")
*!*	c_clcode=oMed.cleanstring(pc_clcode)
*!*	c_str= "SELECT subcnt FROM tblMaster WHERE cl_code =" + c_clcode
*!*	l_tagnum=oMed.sqlexecute(c_str,"TagMaster")
*!*	*  Get current tag count from file, not public variable, in case
*!*	*  another user is working in same case.
*!*	IF  NOT l_tagnum
*!*		gfmessage('Cannot get the tag number from the tblMAster. Contact IT. ')
*!*		RETURN
*!*	ELSE
*!*		n_curtag = TagMaster.SUBCNT
*!*		n_nexttag = n_curtag + 1
*!*	ENDIF

*!*	l_TSFile=oMed.sqlexecute( "select * from tblTimesheet where cl_code =" + c_clcode , "TimeSh")
*!*	SELECT Timesh
*!*	INDEX ON cl_code+STR(TAG) TAG cltag
*!*	IF NOT l_TSFile
*!*		gfmessage( 'Cannot open the tblTimesheet. Contact IT. ')
*!*		RETURN
*!*	ENDIF
*!*	** Note: Index tag "status" on Entry file applies a filter which only
*!*	**   allows the program to see records with Txn_Code = 11
*!*	** No longer used in this code, as it prevented program from seeing
*!*	** tags that were created but not yet issued. DMA 4/2/02
*!*	SELECT Timesh
*!*	DO WHILE .T.

*!*		l_RqId=oMed.sqlexecute( "select dbo.fn_GetID_tblRequest (" + c_clcode + ",'" +  STR(n_nexttag) + "')", "ReqsId")
*!*		IF NOT l_RqId
*!*			gfmessage( 'Cannot find the tag number in the tblRequest. Contact IT. ')
*!*			RETURN
*!*		ENDIF
*!*	*  Confirm that deponent is not in Record file.
*!*	*IF NOT SEEK( c_key)
*!*		IF ISNULL(ReqsId.EXP)
*!*			
*!*			SELECT Timesh
*!*			SET ORDER TO cltag
*!*	*     Confirm that there is no timesheet entry for the deponent
*!*				SEEK( PC_CLCODE+ STR(n_nexttag))
*!*				IF NOT FOUND()		
*!*	* SUCCESS: Update tag count IN master files
*!*	*          and in public variable pn_depcnt
*!*				c_str= "Update tblMaster set subcnt='" +  STR(n_nexttag) + "' Where cl_code = " + c_clcode 
*!*				l_TagCntUpd=oMed.sqlexecute(c_str , "ReqsId")
*!*				IF l_TagCntUpd
*!*					pn_depcnt = n_nexttag
*!*				ELSE
*!*					gfmessage( 'Cannot save a new Tag Number for the case. Contact IT. ')
*!*					RETURN
*!*				ENDIF
*!*				RETURN n_nexttag
*!*			ENDIF
*!*		ENDIF
*!*	*   Try the next sequential tag number
*!*		n_nexttag = n_nexttag + 1
*!*	ENDDO

*!*	RETURN 0
*------------------------------------------------------------------------------
*  end comments
*-------------------------------------------------------------------------------
LOCAL lnTag, lnCurArea
lnCurArea=SELECT()
oMed = CREATEOBJECT("generic.medgeneric")
oMed.sqlexecute("Select dbo.fn_GetNewTagNum( '" + ALLTRIM(pc_clcode) + "')","NewTagNum")
lnTag = Newtagnum.EXP
USE IN Newtagnum
SELECT (lnCurArea)
RETURN lnTag

