**PROCEDURE scanexe
*--04/02/2013 - extracted from subp_pa: calls either latest netscan or latest tiffauto.exe

LOCAL busenetversion AS Boolean, ocdcnt AS OBJECT, ll_confirm AS Boolean, c_sql AS STRING, nr AS Boolean
STORE .F. TO busenetversion , ll_confirm, nr
STORE "" TO c_sql

			ocdcnt=CREATEOBJECT('cntdataconn')
			c_sql = "select [dbo].[fn_getestuser]( '" + ALLTRIM(goapp.currentuser.orec.login) + "','NETSCAN')"
			nr=ocdcnt.sqlpassthrough(c_sql,'viewrss')
			IF nr= .T.
				busenetversion = NVL(viewrss.EXP,.f.)
				IF USED('viewrss')
					USE IN viewrss
				ENDIF
			ELSE
				busenetversion = .F.
			ENDIF





IF NOT busenetversion
	=lfuptif()
ELSE
	*-- replace by code in checkforinstalls.prg
	*=chkburnbase()

ENDIF



RELEASE ocdcnt

RETURN busenetversion


**************************************************************************************
* Abstract: Updates user's copy of tiffauto.exe, if necessary
**************************************************************************************
PROCEDURE lfuptif
PRIVATE n_txttiff, d_txttiff
LOCAL lcoffice
n_txttiff = ADIR(a_txttiff, "\\SANSTOR\IMAGE\TXTTIFF\TIFFAUTO.EXE")


IF pl_caver  &&pl_ofcOak
	IF n_txttiff > 0 AND FILE("c:\TIFFAUTO.EXE")
		d_txttiff = a_txttiff[1, 3]
		n_txttiff = ADIR(a_txttiff, "C:\TIFFAUTO.EXE")
		IF n_txttiff > 0
			IF d_txttiff > a_txttiff[1, 3]
				COPY FILE \\sanstor\IMAGE\txttiff\tiffauto.EXE TO c:\tiffauto.EXE
			ENDIF
		ENDIF
	ENDIF
ELSE
	IF n_txttiff > 0 AND FILE("c:\vfp\TIFFAUTO.EXE")
		d_txttiff = a_txttiff[1, 3]
		n_txttiff = ADIR(a_txttiff, "C:\VFP\TIFFAUTO.EXE")
		IF n_txttiff > 0
			IF d_txttiff > a_txttiff[1, 3]
				COPY FILE \\sanstor\IMAGE\txttiff\tiffauto.EXE TO c:\vfp\tiffauto.EXE
			ENDIF
		ENDIF
	ENDIF
ENDIF
*****************************************************************************
* installes new net based scan app
**************************************************************************************


PROCEDURE chkburnbase
LOCAL clocviewer,cnetviewer,d_txttiff,n_txttiff,t_txttiff,cstring,cfile
clocviewer=ALLTRIM(ADDBS(mlpripro("R", "RTS.INI", "Data","clocprint", "\"))) +"burn_baseimage.exe"
cnetviewer=ALLTRIM(ADDBS(mlpripro("R", "RTS.INI", "Data","cnetburnbase", "\"))) +"burn_baseimage.exe"

cfile = clocviewer

IF NOT DIRECTORY("c:\program files\rts")
	MD "c:\program files\rts"
ENDIF
n_txttiff = ADIR(a_txttiff,cnetviewer)
IF n_txttiff > 0 AND FILE(clocviewer)

	d_txttiff = a_txttiff[1, 3]
	t_txttiff = a_txttiff[1, 4]
	n_txttiff = ADIR(a_txttiff,clocviewer)
	IF n_txttiff > 0
		IF (d_txttiff > a_txttiff[1, 3]) OR (d_txttiff = a_txttiff[1, 3] AND t_txttiff > a_txttiff[1, 4])
			COPY FILE (cnetviewer) TO (clocviewer)
		ENDIF
	ENDIF

ELSE
	IF n_txttiff > 0
		cnetpath=ALLTRIM(ADDBS(mlpripro("R", "RTS.INI", "Data","cnetburnbase", "\")))
		cstring=ADDBS(cnetpath) + "setup.exe"
		IF FILE(cstring)
			gfmessage("One-time installation process for " + cstring + " required")
			RUN &cstring
		ELSE
			gfmessage("Installation program " + cstring	+ " not found. Please notify Helpdesk.")
		ENDIF
	ENDIF

ENDIF
