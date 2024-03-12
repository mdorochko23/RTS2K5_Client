************************************************************************************************
** EF 08/15/2017- addded Pl_TxCourt
** EF 04/07/2015 -do not copy "G"/"R" type files for tags
** MD 11/15/07 - Modified to pull PCX path according to the office
** EF 09/02/05 - Switched to SQL
** Copys original scanned documents to a new tag
*PROCEDURE cscandoc
************************************************************************************************

PARAMETERS lc_newtag, lc_Lrs, lc_tag
IF TYPE('lc_Lrs')='N'
	lc_Lrs=STR(lc_Lrs)
ENDIF

PRIVATE lc_PPath, lc_APath, laFilesP, laFilesA, lc_FileFrom, ;
	lc_FileTo, ll_ok
STORE "" TO  lc_PPath, lc_APath, lc_FileFrom, lc_FileTo
DIMENSION laFilesP[1], laFilesA[1]

STORE .F. TO ll_ok

F_PCX=IIF(pl_ofcoaK, goApp.capcx ,goApp.pcxpath)
F_PCXARCH=IIF(pl_ofcoaK,goApp.capcxarch,goApp.pcxarchpath)

lc_PPath = F_PCX + ALLTRIM(lc_Lrs) + "*." + PADL( ALLTRIM(  lc_tag), 3, "0")
lc_APath = F_PCXARCH + RIGHT( ALLTRIM(lc_Lrs), 1) + "\" + ALLTRIM(lc_Lrs) + + "*." + ;
	PADL( ALLTRIM( lc_tag), 3, "0")

IF NOT ADIR( laFilesP, lc_PPath) == 0
	FOR iv = 1 TO ALEN( laFilesP, 1)
		lc_FileFrom = F_PCX+ laFilesP[iv, 1]
&& do not copy "G"/"R" type files for tags

		IF   (ALLTRIM(lc_Lrs) +  "G"   $lc_FileFrom  OR  ALLTRIM(lc_Lrs) + "R" $lc_FileFrom  ) AND NOT pl_Reissue
			WAIT WINDOW "Do not copy a scanned signed subpoena file." NOWAIT
			ll_ok = .F.

		ELSE
			lc_FileTo = F_PCX + LEFT(laFilesP[iv, 1], (LEN( laFilesP[iv, 1]) - 4)) ;
				+ "." + PADL( ALLTRIM( lc_newtag), 3, "0")
			COPY FILE (lc_FileFrom) TO (lc_FileTo)
			ll_ok = .T.
		ENDIF

	ENDFOR

ENDIF
IF NOT ADIR( laFilesA, lc_APath) == 0
	FOR iv = 1 TO ALEN( laFilesA, 1)
		lc_FileFrom = F_PCXARCH + RIGHT( ALLTRIM(lc_Lrs), 1) + "\" + laFilesA[iv, 1]
		IF   (ALLTRIM(lc_Lrs) +  "G"   $lc_FileFrom  OR  ALLTRIM(lc_Lrs) + "R" $lc_FileFrom)  AND NOT pl_Reissue
			WAIT WINDOW "Do not copy a scanned signed subpoena file." NOWAIT
			ll_ok = .F.
		ELSE

			lc_FileTo = F_PCXARCH + RIGHT( ALLTRIM(lc_Lrs), 1) + "\" + ;
				LEFT( laFilesA[ iv,1], (LEN( laFilesA[iv, 1]) - 4)) + "." + ;
				PADL( ALLTRIM(  lc_newtag), 3, "0")
			COPY FILE (lc_FileFrom) TO (lc_FileTo)
			ll_ok = .T.
		ENDIF
	ENDFOR

ENDIF


	IF ll_ok
	&&12/4/15 -EF:  store "G"/"R" types to the scandoclog
	IF   (ALLTRIM(lc_Lrs) +  "G"   $lc_FileFrom  OR  ALLTRIM(lc_Lrs) + "R" $lc_FileFrom  ) 	 
		l_ok= InsertScn  (lc_Lrs,   lc_newtag,IIF( ALLTRIM(lc_Lrs) +  "G"   $lc_FileFrom ,'G','R'), lc_FileTo, lc_FileFrom)
	ENDIF	
	 
	&&08/15/2017 - added TX work(dwq from original to mirrored tag)
	IF (pl_txcourt AND ALLTRIM(lc_Lrs) +  "Q"   $lc_FileFrom )
		l_ok= InsertScn  (lc_Lrs,   lc_newtag,'Q', lc_FileTo, lc_FileFrom)
	ENDIF	
	
	gfmessage( "Scanned documents have been copied.")
	
	ENDIF
RETURN ll_ok
