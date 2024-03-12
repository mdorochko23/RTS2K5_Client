**05/11/2011 EF: show duplicate issues per a case
*FUNCTION ShwDuptag
PARAMETERS c_code, c_depname, c_id_tblMaster, c_id_tblRequests
LOCAL ogen AS Object, l_Cancel AS Boolean,  C_STR AS String, n_DepChars as Integer
l_Cancel=.F.
n_DepChars=0
pl_DuplTag=.f.
		ogen = CREATEOBJECT("generic.medgeneric")

		C_STR="EXEC  [dbo].[GetTagsbyClcode]  '" +fixquote(c_code) + "' "
		l_RStatus=ogen.sqlexecute(C_STR,"DepCheck")

		C_STR="SELECT * FROM dbo.tblRStatus WITH (NOLOCK) where active =1"
		l_RStatus=ogen.sqlexecute(C_STR,"RecStat")
		
		n_DepChars = MIN( LEN( ALLT( c_depname)), 5)

		SELECT A.DESCRIPT ,  A.TAG, ;
			B.STATUS ;
			FROM DepCheck A, RecStat B ;
			INTO CURSOR RevIssue ;
			WHERE A.CL_code = pc_clcode AND ;
			A.TAG <> pn_tag AND ;
			LEFT( A.DESCRIPT, n_DepChars) == LEFT( c_depname, n_DepChars)  AND;
			A.STATUS = B.CODE ;
			ORDER BY A.DESCRIPT, A.TAG


		IF RECCOUNT("RevIssue") > 0
			n_issueOK = 1
			lcDepNameRevIssue=c_depname
			l_Cancel=goApp.OpenForm("issued.frmRevIssue", "M", c_id_tblMaster, c_id_tblMaster,c_id_tblRequests, lcDepNameRevIssue)
			pl_DuplTag=l_Cancel
		ELSE
			pl_DuplTag=.F.
		ENDIF
		
		SELECT DepCheck
		USE
		SELECT RecStat
		USE
		SELECT RevIssue
		USE
		RELEASE ogen
		
		
		RETURN l_Cancel