#INCLUDE APP.H
********************************************************************
* This procedure will examine if any visible forms are instantiated
* and display an optional error if there are.
********************************************************************
LPARAMETERS p_lNoMsg
LOCAL l_nCnt,l_o, lbRetval

lbRetval = .F.
*--Are we Formless?--*
FOR l_nCnt=1 TO _screen.formcount
  l_o = _screen.forms(l_nCnt)
  IF (((UPPER(l_o.baseclass) != "TOOLBAR") ;
  		AND (UPPER(l_o.Class) != "FRMSPLASH")) ;
  		AND (l_o.visible=.T.))
		IF NOT p_lNoMsg
	    =gfmessage(APP_NOTAVAILFORMS)
*--	    =MESSAGEBOX(APP_NOTAVAILFORMS, MB_ICONSTOP, APP_NAME)
    ENDIF
		lbRetval = .T.	    
  ENDIF
ENDFOR
RETURN lbRetval

**EOF**
