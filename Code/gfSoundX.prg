PROCEDURE gfSoundX
*	Parameters:
*	c_input: A character string containing a name (typically of a firm
* or deponent from a rolodex file). Locates the first (leftmost) word
* in the string that is not on the hard-coded SoundEx exclusion list.

* 	Returns:
*	c_word: The leftmost word in the input string, if one was found, 
* or the null string if the leftmost word was not acceptable for Soundex.
*	c_input: The remainder of the original input string,
* so that recursive calls can be made.
*
PARAMETERS c_input, c_word
PRIVATE n_blank, i, l_reject
DIMENSION SkipWords [21] 
SkipWords[1]	= "THE"
SkipWords[2]	= "CO"
SkipWords[3]	= "AND"
SkipWords[4]	= "INC"
SkipWords[5]	= "CORP"
SkipWords[6]	= "OF"
SkipWords[7]	= "PC"
SkipWords[8]	= "CORPORATIO"
SkipWords[9]	= "ASSOC"
SkipWords[10]	= "ASSOCIATES"
SkipWords[11]	= "III"
SkipWords[12]	= "ET"
SkipWords[13]	= "AL"
SkipWords[14]	= "LLP"
SkipWords[15]	= "LAW"
SkipWords[16]	= "GROUP"
SkipWords[17]	= "OFFICE"
SkipWords[18]	= "OFFICES"
SkipWords[19]	= "FIRM"
SkipWords[20]	= "LLC"
SkipWords[21]	= "LPA"
n_blank = 0
c_word = ""
c_input = UPPER( ALLT( c_input))
c_input = CHRTRAN( c_input, "/\-.,!*", "")
DO WHILE .T.
	IF EMPTY(c_input)
		RETURN ""
	ENDIF
	n_blank = AT(" ", c_input)
	IF n_blank = 0
		c_word = c_input
		c_input = ""
	ELSE
		c_word = SUBS( c_input, 1, n_blank-1)
		c_input = LTRIM( SUBS( c_input, n_blank))
	ENDIF
	l_reject = .F.
	IF LEN( ALLT(c_word)) < 2
		l_reject = .T.
	ENDIF
	IF AT( '[', c_word) > 0 
		l_reject = .T.
	ENDIF
	FOR i = 1 TO ALEN( SkipWords)
   		IF c_word == SkipWords[i]
   			l_reject = .T.
   			EXIT
		ENDIF
	ENDFOR
	IF l_reject
		c_word = ""
	ENDIF
	RETURN c_word
ENDDO
