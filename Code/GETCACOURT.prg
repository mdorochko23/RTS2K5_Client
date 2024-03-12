**EF 3/30/06 - fill court's vars to later use
*PROCEDURE GetCACourt
PARAMETERS c_court
PRIVATE c_Alias as String
c_Alias=ALIAS()
oMED.sqlexecute("select * from tblcourt where court= '" + ;
				c_court + "'", "Court")
 	SELECT Court 
     
         pc_c1Name  = Court.Court
         pc_c1Desc  = Court.Desc
         pl_c1Form  = Court.HasForm
         pl_c1SSubp = Court.ScanSubp
         pn_c1Due   = Court.Add_Due
         pl_c1Notic = Court.Notice
         pc_c1Cnty  = Court.County
         pn_c1Hold  = Court.Hold
         pn_c1Cmply = Court.Comply
         pl_c1Prvdr = Court.Provider
         pl_c1PrtSc = Court.PrintSC
         pl_c1Cert  = Court.CourtCert
         pc_c1Addr1 = Court.Add1
         pc_c1Addr2 = Court.Add2
         pc_c1Phone = Court.Phone
         pc_c1City  = Court.City
         pc_c1State = Court.State
         pc_c1Zip   = Court.Zip
         pc_RpsForm = ALLTRIM( Court.RPSForm)
         pl_CrtFlng = Court.CrtFiling

     

SELECT (c_Alias)

RETURN
