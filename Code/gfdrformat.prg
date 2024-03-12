
****************************************************************
**08/05/11-added NYC
** Doctor name formating program
** Feed in the name field value retrieved from tbldeponent
******************************************************************
PARAMETERS c_string
IF pcount()<1
	RETURN ''
ENDIF
	
LOCAL n_len, lcDept
STORE 0 TO n_len
lcDept=""

 IF pl_NYCAsb or pl_NJAsb AND '[PTF]'$c_string
  c_string=ptftodesc(0,c_string)
 ENDIF
 

c_string=ALLTRIM(UPPER(c_string))
IF "(MED)"$ ALLTRIM(UPPER(c_string)) 
   lcDept=" (MED)"
   c_string=strtran(c_string,"(MED)","") 
ENDIF 
IF "(ECHO)"$ ALLTRIM(UPPER(c_string)) 
   lcDept=" (ECHO)"
   c_string=strtran(c_string,"(ECHO)","") 
ENDIF    
IF "(RAD)"$ ALLTRIM(UPPER(c_string)) 
   lcDept=" (RAD)"
   c_string=strtran(c_string,"(RAD)","") 
ENDIF    
IF "(PATH)"$ ALLTRIM(UPPER(c_string)) 
   lcDept=" (PATH)"
   c_string=strtran(c_string,"(PATH)","") 
ENDIF    
IF "(BILL)"$ ALLTRIM(UPPER(c_string)) 
   lcDept=" (BILL)"
   c_string=strtran(c_string,"(BILL)","") 
ENDIF   
c_string=STRTRAN(c_string,'DR.','')
c_string=STRTRAN(c_string,'DRS.','')
c_string=STRTRAN(c_string,', ',',_')
l_inclupdates="(UPDATES)"$c_string
IF l_inclupdates
	c_string=ALLTRIM(STRTRAN(c_string,"(UPDATES)",''))
ENDIF
n_len=LEN(c_string)
DIMENSION a_stuff[1,2]
a_stuff[1,1]=1
a_stuff[1,2]="X"
*--bulid array of spaces, '.'
n_cnt=1
FOR n_counter=n_len TO 1 STEP -1
	IF INLIST(SUBST(c_string,n_counter,1),' ')
		DIMENSION a_stuff[n_cnt,2]
		a_stuff[n_cnt,1]=n_counter
		a_stuff[n_cnt,2]=SUBST(c_string,n_counter,1)
		n_cnt=n_cnt+1
	ENDIF
ENDFOR
c_newstring=''
n_alen=ALEN(a_Stuff,1)
l_hasinitial=IIF(a_stuff[1,2]<>"X" AND RIGHT(c_string,1)='.',.T.,.F.)
n_lastpos=n_len
IF a_stuff[1,2]<>"X"
FOR n_cnt=n_alen TO 0 STEP -1
	IF NOT n_cnt=0
		c_newstring=ALLTRIM(c_newstring)+ " " +ALLTRIM(SUBST(c_string,a_Stuff[n_cnt,1],n_lastpos-a_Stuff[n_cnt,1]+1))
		n_lastpos=a_Stuff[n_cnt,1]
	ELSE
		c_newstring=ALLTRIM(ALLTRIM(c_newstring)+" " +ALLTRIM(" "+LEFT(c_string,a_Stuff[n_alen,1])))
	ENDIF
ENDFOR
ELSE
c_newstring=c_string
ENDIF
c_newstring=STRTRAN(c_newstring,',_',', ')+lcDept
c_newstring=c_newstring+IIF(l_inclupdates," (UPDATES)","")
IF pl_NYCAsb or pl_NJAsb 
  c_newstring=ptftodesc(1,c_newstring)
 ENDIF
 

RETURN c_newstring
