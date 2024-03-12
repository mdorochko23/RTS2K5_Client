*** LocSumm.prg - Location Summary
**  Produces a list of all records in a case (received and otherwise).
**  Called by PrintCov
**  Uses LocSumm.FRX Report Definition
************************************************************************
parameters lnLRS

if empty(lnLRS) OR ISNULL(lnLRS)
   return
endif

LOCAL llRecord, lcHeader, lcFooter, lnRecv, lnTotal, lnHold, ;
   lnCan, lnWait, lnLook, lcFooter2
LOCAL lnNRS, lloGen, lcSQLLine, lnCurArea
STORE 0 TO holddays, gnFRDays, gnIssDays 
lnCurArea=SELECT()

IF TYPE("oGen")!="O"
   oGen=CREATEOBJECT("medrequest")
   lloGen=.T.
ENDIF

lcSQLLine="exec dbo.getHolDays '"+ALLTRIM(pc_clcode)+"', '"+ALLTRIM(fixquote(pc_Court1))+"' "
oGen.sqlexecute(lcSQLLine,"viewHoldDays")
SELECT viewHoldDays
IF RECCOUNT()>0
   holddays = viewHoldDays.exp
ENDIF  
USE   

&& From-Review Days in Lit
lcSQLLine="select dbo.gfFRDays('"+ALLTRIM(fixquote(pc_litcode))+"')"	
oGen.sqlexecute(lcSQLLine,"viewFRDays")
SELECT viewFRDays
IF RECCOUNT()>0
   gnFRDays = viewFRDays.exp
ENDIF  
USE   

&& Issue Days in Lit
lcSQLLine="select dbo.gfIssDay('"+ALLTRIM(fixquote(pc_litcode))+"')"	
oGen.sqlexecute(lcSQLLine,"viewIssDay")
SELECT viewIssDay
IF RECCOUNT()>0
   gnIssDays = viewIssDay.exp
ENDIF  
USE     
       
SELECT 0
create cursor locSumm (Tag N(3), descript C(50), status C(1), Req_date D, ;
   fin_date D, Holdc C(1), StatDesc C(4) )

STORE 0 TO lnRecv, lnTotal, lnHold, lnCan, lnWait, lnLook, lnNRS

lcSQLLine="select * from tblRequest where cl_code='"+ALLTRIM(pc_clcode)+"' and active=1"
oGen.sqlexecute(lcSQLLine, "viewRequest")
*
*  Pass 1 -- Go through the Record File and process received records.
*            Also, accumulate counts on record categories.
*
SELECT viewRequest
scan 
   lnTotal = lnTotal + 1

   do case
      CASE status = "W"
         IF hold
            lnHold = lnHold + 1
         ELSE
            lnWait = lnWait + 1
         ENDIF
      case status = "R"
         lnRecv = lnRecv + 1
      case status = "N"
         lnNRS = lnNRS + 1
      case status = "F"
         lnLook = lnLook + 1
      case status = "C"
         lnCan = lnCan + 1
   endcase

   if status = "R"
      scatter memvar
      m.holdc = IIF( m.hold, "Y", " ")
      m.statdesc = "RECV"      
      
      if NOT empty(oGen.checkDate(m.req_date))
         if m.type <> "A"
            if holddays > 0
               m.req_date = m.req_date + holddays
            endif
         else
            m.req_date = m.req_date + ;
               IIF(viewRequest.FromRev, gnFRDays, gnIssDays)
         endif
      endif
      DO nvlfields  
      insert into locSumm from memvar
   endif
endscan

*
*  Pass 2 -- Go through the record file for unreceived records
*            and generate report lines.
*
select viewRequest
scan 
   if status <> "R"
      scatter memvar
      m.holdc = IIF( m.hold, "Y", " ")      
      do case
         case status = "A"
            m.statdesc = "COUN"
         case status = "C"
            m.statdesc = "CAN"
         case status = "F"
            m.statdesc = "LOOK"
         case status = "I"
            m.statdesc = "INC"
         case status = "N"
            m.statdesc = "NRS"
         case status = "Q"
            m.statdesc = "RSCH"
         case status = "T"
            m.statdesc = "NOTI"
         case status = "W"
            m.statdesc = "WAIT"
      endcase

      if NOT INLIST( status, "T", "Q")
         if !empty(oGen.checkDate(m.req_date))
            if m.type <> "A"
               if holddays > 0
                  m.req_date = m.req_date + holddays
               endif
            else
               m.req_date = m.req_date + ;
                  IIF( viewRequest.FromRev, gnFRDays, gnIssDays)
            endif
         endif
      else
         m.req_date = {  /  /    }
      endif
      DO nvlfields
      insert into locSumm from memvar
   endif
endscan
SELECT viewRequest
USE 


SELECT locSumm
if RECCOUNT() > 0   
   lcHeader = "Location Summary (" + ALLT( pc_plnam) + ;
      ", RT #: " + pc_lrsno + ")"

   lcFooter = "Locations: " + alltrim(str(lnTotal)) + "   Received: " + ;
      alltrim(str(lnRecv)) + "   Waiting: " + alltrim(str(lnwait)) + ;
      "   Cancelled: " + alltrim(str(lnCan)) + ;
      "   NRS: " + alltrim(str(lnNRS))
   lcFooter2 = "          " + ;
      "   On Hold: " + alltrim(str(lnHold)) + ;
      "   First Look: " + allt(str(lnLook))
    SELECT locSumm        	
 	IF NVL(pl_Softimg,.F.) 	   
 	   _ASCIIROWS=58
   	   REPORT FORM LocSummS TO FILE (pc_softdir + "5_locsum.txt") ASCII		   	   
	ELSE
		REPORT FORM LocSumm TO  PRINTER NOCONSOLE 
	ENDIF   
ELSE 
   gfmessage(  "No deponents have been entered for this case")
ENDIF 



if used("locSumm")
   select locsumm
   use
ENDIF
IF lloGen=.T.
   RELEASE oGen
ENDIF 
SELECT (lnCurArea)   
RETURN
********************************************************************************
PROCEDURE nvlfields
LOCAL lnCurArea, lnfld
lnCurArea=SELECT()
SELECT locsumm
FOR lnfld=1 TO AFIELDS(laflds)
    lcChkField="m."+ALLTRIM(laflds[lnFld,1])
    DO CASE 
       CASE ALLTRIM(laflds[lnFld,2])="N"
            &lcChkField=NVL(&lcChkField,0)
       CASE ALLTRIM(laflds[lnFld,2])="C"
            &lcChkField=NVL(&lcChkField,"")  
       CASE ALLTRIM(laflds[lnFld,2])="D"
            &lcChkField=NVL(&lcChkField,{})        
   ENDCASE 
NEXT 
SELECT (lnCurArea)   
RETURN
*******************************************************************************
