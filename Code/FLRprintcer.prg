PROCEDURE FLRPrintCer
**05/07/10 - add "D" for CAD lit
**04/30/10 - add Pathology for CAD lit 
**03/31/09 - copy of the main one -used for FLR batch printing
*--------------------------------------------------------------------------


PARAMETERS ntag, bReq, ntxn_id,l_flrbatch
PRIVATE dbInit, dbSpec_Ins, l_cCertType, nrec, l_nCnt, l_cCert, ncnt, l_cCert2, ;
   l_cType, ntxn_id, l_cDblLtr, l_cDblLtr2, c_cltag, l_cert, c_Specmark, mv_c
dbInit = SELECT()
mv_c=""
WAIT WINDOW "Printing certification page(s)." NOWAIT NOCLEAR 


STORE "" TO l_cType, l_cCert, l_cCert2, l_cCertType, c_Specmark
STORE 0 TO nrec, ncnt
SELECT 0

SELECT Spec_ins
l_cType = ALLTRIM( Spec_Ins.cert_type)
l_cCertType = l_cType
szEdtReq = gfAddCR( szrequest)

      

*--7/09/04 kdl start: moved procedure setting save out of "if" condition

ncnt = RAT( "L", pc_CertTyp)
IF ncnt <> 0
   l_cCert = STRTRAN( pc_CertTyp, "L", "", 1, 2)
   SET PROCEDURE TO Global additive
   l_cCert2 = getCertif()
   IF EMPTY( l_cCert2)
      gfmessage(" You must pick a certification type.")

      DO WHILE EMPTY( l_cCert2)
         l_cCert2 = getCertif()
         LOOP
      ENDDO
   ENDIF
   l_cCertType = ALLTRIM( l_cCert2) + ALLTRIM( l_cCert)
   SELECT spec_ins  
   REPLACE cert_type WITH pc_CertTyp
   LOCAL oGen as medGeneric OF generic
   oGen=CREATEOBJECT("medGeneric")
   
   	C_STR="update tblSpec_ins  set cert_type='" + pc_CertTyp + ;
   	  "' where id_tblSpec_ins='" + STR(ntxn_id) + "' and  active =1"
	
	l_Retval= oGen.sqlexecute(C_STR,"")
   
   
   

ENDIF

**EF 3/25/05 - always print 'Med records' cert first
ncntr = RAT( "B", l_cCertType)
IF ncntr <> 0
   l_Cert = STRTRAN( l_cCertType, "B", "", 1, 2)
   l_cCertType ="B" + l_Cert
endif
**EF -end

nRec = LEN( l_cCertType)
l_nCnt = 1
DO WHILE .T.
   IF l_nCnt > nRec
      EXIT
   ENDIF
   l_cDblLtr = SUBSTR( l_cCertType, l_nCnt, 1)
   l_cDblLtr2 = STRTRAN( l_cCertType, l_cDblLtr, "", 2,  1)
   l_cCert = SUBSTR( l_cDblLtr2, l_nCnt, 1)
   l_cCertType = l_cDblLtr2
   STORE "" TO l_cWhat, l_cWhat1, l_cBe, l_cTense, c_show

   DO CASE
   		
   &&05/07/2010 added "D" for CAD lit
   
   CASE l_cCert == "D" AND pc_litcode<>'FLR'
         l_cWhat = "disability records"
         l_cWhat1 = "disability records"
         l_cBe = "are"
         c_show = "sent to"
         l_cTense = "was"
         DO printgroup WITH mv_c, "Cert_R"
   
      CASE l_cCert == "X"
         l_cWhat = "radiology materials/records"
         l_cWhat1 = "film(s)"
         l_cBe = "is"
         l_cTense = "was"
         c_show = "have been forwarded to"
         DO printgroup WITH mv_c, "Cert_X"

      
			
      CASE l_cCert == "P" AND pc_litcode<>'FLR'
         l_cWhat = "pathology materials/records"
         l_cWhat1 = "pathology/cytology"
         l_cBe = "are"
         c_show = "sent to"
         l_cTense = "was"
         DO printgroup WITH mv_c, "Cert_P"

      CASE l_cCert == "B"
         l_cWhat1 = "billing record(s)"
         l_cWhat = "billing"
         l_cBe = ""
         c_show = ""
         l_cTense = "were"
         DO printgroup WITH mv_c, "Cert_RB"
       OTHERWISE
      
         l_cWhat = "records"
         l_cWhat1 = ""
         l_cBe = ""
         c_show = ""
         l_cTense = "were"
         DO printgroup WITH mv_c, "Cert_RB"
        

*!*	      CASE l_cCert == "E"
*!*	         l_cWhat = "echocardiogram materials/records"
*!*	         l_cWhat1 = "echocardiogram(s)"
*!*	         l_cBe = "are"
*!*	         c_show = ""
*!*	         l_cTense = "was"
*!*	         DO printgroup WITH mv_c, "Cert_E"

*!*	      CASE l_cCert == "F"
*!*	         l_cWhat = "photographs"
*!*	         l_cWhat1 = ""
*!*	         l_cBe = "are"
*!*	         c_show = ""
*!*	         l_cTense = "were"
*!*	         DO printgroup WITH mv_c, "Cert_F"

*!*	      CASE l_cCert == "C"
*!*	         l_cWhat = "cardiac catheterization materials/records"
*!*	         l_cWhat1 = "cardiac catheterization(s)"
*!*	         l_cBe = "are"
*!*	         c_show = ""
*!*	         l_cTense = "was"
*!*	         DO printgroup WITH mv_c, "Cert_E"

   ENDCASE

   l_nCnt = l_nCnt + 1
   **3/19/07 - addded for SRQ lit cases	
   **c_Specmark= IIF(pc_litCode='SRQ', 'S','')
 
	
	l_GetRps= rpslitdata (pc_litcode)
	
   
   c_Specmark=ALLTRIM(UPPER(NVL(pc_litcode,"")))+"."+ALLTRIM(UPPER(NVL(pc_Initials,"")))
   
   DO PrintField WITH mv_c, "SpecMark", c_Specmark
   **3/19/07 - end
	
   DO printfield WITH mv_c, "What", ALLTRIM( l_cWhat)
   DO printfield WITH mv_c, "Cap", UPPER( ALLTRIM( l_cWhat))
   DO printfield WITH mv_c, "What1", ALLTRIM( l_cWhat1)
   DO printfield WITH mv_c, "Be", ALLTRIM( l_cBe)
   DO printfield WITH mv_c, "How", ALLTRIM( c_show)
   DO printfield WITH mv_c, "Tense", ALLTRIM( l_cTense)
   DO printfield WITH mv_c, "InfoText", ;
      STRTRAN( STRTRAN( szEdtReq, CHR(13), " "), CHR(10), "")

   DO printgroup WITH mv_c, "Case"
   DO printfield WITH mv_c, "Plaintiff", ALLTRIM( pc_plcaptn)
   DO printfield WITH mv_c, "Defendant", ALLTRIM( pc_dfcaptn)
   DO printfield WITH mv_c, "Dist", ALLTRIM( pc_maiden1)

   DO printgroup WITH mv_c, "Control"
   DO printfield WITH mv_c, "LrsNo", pc_lrsno
   DO printfield WITH mv_c, "Tag", ALLTRIM( STR( ntag))

   DO printgroup WITH mv_c, "Plaintiff"
   DO printfield WITH mv_c, "FirstName", pc_plnam
   DO printfield WITH mv_c, "MidInitial", ""
   DO printfield WITH mv_c, "LastName", ""
   IF TYPE('pd_pldob')<>"C"
			pd_pldob=DTOC(pd_pldob)
   ENDIF
   DO printfield WITH mv_c, "BirthDate",  pd_pldob
      DO printfield WITH mv_c, "SSN", pc_plssn

 IF l_flrbatch
 **3/31/09 - flrbatch does not need to look at the timesheet
  DO printgroup WITH mv_c, "Deponent"
  DO printfield WITH mv_c, "Name",  ALLTRIM(Spec_ins.descript)
 ELSE
 
	SELECT timesheet  
   DO printgroup WITH mv_c, "Deponent"
   IF NOT EOF()  
      DO printfield WITH mv_c, "Name", UPPER( ALLTRIM( timesheet.Descript))
        
   ELSE
      DO printfield WITH mv_c, "Name",  ""
   ENDIF
  endif
ENDDO

*set procedure to (curproc)   &EF 06/17/04
WAIT CLEAR   
SELECT( dbInit)
RETURN mv_c
*******************************************************************
* 