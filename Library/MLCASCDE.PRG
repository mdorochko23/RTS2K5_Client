*:****************************************************************************
*:
*: PROCEDURE   - MLCASCDE
*:
*: Description: Cascades all non-minimized forms on the screen
*:
*: Parameters : None
*:
*: Return Val : None
*:
*: Example    : 
*:              DO MLTile
*:
*:****************************************************************************
LOCAL l_nCnt,l_nMode,l_nTot,l_nSize,l_nSizeW,l_nSizeH,l_oFrm,l_nOffset

l_nTot = _screen.formcount

IF (l_nTot > 0)

  *--Save the Screen--*
  l_nMode = _screen.scalemode
  _screen.scalemode = 3
  _screen.lockscreen = .T.

  *--Get System Metrics--*
  l_nSize  = SYSM(9)
  l_nSizeW = l_nSize+SYSM(3)
  l_nSizeH = l_nSize+SYSM(4)
  l_nOffset= -1

  FOR l_nCnt=1 TO l_nTot
    l_oFrm = _screen.forms(l_nCnt)
    IF (TYPE("l_oFrm.windowstate")!="U") AND (l_oFrm.windowstate != 1) AND ;
       (l_oFrm.visible = .T.)
      l_nOffset = (l_nOffset+1)
      l_oFrm.move((l_nOffset*l_nSizeW),(l_nOffset*l_nSizeH))
    ENDIF
  ENDFOR

  *--Restore the Screen--*
  _screen.lockscreen = .F.
  _screen.scalemode = l_nMode

ENDIF

**EOF**
