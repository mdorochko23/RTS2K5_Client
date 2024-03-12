********************************************
*- Batesunlock.prg
*- "Un-lock" bates text files
********************************************
PARAMETERS cRT
IF PCOUNT()>1
	RETURN
ENDIF
LOCAL tcPath, lcCurDir, lnSubDirs, ix, lunlock, ogen

ogen=CREATEOBJECT("medgeneric")

lcSQLLine="select resetBates from tbluserctrl with (nolock) where Id_userctrl='"+;
	ALLTRIM(GOAPP.currentuser.orec.ID_USERCTRL)+"'"
ogen.sqlexecute(lcSQLLine,"viewUserCtrl")
SELECT viewUserCtrl
IF RECCOUNT()=0
	gfmessage("Can't access tblUserCtrl. Bates reset cancelled.")
	RETURN .F.
ENDIF
IF NVL(viewUserCtrl.resetBates,.F.)=.F.
	gfmessage("You are not allowed to use this option. Bates unlock cancelled.")
	RETURN .F.
ENDIF

IF USED('viewUserCtrl')
	USE IN viewUserCtrl
ENDIF

LOCAL ARRAY laDirs[1]
lunlock=.F.
cRt=ALLTRIM(cRT)

*--check for table driven bates
IF tbcheckdef()
	gfmessage("Table based Bates litigation. No case text file.")
	RETURN
ENDIF

tcPath= "\\datastor\volume1\bates"

CREATE CURSOR dirlist (dirname c(200))

lcCurDir = ADDBS(m.tcPath)
lnSubDirs=ADIR(laDirs,m.lcCurDir+"*.*","DHS")
FOR ix = 1 TO m.lnSubDirs
	IF laDirs[m.ix,1]#"." AND "D"$laDirs[m.ix,5]
		INSERT INTO dirlist VALUES (m.lcCurDir+laDirs[m.ix,1])
*        =getsubdirs(m.lcCurdir+laDirs[m.ix,1])
	ENDIF
ENDFOR

SELECT dirlist
SCAN
	IF FILE(ADDBS(ALLTRIM(dirlist.dirname))+cRt+".sav")
		ERASE ADDBS(ALLTRIM(dirlist.dirname))+cRt+".sav"
		lunlock=.T.
		EXIT
	ENDIF
ENDSCAN

IF USED("dirlist")
	USE IN dirlist
ENDIF

IF lunlock
	gfmessage("Bates text file unlocked for RT: " + cRt)
ELSE
	gfmessage("No lock found on Bates file for RT: " + cRt)
ENDIF


**************************************************************
FUNCTION tbcheckdef
LOCAL c_sql,nr,ncurarea,ogen,ldef
ncurarea=SELECT()
ogen=CREATEOBJECT("medgeneric")
ldef=.F.
**10/01/18 SL #109598
*c_sql="select * from tblbatesdef with (nolock, index (ix_tblbatesdef_1)) where slit='&pc_litcode.' "+
c_sql="select * from tblbatesdef with (nolock) where slit='&pc_litcode.' "+;
	"and ISNULL(sarea,'')='' and active=1"
nr=ogen.sqlexecute(c_sql,'batdef')

IF RECCOUNT('batdef')<1
	**10/01/18 SL #109598
	*c_sql="select * from tblbatesdef with (nolock, index (ix_tblbatesdef_1)) where slit='&pc_litcode.' "+
	c_sql="select * from tblbatesdef with (nolock) where slit='&pc_litcode.' "+;
		"and ISNULL(sarea,'')='&pc_area.' and active=1"
	nr= ogen.sqlexecute(c_sql,'batdef')
ENDIF

IF RECCOUNT('batdef')>0
	ldef=.T.
ENDIF

IF USED('batdef')
	USE IN batdef
ENDIF

SELECT (ncurarea)
RETURN (ldef)
