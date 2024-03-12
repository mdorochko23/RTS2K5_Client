********************************************************************************
*PROCEDURE  OMRPage
**EF 03/05/2012
********************************************************************************


PRIVATE  c_Save AS STRING
c_Save = SELECT()
DO PrintGroup WITH mv, "OMRPage"
SELECT (c_Save)
WAIT CLEAR
RETURN



