PARAMETERS c_Amname
LOCAL l_RetVal AS Boolean,  C_STR AS STRING, omedfax AS OBJECT
oMedFax = CREATEOBJECT("generic.medgeneric")
STORE .F. TO l_RetVal

c_str=" exec  [dbo].[GetAMFaxCode] " + c_Amname
l_RetVal=oMedFax.sqlexecute(C_STR, "AMFax")
RELEASE oMedFax
RETURN l_RetVal

