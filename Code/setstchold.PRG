PROCEDURE SetSTCHold
*PARAMETERS c_clcode, n_tag
PARAMETERS c_tblRequests
LOCAL nHold as integer
nHold=0
* 02/26/04 DMA Turn off research flag when an STC change is logged
*nHold = rechold( c_clcode, n_tag)
nHold = rechold( c_tblRequests)
csql="Update tblRequest set hold = " + STR(nHold) + ", Research = 0 " ;
+ " Where id_tblRequests ='" + c_tblRequests + "'" 

oMed = CREATE("generic.medgeneric")
oMed.sqlexecute (csql, "")

Return