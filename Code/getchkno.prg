FUNCTION GetChkNo
*** Gets the next available check number for the specific office
*** Pittsburgh and Maryland offices use the King of Prussia office's
*** counter for next available check number.
** 06/04/2002  DMA  Get Texas check number from separate file
PARAMETERS c_Office
PRIVATE n_check_no, l_ChkBig

IF TYPE("c_Office") <> "C"
   c_Office = "P"
ENDIF
oMed = CREATE("generic.medgeneric")
n_check_no = 0
l_GetChk =omed.sqlexecute("SELECT  dbo.getnextchknum ('" +c_Office + "')" , "NextChk")
IF l_GetChk
	n_check_no= NextChk.exp
	c_Table =IIF(c_Office="T","tblChkbigtx","tblChkBig")
	c_Field =IIF(c_Office="T","Texas","Num")
	
	C_STR="Update " +  c_Table + " set " + c_Field ;
		+ "='" + STR(n_check_no) + "'"
l_Retval= oMed.sqlexecute(C_STR,"")

	
IF NOT l_Retval
gfmessage("The counter for the check number has not been updated. Contact IT" )
ENDIF 	
ELSE
  n_check_no=0
  gfmessage("Cannot get the next check's number" )
endif			
*l_ChkBig = gfuse( IIF( c_Office = "T", "ChkBigTX", "ChkBig"))
*GO TOP

*DO WHILE NOT RLOCK()
*ENDDO

*IF c_Office == "T"
   *n_check_no = Texas + 1
  *REPLACE Texas WITH n_check_no
*ELSE
   *n_check_no = num + 1
   *REPLACE num WITH n_check_no
*ENDIF

*UNLOCK ALL

*= gfUnUse( IIF( c_Office = "T", "ChkBigTx", "ChkBig"), l_ChkBig)
RETURN n_check_no
