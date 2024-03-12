		**PROCEDURE UpdHld4
		PARAMETERS n_tag
		LOCAL c_str, c_cl,  c_md, c_md, c_reqid,  c_name, oMed1 as Object
		oMed1=CREATEOBJECT("request.medrequest")
		c_cl=FIXQUOTE(pc_clcode)
		c_iss=PC_ISSTYPE
		c_md =pc_mailid
		c_name=FIXQUOTE(PC_DESCRPT)
		IF !USED ("LatestReq")
			oMed1.closealias("ReqsId")
			c_str="select dbo.fn_GetID_tblRequest ('" + c_cl+ "','" +  STR(n_tag) + "')"
			l_RqId=oMed1.sqlexecute( 	c_str, "ReqsId")
			c_reqid=ReqsId.exp
		ELSE
			c_reqid=LatestReq.id_tblRequests
		ENDIF
		
		
		IF  EMPTY(NVL(c_reqid,''))
			=gfmessage("The[Update Hold Request] memo was not added. Contact IT.")			
		ELSE			
			c_str= ""
			c_str= "Exec dbo.gfAddTxnCom '" + DTOC(DATE())+  " ', '" ;
			+ LEFT(c_name,50) + "'," + c_cl+ ",' " ;
			+ ALLTRIM(STR(4)) + "','"  + ALLTRIM(STR(n_tag)) + "','" ;
			+ c_md + "','" + STR(0) + "','" ;
			+ ALLTRIM(STR(0)) + "','" +  "" + "','" ;
			+ ALLTRIM(STR(0)) + "', '"  + "" + "','"  ;
			+ ALLTRIM(c_iss)+ "', '" ;
			+ ALLTRIM(pc_userid) + "','" ;
			+ c_reqid +"', 'Update Hold Request'"
		oMed1.sqlexecute(c_str,'')
		ENDIF
	RELEASE oMed1	
		return