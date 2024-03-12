*****************************************************************************
** EF 01/22/09- added getservd
** EF 4/26/06 -Added to the VFP proj.
*****************************************************************************
* gfHServe.PRG - return Subpoena Serve Date
*                As of 12/13/03 this date goes on Check Stub 
*                and it is also calculated in Subp_pa as ldHandserve
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
* 12//97  Hsu   Initial release
*****************************************************************************
** Called by LaserChk
Parameter lcClient, lnTag
Private llNotice, ldReturn, llHandsrv, llTam, lcLit

ldReturn = d_null
*llNotice = gfuse("psNotice")
*llTam    = gfuse("Tamaster")
oMed = createobject('generic.medgeneric')

select master
lcLit = master.Litigation
*set order to cl_code
C_STR="SELECT * FROM tblPSnotice " ;
	+ " where cl_code ='" + fixquote(lcClient) ;
	+ "' and tag ='" + STR(lnTag) + "' and active =1"
l_done=oMed.sqlexecute(C_STR, "PsNotice")


select psNotice
*set order to clTag
if NOT EOF()&&seek(lcClient + "*" + str(lnTag))
	*select Tamaster
	*if seek(lcClient)
		*lcLit = Tamaster.Litigation		
		*select psNotice		
	    llHandsrv = psNotice.hs_notice
	    *ldHandServe = Txn_date + IIF( llHandsrv, IIF( alltrim(lcLit) = "A", 4, 5), 10)
	    ldHandServe =getservd(Txn_date, hs_notice )      
        ldHandServe = gfChkDat( ldHandServe, .F., .F.)
		ldReturn = ldHandServe
	*endif
endif

*=gfUnuse("Tamaster", llTam)
*=gfUnuse("psNotice", llNotice)
SELECT psNotice
USE

return ldReturn