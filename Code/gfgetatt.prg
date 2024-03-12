FUNCTION gfGetAtt
***EF 12/27/05 -Added to the VSS
************************************************************
* - EF - 05/16/03  gets an attention line from mail files.
* Called by : AfaxRmd, Subp_pa
* Calls: gfDepInf
* 06/20/03 gfMail renamed gfDepInf to avoid conflicts
*************************************************************
PARAMETERS lc_dept
PRIVATE lcAttn, l_dept, c_match
STORE "" TO lcAttn, l_dept


IF lc_dept = "H"
l_dept = ALLTRIM(SPEC_INS.DEPT)
      **fill the "Attention" info for cover pages
      IF NOT EMPTY( l_dept)
         DO CASE
            CASE l_dept = "E"
               lcAttn = "ATTN: ECHOCARDIOGRAM DEPARTMENT"
            CASE l_dept = "R"
               lcAttn = "ATTN: RADIOLOGY DEPARTMENT"
            CASE l_dept = "P"
               lcAttn = "ATTN: PATHOLOGY DEPARTMENT"
            CASE l_dept = "B"
               lcAttn =  "ATTN: BILLING DEPARTMENT"
            OTHERWISE
               IF EMPTY( lcAttn)
                  lcAttn = "ATTN: MEDICAL RECORDS DEPARTMENT"
               ENDIF
         ENDCASE
      ENDIF
        

ELSE
IF TYPE('pc_MAttn')="L"
   pc_MAttn=.NULL.
ENDIF
 lcAttn = IIF( ISNULL( pc_MAttn), "", "ATTN: " + pc_MAttn)
ENDIF

RETURN  lcAttn
