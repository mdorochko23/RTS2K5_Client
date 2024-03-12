FUNCTION FormatBlurb
**EF 09/15/11 - ava1 needs an extra wide blurb
*
PARAMETERS m_memo, l_width, n_width
* m_memo is the memo field to be formatted
* c_width is the optional formatting width
PRIVATE n_lines, c_string, n_count, c_line, n_oldwidth,n_param
IF EMPTY( m_memo)
	RETURN ""
ENDIF
n_oldwidth = 0
*!*	IF pc_Litcode='AV1'
*!*		SET MEMOWIDTH TO 126
*!*	ENDIF 	
IF  L_width<>.F.
	n_param =PARAMETERS()
	IF n_param == 3
		n_oldwidth = SET ("MEMOWIDTH")		
		SET MEMOWIDTH TO n_width

	ENDIF
ENDIF
c_string = ""
n_lines = MEMLINES( m_memo)
FOR n_count = 1 TO n_lines
	c_line = MLINE( m_memo, n_count)
	IF NOT EMPTY( c_line) OR n_count <> n_lines
		c_string = c_string + c_line + CHR(13)
		
	ENDIF
ENDFOR
IF n_oldwidth > 0
	SET MEMOWIDTH TO n_oldwidth
ENDIF
RETURN c_string
