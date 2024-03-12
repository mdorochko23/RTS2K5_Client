***********************************************************************
* PROGRAM: GFDSUPDT
* Date: 6/30/04
* ABSTRACT: Update disttodo jobs
* Called by: Orders.prg
* Calls: gfuse.prg, gfunuse.prg
***********************************************************************
PARAMETER c_list, ln_tag, lc_atcode, d_Date
PRIVATE n_CurArea, l_Usedist, n_alen, lc_atcode, l_Usebill
n_CurArea = SELECT()
*!*	l_Usebill = gfuse("distbill")
*!*	l_Usedist = gfuse("Disttodo")
*!*	lc_atcode = PADR(lc_atcode, 8)
*!*	SELECT disttodo
*!*	*--set order to lrst + tag + at_code + rectype
*!*	SET ORDER TO lrstagat IN disttodo
*!*	SET ORDER TO cldttype IN distbill
DIMENSION a_stypes[5, 3]
a_stypes[1, 1] = "W"
a_stypes[2, 1] = "D"
a_stypes[3, 1] = "V"
a_stypes[4, 1] = "C"
a_stypes[5, 1] = "F"

a_stypes[1, 2] = "DV"
a_stypes[2, 2] = "DS"
a_stypes[3, 2] = "VS"
a_stypes[4, 2] = "CD"
a_stypes[5, 2] = "FT"
n_Alen = ALEN(a_stypes, 1)

*--combine ship types "D" and "V" into the conbined "W" ship type
*--for the new shiplist
IF "D" $ c_list AND "V" $ c_list
	c_list = STRTRAN(c_list, "D", "W")
	c_list = STRTRAN(c_list, "V,", "")
	c_list = STRTRAN(c_list, ",V", "")
ENDIF

*--if the ship type is active (in the ship type string), then set column 3 to .T.
FOR n_cnt = 1 TO n_Alen
	a_stypes[n_cnt, 3] = ;
		IIF( a_stypes[n_cnt, 1] $ c_list, .T., .F.)
ENDFOR

*--there is only one DS/VS/DV shiptype job record and one separate CD and
*-- and one separate FTP job type record , so any jobtype records for ship types
*-- not found, or duplicates need to be removed.
*--SELECT disttodo

*--update the rectype for the DS job record (combined record for 1st 3 job types),
*-- or delete it if there is no longer any DS job type
DO CASE
	CASE a_stypes[1, 3]
		DO lfDsupdt WITH "DV", lc_atcode, ln_tag, d_date
	CASE a_stypes[2, 3]
		DO lfDsupdt WITH "DS", lc_atcode, ln_tag, d_date
	CASE a_stypes[3, 3]
		DO lfDsupdt WITH "VS", lc_atcode, ln_tag, d_date
	OTHERWISE
		FOR n_cnt = 1 TO 3
			DO lfDsclr WITH a_stypes[n_cnt , 2], lc_atcode, ln_tag, d_date
		ENDFOR
ENDCASE


*--remaining ship types are individual records in disttodo table
FOR n_cnt = 4 TO n_Alen
	IF a_stypes[ n_cnt, 3]
		DO lfDsupdt WITH a_stypes[n_cnt , 2], lc_atcode, ln_tag, d_date
	ELSE
		DO lfDsclr WITH a_stypes[n_cnt , 2], lc_atcode, ln_tag, d_date
	ENDIF
ENDFOR

*--= gfunuse("Disttodo", l_Usedist)
SELECT (n_CurArea)

***********************************************************************************
* PROCEDURE: lfDsupdt
* ABSTRACT: Update existing (or post new) DS records
***********************************************************************
PROCEDURE lfDsupdt
PARAMETER c_type, c_atcode, n_tag, d_ordate, c_rectype, c_oldtype
LOCAL n_Curarea, l_updated,c_sql
n_Curarea = SELECT()
c_oldtype = ""
*l_updated = .F.
*--there will be only active record in the disttodo table, so get pointer to the
*--ist record for the lrs, tag, attorney, shipment type and then scan till
*--the active record is found
omed=CREATEOBJECT('medgeneric')
c_sql="SELECT * FROM tbldisttodo WITH (nolock) WHERE lrs_no="+IIF(TYPE('pn_lrsno')='N', STR(pn_lrsno),pn_lrsno)+" AND tag="+STR(n_tag)+ ;
	" AND at_code='&c_atcode.' AND rectype IN ('DS','DV','VS','&c_type.') AND active=1 AND deleted IS null"
omed.sqlexecute(c_sql,'disttodo')

IF RECCOUNT('disttodo')>0
*!*	IF ( ;
*!*		( INLIST(c_type, "DS", "VS", "DV") AND ;
*!*		( SEEK(STR(pn_lrsno) + STR(n_tag) + c_atcode + "DS", "disttodo") OR ;
*!*		  SEEK(STR(pn_lrsno) + STR(n_tag) + c_atcode + "DV", "disttodo") OR ;
*!*		  SEEK(STR(pn_lrsno) + STR(n_tag) + c_atcode + "VS", "disttodo")) ) ;
*!*		OR ;
*!*		  SEEK(STR(pn_lrsno) + STR(n_tag) + c_atcode + c_type, "disttodo") ;
*!*		)

	c_Rectype = IIF( INLIST(c_type, "DS", "VS", "DV"),;
		"DS,VS,DV", c_type)
	SELECT disttodo
	SCAN WHILE disttodo.lrs_no = IIF(TYPE('pn_lrsno')='N',pn_lrsno,VAL(pn_lrsno)) AND ;
		disttodo.tag = n_tag AND ;
		disttodo.at_code = c_atcode AND ;
		disttodo.rectype $ c_rectype

		IF EMPTY(disttodo.rem_date)
		*--update the rectype value
			IF disttodo.rectype <> c_type
*!*					SELECT disttodo
*!*					c_oldtype = disttodo.rectype
*!*					DO WHILE NOT RLOCK()
*!*					ENDDO
				c_sql="UPDATE tbldisttodo SET rectype=c_type WHERE id_tbldisttodo='"+disttodo.id_tbldistodo+"'"
				omed.sqlexecute(c_sql)
*--				REPLACE disttodo.rectype WITH c_type
*!*					UNLOCK
			ENDIF
			EXIT
		ENDIF
		*--now update the shipype in distbill (always do this since the job can be removed by
		*-- other processes)
		IF disttodo.rectype <> c_type
			DO CASE
				CASE c_oldtype = "DV"
					*--for DV type, update shiptype for one of the 2 associated records
					*--and delete the second record
					DO gfDsbill WITH "CLEAR", "VS", n_tag, c_atcode, 0, d_ordate
					DO gfdsbill WITH "UPDATE", "DS", n_Tag, c_atcode, 0, ;
						d_Ordate, 1, "shiptype", c_type
				OTHERWISE
					IF NOT c_type = "DV"
						*--other ship types, if not now DV update the current record
						c_sql="SELECT * FROM tbldistbill WITH (nolock) " +;
							"WHERE cl_code='&pc_Clcode.' AND tag="+STR(n_Tag)+" AND at_code='&c_atcode.' AND " +;
							"shiptype='&c_oldtype.' AND [Id]=0 AND active=1 AND deleted IS null"
						omed.sqlexecute(c_sql,'distbill')
						IF RECCOUNT('distbill')>0
*--						IF SEEK(pc_Clcode + STR(n_tag) + c_atcode + ;
*--		      			 DTOC(d_Ordate)+ c_oldtype, "distbill")
							DO gfdsbill WITH "UPDATE", c_oldtype, n_Tag, c_atcode, 0, ;
								d_Ordate, 1, "shiptype", c_type
						ELSE
							DO gfdsbill WITH "ADD", c_type, n_Tag, c_atcode, 0, ;
								d_Ordate, 1
						ENDIF
					ELSE
						c_sql="SELECT * FROM tbldistbill WITH (nolock) " +;
							"WHERE cl_code='&pc_Clcode.' AND tag="+STR(n_Tag)+" AND at_code='&c_atcode.' AND " +;
							"shiptype='&c_oldtype.' AND [Id]=0 AND active=1 AND deleted IS null"
						omed.sqlexecute(c_sql,'distbill')
						IF RECCOUNT('distbill')>0
*!*							IF SEEK(pc_Clcode + STR(n_tag) + c_atcode + ;
*!*			      			 DTOC(d_Ordate) + c_oldtype, "distbill")
						*--IF now DV, update current record and add the second record
							DO gfdsbill WITH "UPDATE", c_oldtype, n_Tag, c_atcode, 0, ;
								d_Ordate, 1, "shiptype", "DS"
						ELSE
							DO gfdsbill WITH "ADD", "DS", n_Tag, c_atcode, 0, ;
							d_Ordate, 1
						ENDIF

						DO gfdsbill WITH "ADD", "VS", n_Tag, c_atcode, 0, ;
						d_Ordate, 1
						IF USED('distbill')
							USE IN distbill
						ENDIF	
					ENDIF
			ENDCASE
		ENDIF
	ENDSCAN
ENDIF
*--decided to not post new jobs at this point, they should only come from
*--the new orders, log in and cover letter printing process processes
*IF NOT l_updated
	*--post a new job
*	DO gfdspost WITH pc_clcode, n_tag, c_atcode, ;
*		IIF( c_type = "DV", "W", c_type), "", .F., d_ordate
*ENDIF
SELECT (n_curarea)

************************************************************************************
* PROCEDURE: lfDsclr
* ABSTRACT: Mark existing DS jobs as removed (clear them)
***********************************************************************
PROCEDURE lfDsclr
PARAMETER c_type, c_atcode, n_tag, d_ordate
LOCAL n_Curarea
n_CurArea = SELECT()
omed=CREATEOBJECT('medgeneric')
c_sql="SELECT * FROM tbldisttodo WITH (nolock) WHERE lrs_no="+IIF(TYPE('pn_lrsno')='N', STR(pn_lrsno),pn_lrsno)+" AND tag="+STR(n_tag)+ ;
	" AND at_code='&c_atcode.' AND rectype IN ('DS','DV','VS','&c_type.') AND active=1 AND deleted IS null"
omed.sqlexecute(c_sql,'disttodo')

IF RECCOUNT('disttodo')>0
*--IF SEEK(STR(pn_lrsno) + STR(n_tag) + c_atcode + c_type, "disttodo")
	SELECT disttodo
	SCAN WHILE disttodo.lrs_no = pn_lrsno AND ;
		disttodo.tag = n_tag AND ;
		disttodo.at_code = c_atcode AND ;
		disttodo.rectype = convertField(NVL(c_type,""),"")

		IF EMPTY(disttodo.rem_date)
			*--remove the job
			c_sql="UPDATE tbldisttodo SET rem_by='&pc_UserId.'," +;
				"rem_date='"DTOC(d_today)+"',"+ ;
				"rem_time='"+TIME()+"'"+ ;
				" WHERE id_tbldisttodo='"+disttodo.id_tbldistodo+"'"
			omed.sqlexecute(c_sql)
*!*				SELECT disttodo
*!*				DO WHILE NOT RLOCK()
*!*				ENDDO
*!*				REPLACE disttodo.rem_by WITH pc_UserId, ;
*!*				   disttodo.rem_date WITH d_today, ;
*!*				   disttodo.rem_time WITH TIME()
*!*				UNLOCK
			ENDIF

		*--clear the distbill record (always do this since the job can be removed by
		*-- other processes)
		IF disttodo.rectype = "DV"
			DO gfDsbill WITH "CLEAR", "DS", n_tag, c_atcode, 0, d_orDate
			DO gfDsbill WITH "CLEAR", "DV", n_tag, c_atcode, 0, d_orDate
		ELSE
			DO gfDsbill WITH "CLEAR", (disttodo.rectype), n_tag, c_atcode, 0, d_orDate
		ENDIF

	ENDSCAN
ENDIF
SELECT (n_CurArea)






