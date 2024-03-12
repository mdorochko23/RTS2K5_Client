
*--update or copy files in a target folder using files in a source folder
PARAMETERS lcfoldersource,lcfoldertarget, lcskeleton
LOCAL lncopycnt,ndlls
lncopycnt=0
ndlls=0
IF NOT DIRECTORY(lcfoldertarget)
	MD (lcfoldertarget)
ENDIF
*--SET STEP ON 
lcextension = ALLTRIM(lcskeleton)
ndlls=ADIR(a_dlls,ADDBS(lcfoldersource) + lcskeleton)
IF NVL(ndlls,0) > 0
	WAIT WINDOW "Copying/updating required startup file(s). Please wait..." NOWAIT NOCLEAR
	FOR ncnt=1 TO ALEN(a_dlls,1)
		IF NOT FILE(ADDBS(lcfoldertarget)+ALLTRIM(a_dlls[ncnt,1]))
			COPY FILE (ADDBS(lcfoldersource)+ALLTRIM(a_dlls[ncnt,1])) ;
				TO (ADDBS(lcfoldertarget)+ALLTRIM(a_dlls[ncnt,1]))
			lncopycnt =lncopycnt+1
		ELSE
	*// check date of local file
			n_Txtlocal = ADIR(a_local,ADDBS(lcfoldertarget)+ALLTRIM(a_dlls[ncnt,1]))
			
			*--7/22/20: check for a "later date" instead of "any date" difference. Needed when test versions are on user machines [181763]
			IF (n_Txtlocal > 0) AND (a_dlls[ncnt,3] > a_local[1, 3])
			*--IF (n_Txtlocal > 0) AND (a_dlls[ncnt,3] <> a_local[1, 3])

				COPY FILE (ADDBS(lcfoldersource)+ALLTRIM(a_dlls[ncnt,1])) ;
					TO (ADDBS(lcfoldertarget)+ALLTRIM(a_dlls[ncnt,1]))
						lncopycnt =lncopycnt+1
			ENDIF
		ENDIF
	NEXT
	WAIT CLEAR
ENDIF

RETURN (lncopycnt)
