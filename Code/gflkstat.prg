**************************************************
* PRG: gfLkstat
* Date: 7/01/03
* Programmer: kdl
*
* Abstract: Return the current tag's 1st look status
* 1st look level: 0 = no 1st look, 1 = wait, 2=pre-review,
* 3=review, 4=post review (redacted/received),
* 5=released for distribution, 6=order fullfillment
* Modifications:
* 01/10/06 kdl SQL conversion
* 12/05/03 kdl Drop check for order fulfillment to speed up process
*
****************************************************
PARAMETER c_Type, l_FrstLook, c_Status, n_Tag

PRIVATE n_Level
n_level = 0                                     && 1st look status level
*--n_Curarea = SELECT()
IF c_Type = "LEVEL"
   IF l_FrstLook
      DO CASE
         CASE c_Status = "W"
            n_Level = 1
         CASE c_Status = "F"
            *--check for an '88' transaction
*!*	            SELECT ( pc_Entryn)
*!*	            c_Order = ORDER()
*!*	            SET ORDER TO Cl_Txn
			omed=CREATEOBJECT('medgeneric')
			**10/01/18 SL #109598
			*c_sql="SELECT * FROM tbltimesheet WITH (INDEX (ix_tbltimesheet)) WHERE cl_code='&pc_clcode.' AND tag="+STR(n_Tag)+
			c_sql="SELECT * FROM tbltimesheet WHERE cl_code='&pc_clcode.' AND tag="+STR(n_Tag)+;
				" AND txn_code=88 AND active=1 and deleted IS null"
			omed.sqlexecute(c_sql,'entry')
			IF RECCOUNT('entry')>0
*--            IF SEEK( pc_clcode + "*" + STR(88) + "*" + STR(n_tag), pc_Entryn)
               n_Level = 3
            ELSE
               n_Level = 2
            ENDIF
*--            SET ORDER TO (c_Order) IN (pc_Entryn)
         	IF USED('entry')
         		USE IN entry
         	ENDIF
         CASE c_Status = "R"
				n_Level = IIF( Record.Distribute, 5, 4)
      ENDCASE
   ELSE
      n_Level = 0
   ENDIF
*--   SELECT ( n_Curarea)
RETURN n_Level
ELSE
   *--add code for record status comp here
ENDIF


