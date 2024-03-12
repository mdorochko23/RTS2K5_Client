
PARAMETERS n_id_tblw2header, c_Location,  c_blurb, c_Mailid, c_certype, c_add1, c_add2, c_city, c_st, c_zip, c_ph
**06/13/2016- store a phone# without an address #42761
**Adds F2 MANUAL TAGS TO THE QC SYSTEM and RTS
LOCAL lcrolotype AS STRING , omedf2 AS Object, l_ok2 AS Boolean
lcrolotype=""
omedf2=CREATEOBJECT("medgeneric")
l_ok2=.F.
STORE "" TO c_fax , c_phone , c_fax2 , c_temp , c_temp2 ,c_phone2 , lc_sql, c_SendTo, ;
		c_CopyTo, c_FromName,c_FromEmail, c_Subject, lc_sql
lc_loc =FIXQUOTE( LEFT(c_location,50))

IF EMPTY(ALLTRIM(c_certype))
c_certype =IIF(pc_offcode="C"	, "M","R")
ENDIF

lc_sql=""

IF EMPTY(ALLTRIM(c_add1)) AND EMPTY(ALLTRIM(c_add2)) AND EMPTY(ALLTRIM(c_city))
lc_sql =" exec [dbo].[StoreF2Locations] '" +STR(n_id_tblw2header) + "','"  + lc_loc  ;
	 +"','" + lcrolotype + "','"  + c_blurb + "','" + c_Mailid+ "','" + c_certype + "','" + ALLTRIM(c_ph) + "'"
ELSE
** 05/31/2013 added address as a separate data columns

lc_sql =" exec [dbo].[qc_AddMF2Locations] '" +STR(n_id_tblw2header) + "','"  + lc_loc  ;
	 +"','" + lcrolotype + "','"  + c_blurb + "','" + c_Mailid+ "','" + c_certype + "','"  ;
	 +FIXQUOTE( ALLTRIM(c_add1)) + "','" +FIXQUOTE( ALLTRIM(c_add2) )+ "','" + FIXQUOTE(ALLTRIM(c_city) )+ "','"  ;
	 + ALLTRIM(c_st) + "','" + ALLTRIM(c_zip) + "','" + ALLTRIM(c_ph) + "'"

ENDIF

omedf2.SQLEXECUTE( lc_sql,"LocRecord")

RELEASE omedf2

IF USED("LocRecord") AND NOT EOF()
 RETURN NVL(LocRecord.EXP,0)
ELSE

RETURN 0
ENDIF




