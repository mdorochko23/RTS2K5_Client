*** clean string for use in SQL statements
PARAMETERS c_string,l_addapostrophes
l_addapostrophes=IIF(PCOUNT()<2,.f.,l_addapostrophes)
LOCAL l_hascontainingapostr
l_hascontainingapostr=.f.
*--deal with apostrophes
c_string=ALLTRIM(c_string)

IF LEFT(c_string,1)="'" AND RIGHT(c_string,1)="'"
	l_hascontainingapostr=.T.
	c_string=RIGHT(c_string,LEN(c_string)-1)
	c_string=LEFT(c_string,LEN(c_string)-1)
ENDIF

c_string=STRTRAN(STRTRAN(c_string,"''","'"),"'","''")

IF (l_hascontainingapostr OR l_addapostrophes)
	c_string="'"+c_string+"'"
ENDIF

RETURN (c_string)