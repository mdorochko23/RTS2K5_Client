**************************************************************
*checks if uploaded images have been processed by qcer
**************************************************************

PARAMETERS  n_ordnum
LOCAL  OMED AS OBJECt, c_CurArea AS String, l_ok as Boolean
c_CurArea=ALIAS()
_SCREEN.MOUSEPOINTER=11
PRIVATE OMED AS OBJECT
OMED=CREATEOBJECT("generic.medgeneric")
l_ok=.t.
omed.closealias("WebImgs")


IF NOT EMPTY(n_ordnum)
		lc_sql=""		
		*lc_sql ="exec  [dbo].[qc_CheckUploads] '" +ALLTRIM(n_ordnum) + "'"
		lc_sql ="exec   [dbo].[qc_CheckProcessedUploads]  '" +ALLTRIM(n_ordnum) + "'"
		omed.SQLEXECUTE( lc_sql,"WebImgs")
		IF !EOF()
		SELECT WebImgs
			IF NVL(WebImgs.filenum ,0)<>0
				GFMESSAGE( "That order has uploaded images, please preview and then continue with an order."  )

			l_ok=.f.
			ENDIF

		ENDIF

ENDIF

 RELEASE OMED
IF NOT EMPTY(c_CurArea )
SELECT (c_CurArea )
ENDIF

RETURN l_ok