FUNCTION AddStcTxn
**EF 10/07/05 - adds entry into the tblTimesheet and tblComment
PARAMETERS cDESCRIPT, ccl_code, ntxn, ntag, cmailid_no, ctype, clogin ,	cid_tblcode30, cMemo, lCommOk
**lCommOk : .f./.t. if an entry to the comment table is needed
LOCAL C_STR AS STRING, l_done AS Boolean, l_EntryID as Boolean
C_STR=""
oMed = CREATEOBJECT("generic.medgeneric")
c_Desc=oMed.cleanstring(cDESCRIPT)
C_STR= "Exec dbo.gfAddTxn '" + DTOC(DATE())+  " ', " ;
	+ ALLTRIM(NVL(c_DESC,"")) + " ,'" + ccl_code + "',' " ;
	+ ALLTRIM(STR(ntxn)) + "','"  + ALLTRIM(STR(ntag)) + "','" ;
	+ NVL(cmailid_no,"") + "','" + STR(0) + "','" ;
	+ ALLTRIM(STR(0)) + "','" +  "" + "','" ;
	+ ALLTRIM(STR(0)) + "', '"  + "" + "','" ;
	+ ctype + "','" ;
	+ ALLTRIM(clogin) + "','" ;
	+ cid_tblcode30 +"'"

l_done=oMed.sqlexecute(C_STR,"")


IF USED('EntryID')
	SELECT EntryID
	USE
ENDIF
l_EntryID= oMed.sqlexecute("select dbo.fn_GetID_tblTimesheet ('" + ccl_code + "','" ;
+ STR(ntag) +"','" + STR(ntxn)+ "','" +DTOC(DATE()) +"')", "EntryId")
IF l_EntryID AND lCommOk &&ntxn=51 
	l_Comm=oMed.sqlexecute("Exec gfAddCom '" + DTOC(DATE())+  " ', " ;
	     + ALLTRIM(c_DESC) + ",'" + ccl_code + "',' " ;
		 + ALLTRIM(STR(ntxn)) + "','"  + ALLTRIM(STR(nTag)) + "','" ;
		 + NVL(cmailid_no,"") + "','" + "" + "','" ;
		 + fixquote(NVL(cMemo,""))  + "','"  ;
		 + ALLTRIM(STR(0)) + "','"  ;		 
		 + ALLTRIM(clogin) + "','" + EntryID.exp +"'")
	
	l_done=l_Comm
Endif	

RELEASE oMed
RETURN l_done


