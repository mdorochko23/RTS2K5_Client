PROCEDURE Code30B
*** Code30B.prg - Allow user selection of Code 30 blurb.
* EF 09/21/2005 - Switched to SQL
*********************************************************************************************
* Called by Add30Txn.spr
* 05/05/03 DMA Add handling for Echocardiogram department in hospitals
*              Add new document type for HIPAA-compliant authorizations
* 05/01/02 HN  Initial Programming
*              Parameters:
*                          lcClCode   Client code of current case
*                          lnTag      Tag of current deponent
*                          lcC30Type  S = Subpoena
*                                     O = Other
*                                     A = Standard Authorization
*                                     H = HIPAA-compliant authorization
*********************************************************************************************
parameters lcClCode, lnTag
set memowidth to 70

PRIVATE n_which30, llRecord, lnCurRec, lcCurTag, lcMid, lcMail, llMail

LOCAL l_mail as Boolean, l_SpInst as Boolean
PUBLIC ARRAY Code30Arr[1,3]
lcReturn = space(500)
STORE .t. to l_mail, l_SpInst 
** Get deponent Information from Record and Rolodex files.
lcMid = ""
SELECT Request
store "" to Depline1, Depline2,Depline3, Depline4
lcMid = Request.Mailid_no
DepLine1 = alltrim(Request.Descript)  

if !empty(lcMid)
  * lcMail = gfMailn(lcMid)
  * llMail = gfUse(lcMail)
  c_str="select * from tblDeponent where mailid_no ='" + lcMid + "'"
  l_mail=Thisform.mediator.sqlexecute(c_str, "Mail")
  
   IF l_mail
   
      DepLine2 = alltrim(mail.add1)
      if !empty(mail.add2)
         DepLine2 = depline2 + ", " + alltrim(mail.add2)
      endif
      DepLine3 = alltrim(mail.city) + ", " + alltrim(mail.state) + " " + alltrim(mail.zip)
      if left(lcMid,1) <> "H"
         if "ATTN:"$upper(mail.attn)
            DepLine4 = alltrim(mail.attn)
         else
            DepLine4 = "ATTN: " + alltrim(mail.attn)
         endif
      ELSE
      
         *llSpec_ins = gfuse("spec_ins")
         *set order to cltag
         c_str="select * from tblSpec_inst where cl_code ='" + lcClCode + "' and tag ='" + STR(lnTag) + "'"
  		l_SpInst=Thisform.mediator.sqlexecute(c_str, "Spec_ins")
         if l_SpInst
            do case
               case spec_ins.dept = "M"
                  DepLine4 = mail.Mr
               case spec_ins.dept = "P"
                  DepLine4 = mail.Path
               case spec_ins.dept = "B"
                  DepLine4 = mail.Billing
               case spec_ins.dept = "R"
                  DepLine4 = mail.Rad
                  * 05/05/03 DMA Add echocardiogram department option
               case spec_ins.dept = "E"
                  DepLine4 = mail.Echo
            ENDCASE
          ELSE
          =MESSAGEBOX("Cannot get Special Instruction File",64, "Blurbs Selection")
          DepLine4=""
         endif
         if !empty(depline4)
            if !"ATTN:"$upper(depline4)
               depline4 = "ATTN: " + alltrim(depline4)
            endif
         endif
			SELECT spec_ins
			use
         *=gfUnuse("Spec_ins",llSpec_ins)
      ENDIF
    ELSE
     =MESSAGEBOX("Cannot get MailRolodex File",64, "Blurbs Selection")
     return
   ENDIF
   SELECT mail
   use
   *=gfUnuse(lcMail,llMail)
endif

**
n_which30 = 1
Code30desc = ""

DO code30b.spr

release code30Arr

RETURN lcReturn

**********************************************
procedure got30

private lcType,lcMType

if code30arr[n_which30, 3] <> 0
   select code30b
   goto code30arr[n_which30, 3]
   lcType = ""
   lcMType = ""
   if !empty(type1)
      lcType = getType("Select Insert (TYPE)", Type1,Type2,Type3,"", "", "")
   endif

   if !empty(mType1)
      lcmType = getType("Select Insert (MTYPE)",mType1,mType2,mType3,mType4,mType5,"")
   endif

   do case
      case upper(alltrim(lcType)) == "IRS"
         lcType = "INTERNAL REVENUE SERVICE"
      case upper(alltrim(lcType)) == "SSA"
         lcType  = "SOCIAL SECURITY ADMINISTRATION"
      case upper(alltrim(lcType)) == "EMP"
         lcType  = "EMPLOYMENT"
      case upper(alltrim(lcType)) == "W/C"
         lcType  = "WORKERS COMPENSATION"
      case "AUTHO"$upper(lcType)
         lcType = strtran(lcType,"AUTHO","AUTHORIZATION")
   endcase

   do case
      case upper(alltrim(lcMType)) == "IRS"
         lcMType = "INTERNAL REVENUE SERVICE"
      case upper(alltrim(lcMType)) == "SSA"
         lcMType  = "SOCIAL SECURITY ADMINISTRATION"
      case upper(alltrim(lcMType)) == "EMP"
         lcMType  = "EMPLOYMENT"
      case upper(alltrim(lcMType)) == "W/C"
         lcMType  = "WORKERS COMPENSATION"
      case "AUTHO"$upper(lcMType)
         lcMType = strtran(lcMType,"AUTHO","AUTHORIZATION")
   endcase

   lcReturn = code30arr[n_which30,2]
   if !empty(lcType)
      lcReturn = strtran(lcReturn,"(TYPE)",alltrim(lcType))
   endif

   if !empty(lcMType)
      lcReturn = strtran(lcReturn,"(MTYPE)",alltrim(lcMType))
   endif
else
   lcReturn = ""
endif
RETURN

**********************************************
procedure makepop

private lcStr

code30arr = ""
nCnt = 0
nbar = 0
arRec = 0
select Code30b
scan
   nBar = nBar + 1
   nCnt = nCnt + 1
   DIMENSION code30arr[nCnt, 3]
   code30arr[nCnt, 1] = heading
   lcStr = strtran(code30b.desc,"(DEPLINE1)",depline1)
   lcStr = strtran(lcStr,"(DEPLINE2)",depline2)
   lcStr = strtran(lcStr,"(DEPLINE3)",depline3)
   lcStr = strtran(lcStr,"(DEPLINE4)",depline4)

   code30arr[nCnt, 2] = lcStr
   code30arr[nCnt, 3] = recno()
endscan

RETURN

***************************************************
procedure when30

if code30arr[n_which30, 3] <> 0
   Code30desc = code30arr[n_which30,2]
   show gets
endif

RETURN

*********************************************************
Function getType
parameters lcHdng, lcT1, lcT2, lcT3, lcT4, lcT5, lcT6

private lcReturn

DEFINE POPUP TypePop FROM 5,15 TO 10,45 ;
   TITLE lcHdng FOOTER " Press <Esc> to cancel "
nbar = 0
if !empty(lcT1)
   nbar = nbar + 1
   DEFINE BAR nbar OF TypePop PROMPT "\<"+lcT1
endif

if !empty(lcT2)
   nbar = nbar + 1
   DEFINE BAR nbar OF TypePop PROMPT "\<"+lcT2
endif

if !empty(lcT3)
   nbar = nbar + 1
   DEFINE BAR nbar OF TypePop PROMPT "\<"+lcT3
endif

if !empty(lcT4)
   nbar = nbar + 1
   DEFINE BAR nbar OF TypePop PROMPT "\<"+lcT4
endif

if !empty(lcT5)
   nbar = nbar + 1
   DEFINE BAR nbar OF TypePop PROMPT "\<"+lcT5
endif

if !empty(lcT6)
   nbar = nbar + 1
   DEFINE BAR nbar OF TypePop PROMPT "\<"+lcT6
endif

nbar = nbar + 1
DEFINE BAR nbar OF TypePop PROMPT "\<"+"OTHER"

ON SELECTION POPUP TypePop DEACTIVATE POPUP TypePop
SIZE POPUP TypePop TO CNTBAR("TypePop"),30

ACTIVATE POPUP TypePop
DO CASE
   CASE BAR() = 1
      lcReturn = lcT1
   CASE BAR() = 2
      lcReturn = lcT2
   CASE BAR() = 3
      lcReturn = lcT3
   CASE BAR() = 4
      lcReturn = lcT4
   CASE BAR() = 5
      lcReturn = lcT5
   CASE BAR() = 6
      lcReturn = lcT6
   OTHERWISE
      lcReturn = ""
ENDCASE

DEACTIVATE POPUP TypePop
RELEASE POPUP TypePop

return lcReturn
