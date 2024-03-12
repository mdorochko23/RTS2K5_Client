PARAMETERS c_lit as String, c_VALUE as String
LOCAL 	nmax AS Number,nmax2 AS Number, l_ok  as Boolean
STORE  18 TO nmax,nmax2
&&& 08/12/2013- BLURB FOR CIVIL =82

DO CASE 
CASE c_Lit='AV1'
	SET MEMOWIDTH TO 126
	nmax=19
	nmax2=18
CASE c_Lit='C'
	SET MEMOWIDTH TO 82
	nmax=18
	nmax2=17
OTHERWISE 
	SET MEMOWIDTH TO 68
	nmax=18
	nmax2=17
ENDCASE
l_ok =.t.
n_numlines = MEMLINES( ALLTRIM(c_VALUE))
IF n_numlines > nmax 
	gfmessage( "Max of "+ ALLTRIM(STR(nmax)) + " request lines allowed; you have " + ;
		ALLTRIM( STR( n_numlines))+ ". Press any key.")
	
	l_ok =.f.
ENDIF

*!*	IF n_numlines > nmax OR ;
*!*			(n_numlines = nmax2 AND NOT EMPTY( MLINE( ALLTRIM(c_VALUE), 7) ) )
*!*		gfmessage( "Max of "+ ALLTRIM(STR(nmax)) + " request lines allowed; you have " + ;
*!*			ALLTRIM( STR( n_numlines))+ ". Press any key.")
*!*		
*!*		l_ok =.f.
*!*	ENDIF
RETURN l_ok