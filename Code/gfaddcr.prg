FUNCTION gfAddCR
**04/14//2017- Re-sized a blurb when priting to the rps  # 60943
**EF 12/19/05 - added to the SQL-RTS project.
****************************************************************************
* Converts a multi-line Memo field or string into a formatted character
* string by adding a carriage-return character [CHR(13)] at the end of
* each line. An optional parameter can be used to specify line width.
*
* Extracted from existing code in calling routines.
* Called by CaNotInf, Subp_PA, Subp_CA, ReAttch, PrintCer, PrtTXQst, TXReprin
* 05/27/03 DMA Original creation
*
PARAMETERS m_memo, n_width
* m_memo is the memo field to be formatted
* c_width is the optional formatting width
PRIVATE n_lines, c_string, n_count, c_line, n_oldwidth,n_param
IF EMPTY( m_memo)
	RETURN ""
ENDIF
n_oldwidth = 0
IF pc_Litcode='AV1'
	SET MEMOWIDTH TO 90
ENDIF
n_param =PARAMETERS()


IF  n_param =2
	IF TYPE('n_width')<>"N"
		n_width=70
	ENDIF
	IF n_param == 2
		n_oldwidth = SET ("MEMOWIDTH")
		SET MEMOWIDTH TO n_width
	ENDIF
ENDIF
c_string = ""
&& 08/14/2019 MD memlines removes CR/LF
*!*	n_lines = MEMLINES( m_memo)
*!*	FOR n_count = 1 TO n_lines
*!*		c_line = MLINE( m_memo, n_count)
*!*		IF NOT EMPTY( c_line) OR n_count <> n_lines
*!*			c_string = c_string + c_line + CHR(13)
*!*		ENDIF
*!*	ENDFOR

LOCAL laAr[1]
n_lines = ALINES(laAr, m_memo)
FOR n_count = 1 TO ALINES(laAr, m_memo )
 c_line = laAr[n_count]
 IF NOT EMPTY( c_line) OR n_count <> n_lines
	 c_string = c_string + c_line + CHR(13)+ CHR(10)
 ENDIF
ENDFOR

IF n_oldwidth > 0
	SET MEMOWIDTH TO n_oldwidth
ENDIF
RETURN c_string
