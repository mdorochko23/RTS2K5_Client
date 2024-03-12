**********************************************************************
* PROGRAM: GFDSBILL.PRG
* Date: 04/22/04
* Abstract: Billing queue table functions
* Called By: acmanord.prg, orders.prg
* Calls: gfuse.prg, gfunuse.prg
* Parameters:
* 		c_Action - Calling programs requested action
*		c_Jobtype - Disttodo.jobtype field falue "CD", "DS"
*		n_Tag     - tag number
*		lc_Atcode  - Attorney code
*		ln_Ordid   - order id number. 0 for regular orders, required
*		ld_OrderDt - order date, required for regular order actions
*		ln_Shnum   - Copies in the "shipment"
*		c_Field    - Table field to be used for requested action
*		v_Newvalue - Replacement value for c_field
* Modified:
* 10/05    KDL  Converted to use SQL Server tables
* 02/09/05 kdl  removed the data field name from the pull case
* 01/21/05 EF   Display DistBill.Date_ship for Orders on CDs
* 07/30/04 kdls Modified for multiple ship types
**********************************************************************
PARAMETER c_Action, c_JobType, ln_tag, lc_atcode, ln_OrderId, ;
   ld_OrderDt , ln_Shnum, c_Field, v_Newvalue

LOCAL c_sql
c_sql=''
IF PCOUNT() < 4
	RETURN
ENDIF
omed=createobject('medgeneric')

IF INLIST(TYPE("ld_Shipdt"), 'U', "L", "C")
	ld_Shipdt = {  /  /    }
ENDIF
IF INLIST(TYPE("ld_Billdt"), 'U', "L", "C")
	ld_Billdt = {  /  /    }
ENDIF
IF INLIST(TYPE("ln_OrderId"), 'U', "L", "C")
	ld_OrderId = 0
ENDIF
IF INLIST(TYPE("ld_OrderDt"), "U", "L", "C", "N")
	ld_OrderDt = {  /  /    }
ENDIF
IF INLIST(TYPE("ln_Shnum"), "U", "L", "C")
	ln_Shnum = 1
ENDIF
IF INLIST(TYPE("c_Field"), "U", "L")
	c_Field = ""
ENDIF

LOCAL n_CurArea, l_Usedist, v_Seekval, l_order, c_order, n_rec, c_sql, c_sqlds, c_where
n_CurArea = SELECT()
*--fill in empty order dates with current order table value

IF EMPTY(ld_OrderDt)
*!*		l_order = gfuse_ro("order")
*!*		c_order = ORDER("order")
*!*		*--9/29/04 kdl start: save record pointer location
*!*		SELECT order
*!*		DO CASE
*!*			CASE EOF()
*!*				GO BOTTOM
*!*			CASE BOF()
*!*				GO TOP
*!*		ENDCASE
*!*		n_rec = RECNO()
*!*		SET ORDER TO cltgat IN ORDER
	**10/01/18 SL #109598
	*c_sql="SELECT * FROM tblorder WITH (INDEX (ix_tblorder_1)) WHERE cl_code='&pc_clcode.' AND tag="+ 
	c_sql="SELECT * FROM tblorder WHERE cl_code='&pc_clcode.' AND tag="+ ;
		STR(ln_tag)+" AND at_code='&lc_atcode.' AND active=1 AND deleted IS null" 
	omed.sqlexecute(c_sql,'curorder')
	IF reccount('curorder')>0
*!*	IF SEEK( pc_clcode + STR(ln_tag) + lc_atcode, "order")
		ld_OrderDt = curorder.date_order
	ENDIF
*!*		SET ORDER TO (c_order) IN order
*!*			GO (n_rec)
*!*		= gfunuse("order", l_order)
ENDIF

*!*	l_Usedist = gfuse("Distbill")
*!*	SELECT distbill
*!*	c_Curord = ORDER()
IF ln_OrderId > 0
*!*	SET ORDER TO clidtype IN distbill
	v_Seekval = STR(ln_OrderId)
	c_where = "cl_code='&pc_clcode.' AND tag="+ ;
		STR(ln_tag)+" AND at_code='&lc_atcode.' AND active=1 AND deleted IS null AND ln_orderid=&v_Seekval. AND rectype='&c_JobType.'"
	c_sqlds="SELECT * FROM tbldisttodo WHERE " + c_where
ELSE
*!*		IF EMPTY(ld_OrderDt)
*!*			SET ORDER TO cltagattyp IN distbill
		v_Seekval = ""
		c_where = "cl_code='&pc_clcode.' AND tag="+ ;
			STR(ln_tag)+" AND at_code='&lc_atcode.' AND shiptype='&c_JobType.' AND active=1 AND deleted IS null"
*!*		ELSE
*!*	*!*		SET ORDER TO cldttype IN distbill
*!*			v_Seekval = DTOC(ld_OrderDt)
*!*			c_where = "cl_code='&pc_clcode.' AND tag="+ ;
*!*				STR(ln_tag)+" AND at_code='&lc_atcode.' AND date_order=CAST('&v_Seekval.' AS datetime) AND active=1 AND deleted IS null" + ;
*!*				" AND shiptype='&c_JobType.'"
*!*		ENDIF
	c_sqlds="SELECT * FROM tbldisttodo WHERE lrs_no="+IIF(TYPE('pn_lrsno')='N',STR(pn_lrsno),pn_lrsno)+" AND tag="+ ;
		STR(ln_tag)+" AND at_code='&lc_atcode.' AND rectype='&c_JobType.'"
ENDIF

DO CASE
	CASE c_Action = "ADD"
*!*		SET ORDER TO
		c_sql= "INSERT INTO tblDistbill ( " +;
		   "Cl_code,Tag,Date_order,Id,At_code," + ;
		   "Shiptype,Shipnum,created,createdby,active)" + ;
		   "VALUES (" + ;
		   "'&pc_Clcode.',"+STR(ln_tag)+",'"+DTOC(d_today)+"',"+STR(ln_OrderId)+",'&lc_atcode.'," + ;
		   "'&c_JobType.',"+STR(ln_Shnum)+",'"+DTOC(d_today)+"','&pc_userid.',1)"
		omed.sqlexecute(c_sql)
	CASE c_Action = "UPDATE"

		c_sql=''
***		omed.sqlexecute(c_sqlds,'curtemp')
****		IF RECCOUNT('curtemp')>0		
*!*			IF SEEK(pc_Clcode + STR(ln_tag) + lc_atcode + ;
*!*			      v_Seekval + c_Jobtype, "distbill")
*--			IF TYPE(c_Field) = TYPE("v_Newvalue")
			DO CASE
*				CASE AT('/',v_Newvalue) > 0
*					c_sql="UPDATE tbldistbill SET &c_Field.='&v_Newvalue.' WHERE &c_where."
				CASE TYPE("v_Newvalue")='C'
					v_Newvalue=IIF(v_Newvalue=="  /  /    ","null","'"+v_Newvalue+"'")
					c_sql="UPDATE tbldistbill SET &c_Field.=&v_Newvalue. WHERE &c_where."
				CASE TYPE("v_Newvalue")='N'
					c_sql="UPDATE tbldistbill SET &c_Field.="+STR(&v_Newvalue)+" WHERE &c_where."
				CASE TYPE("v_Newvalue")='L'
					c_sql="UPDATE tbldistbill SET &c_Field.="+IIF(v_Newvalue,"1","0")+" WHERE &c_where."
			ENDCASE
				omed.sqlexecute(c_sql)
*--			ENDIF
***		ENDIF
	CASE c_Action = "PULL"
***		omed.sqlexecute(c_sqlds,'curtemp')
***		IF RECCOUNT('curtemp')>0		
*!*			IF SEEK(pc_Clcode + STR(ln_tag) + lc_atcode + ;
*!*			      v_Seekval + c_Jobtype, "distbill")
			v_Data = &c_Field
			IF TYPE("v_Data") = "C"
				v_Data = ALLTRIM(v_Data)
			ENDIF
***		ENDIF
	CASE c_Action = "CLEAR"
***		omed.sqlexecute(c_sqlds,'curtemp')
***		IF RECCOUNT('curtemp')>0		
			c_sql= "DELETE FROM tbldistbill WHERE &c_where."
			omed.sqlexecute(c_sql)
*!*			IF SEEK(pc_Clcode + STR(ln_tag) + lc_atcode + ;
*!*			      v_Seekval + c_JobType, "distbill")
*!*			   DO WHILE NOT RLOCK()
*!*			   ENDDO
*!*				DELETE
*!*			   UNLOCK
***		ENDIF
ENDCASE
*!*	SET ORDER TO (c_Curord) IN distbill
*!*	= gfunuse("Distbill", l_Usedist)
IF USED('curorder')
	USE IN curorder
ENDIF
IF USED('curtemp')
	USE IN curtemp
ENDIF

SELECT (n_CurArea)

