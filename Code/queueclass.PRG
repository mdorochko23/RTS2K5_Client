*FUNCTION GetRpsQueueClass

PARAMETERS lFax2Req ,lPrt2Req , cuserdepar, d_txn11

PRIVATE c_class
c_class=""
PC_BATCHRQ=""
pl_SpecRpsSrv=.f.


DO CASE
CASE lFax2Req                   && Fax a 2nd Request
	c_class = IIF (pl_CAVer, "CAFax2Rq", "2ReqFax") &&--EF end
	**06/20/2011: additional class so we can stop storing 2nd request from pdf as another pdf
	&&2/5/15 : stop using  followup with pdfs
*!*		c_class= IIF(pl_PdfReprint and NOT pl_EditReq,c_class + 'fromPdf',c_class)


CASE lPrt2Req                   && Print a 2nd Request
	c_class = "Second"
	IF INLIST( ALLT(UPPER(cuserdepar )), "RTU", "ICU", "ASU", "SRU", "AM")	
		c_class =  IIF( ALLTRIM(cuserdepar ) = "RTURUSH", ;
			"SecRTURUSH", c_class + ALLT(UPPER(cuserdepar )))
	ENDIF
*!*		IF PL_KOPVER  AND (PC_ISSTYPE=="S")  AND PL_OFCMD
*!*					MCLASS ='MDSubReq2'
*!*		ENDIF
*!*		
	
	
ENDCASE





IF  ALLT(UPPER(cuserdepar))= "SRU" AND pl_RushCas
	c_class = ALLT(UPPER(goApp.userdepartment))+"RUSH"
ENDIF

IF pl_UpdHoldReqst 
	mclass="HoldFollUp2"
ELSE
	mclass=c_class
ENDIF

RETURN
