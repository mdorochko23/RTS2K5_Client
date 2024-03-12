PROCEDURE gfAddCom
** gfAddCom.prg - Adds a comment to Comment.dbf file
** DMA 01/20/05  Remove use of Worker field in Comment.dbf
** DMA 06/19/02  Replace mlogname with pc_UserID
** DMA 06/04/02  Fill in CreatedBy field
** HN  02/19/98
** Called from AddPhnTx, AddTxn14, Incoming, PhoneTxn, OrdCancl, MemoTxn,

**             MailIDFx
** Calls gfUse, gfUnUse, gfPush, gfPop

** DMA 01/20/05  Remove use of Worker field in Comment.dbf
lPARAMETERS ldTxnDate, lcDescript, lcClient, lnTxnCode, lnTag, lcMailid, ;
   lnCount, lmComm, lnTxnId
*   lcWorker, lnCount, lmComm, lnTxnId

local laEnv, lcCurArea, lnComUsed

DIMENSION laEnv[1,3]
= gfPush( @laEnv)

*!*	lnComUsed = gfuse( "Comment")

*SET CLASSLIB TO comment.vcx

o=create("medcomment")
o.getitem(.null.)

** MEI(PCL) 4/21/05: Legacy Code. No longer needed.
*!*	** DMA 01/20/05  Remove use of Worker field in Comment.dbf
*!*	INSERT INTO Comment ;
*!*	   (Txn_date, Descript, Cl_Code, Txn_code, Tag, ;
*!*	   Mailid_no, Txn_id, Count, Comment, CreatedBy, Txn_id) ;
*!*	   VALUES ;
*!*	   (ldTxnDate, lcDescript, lcClient, lnTxnCode, lnTag, ;
*!*	   lcMailid, lnTxnId, lnCount, lmComm, pc_UserID, lnTxnId)
*!*	*INSERT INTO Comment (Txn_date, ;
*!*	*   Descript, ;
*!*	*   Cl_Code,  ;
*!*	*   Txn_code, ;
*!*	*   Tag,      ;
*!*	*   Mailid_no,;
*!*	*   Worker,   ;
*!*	*   Txn_id,   ;
*!*	*   Count,    ;
*!*	*   Comment,  ;
*!*	*   CreatedBy, ;
*!*	*   Txn_id) VALUES ;
*!*	*   (ldTxnDate, ;
*!*	*   lcDescript,;
*!*	*   lcClient,  ;
*!*	*   lnTxnCode, ;
*!*	*   lnTag,     ;
*!*	*   lcMailid,  ;
*!*	*   lcWOrker,  ;
*!*	*   lnTxnId,   ;
*!*	*   lnCount,   ;
*!*	*   lmComm,    ;
*!*	*   pc_UserID,  ;
*!*	*   lnTxnId)

replace comment.Txn_date	WITH ldTxnDate
replace comment.Descript		WITH lcDescript
replace comment.Cl_Code		WITH lcClient
replace comment.Txn_code		WITH lnTxnCode
replace comment.Tag			WITH lnTag
replace comment.Mailid_no		WITH lcMailid
replace comment.Txn_id			WITH lnTxnId
replace comment.Count			WITH lnCount
replace comment.Comment		WITH lmComm
replace comment.CreatedBy		WITH goApp.CurrentUser.pc_UserID
replace comment.Txn_id			WITH lnTxnId

o.updatedata

*!*	= gfunuse( "Comment", lnComUsed)

= gfPop( @laEnv)

RETURN
