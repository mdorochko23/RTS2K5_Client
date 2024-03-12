PROCEDURE gfShowF2

** Display the stored comments for a deponent.
** Called by GetBlurb, Depopts
** Calls GfShowF2.SPR

** 06/13/03  DMA Don't put environment on stack until after file-open check
** 03/13/01  DMA Switch from DO WHILE to SCAN

LOCAL laEnv, l_commused, c_comment, c_commkey
DIMENSION laEnv[1,3]
l_commused = .F.
c_comment = ""
IF NOT USED( "Request")
	RETURN
ENDIF
=gfPush(@laEnv)
SELECT REQUEST
IF NOT EOF('Request')
	c_commkey = REQUEST.Cl_Code + STR( REQUEST.TAG)
*!*		l_commused = gfuse( "Comment")
	SET ORDER TO ClTag
	IF SEEK( c_commkey)
		SCAN WHILE COMMENT.Cl_Code = REQUEST.Cl_Code AND ;
				COMMENT.TAG = REQUEST.TAG
			IF INLIST( COMMENT.Txn_Code, 4, 12)
				c_comment = c_comment + COMMENT.COMMENT
			ENDIF
		ENDSCAN
	ENDIF
*!*		=gfunuse( "Comment", l_commused)
ENDIF
*!*	DO gfShowF2.spr WITH c_comment
=gfPop(@laEnv)
RETURN
