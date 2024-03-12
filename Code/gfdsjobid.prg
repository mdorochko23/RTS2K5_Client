LOCAL n_Curarea, n_jobnum, c_Prefix, l_distid
n_Curarea = SELECT()

l_distid=.t.
IF NOT USED("distid")
	c_path=dbf_use('data','GLOBAL','rts.ini')
	USE (ADDBS(c_path)+'distid') IN 0
	l_distid=.f.
ENDIF

SELECT distid

GOTO TOP
DO WHILE NOT RLOCK()
ENDDO
DO WHILE flag
ENDDO
REPLACE flag WITH .T.
*-- Increment counter
n_jobnum = distid.jobid_no + 1
c_Prefix = distid.prefix
IF n_jobnum >=  99999999
   REPLACE distid.jobid_no WITH 1
	n_jobnum = 1
   IF RIGHT(c_Prefix,1) != "Z"
      *-- Increment prefix
      c_Prefix = CHR(ASC(c_Prefix) + 1)
      REPLACE distid.prefix WITH c_Prefix
   ELSE
      *-- Should never happen :-(
      DO WHILE .T.
         gfmessage("Seek MIS help! Please do not continue!!")
         gfmessage( "DS Job ID overflow !!")
      ENDDO
   ENDIF
ELSE
   REPLACE distid.jobid_no WITH n_jobnum
ENDIF

REPLACE distid.flag WITH .F.
UNLOCK

IF NOT l_distid=.t.
	USE IN distid
ENDIF	

SELECT (n_CurArea)

RETURN (c_Prefix + PADL(ALLTRIM(STR(n_jobnum)), 8, "0"))


FUNCTION DBF_USE
LPARAMETERS lcSection, lcVarable, lcINI

LOCAL lc_GlobalPath

DECLARE INTEGER GetPrivateProfileString IN Win32API AS GetPrivStr ;
                    String cSec, ;
                    String cKey, ;
                    String cDef, ;
                    String @cBuf, ;
                    Integer nBufSize, ;
                    String cINIFile

    lc_GlobalPath = SPACE(500)

    ln_len=GetPrivStr(lcSection,lcVarable,"\",@lc_GlobalPath,500,SYS(5)+CURDIR()+ALLTRIM(lcINI))

    lc_GlobalPath= LEFT(lc_GlobalPath,ln_Len)

RETURN lc_GlobalPath
