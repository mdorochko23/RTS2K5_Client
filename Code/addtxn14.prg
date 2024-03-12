PROCEDURE AddTxn14
*** Addtxn14.prg - Adds a 14 ("Expedited request") transaction
* 01/20/2005  DMA  Remove use of TAMaster.Worker field in Comment.dbf
*                  Remove code that became unused as of 2002 changes
* 06/19/2002  DMA  Replace mlogname with pc_UserID; remove ID from gfAddTxn call
* 06/14/2002  kdl  Fix missing value for exp
* 05/29/2002  DMA  Minor speed enhancements; improve locking

* Called by DepOpts
* Calls gfAddTxn, gfAddCom
* Assumes gfGetCas has been called, but not necessarily gfGetDep

PRIVATE lnTxnId

lnTxnId = 0

** Expedite request
** Assumes record.dbf is open and at correct position.

DO gfAddTxn WITH m.date, m.descript, getPub("pc_clcode"), 14, Record.Tag, ;
   Record.Mailid_no, 0, mCount, " ", lnTxnId, " "

* 01/20/2005 DMA Remove use of TAMaster.Worker field in Comment.dbf
DO gfAddCom WITH m.date, m.descript, getPub("pc_clcode"), 14, Record.Tag, ;
   Record.Mailid_no, mcount, m.comments, lnTxnId
*   record.mailid_no, tamaster.worker, mcount, m.comments, lnTxnId

* 05/29/02 DMA Inserted code from internal routine SetExp
*              here to speed up program
SELECT Record
DO WHILE NOT RLOCK()
ENDDO

*--6/14/02 kdl start: fix missing value for exp
REPLACE Record.Expedite WITH .T., ;
   Record.ExpDate WITH d_today
*--kdl out 6/14: REPLACE Record.Expedite WITH exp, ;
*--kdl out 6/14:    Record.ExpDate WITH d_today
*--6/14/02 kdl start:

UNLOCK
DO GlobUpd WITH "RECORD", RECNO()

SELECT F
SET ORDER TO cltag
RETURN
