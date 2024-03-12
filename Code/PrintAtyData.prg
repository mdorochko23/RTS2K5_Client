***************************************************************
**3/31/06 - atty data
*PROCEDURE PrintAtyData
PARAMETERS lc_atty
 _Screen.MousePointer=11
c_Atty=fixquote(lc_atty)
pl_GetAt = .F.
DO gfatinfo WITH c_Atty, "M"           


   c_Address = IIF(EMPTY(pc_AtySign),UPPER( pc_AtyName),UPPER( pc_AtySign))+ CHR(13)
   c_Address = c_Address + IIF( NOT EMPTY( ALLTRIM( pc_AtyFirm)), ;
      ALLTRIM( pc_AtyFirm) + CHR(13), "")
   c_Address = c_Address + IIF( NOT EMPTY( ALLTRIM( pc_Aty1Ad)), ;
      ALLTRIM( pc_Aty1Ad) + CHR(13), "")
   c_Address = c_Address + IIF( NOT EMPTY( ALLTRIM( pc_Aty2Ad)), ;
      ALLTRIM( pc_Aty2Ad) + CHR(13), "")
   *c_Address = c_Address + IIF( NOT EMPTY( ALLTRIM( pc_AtyFirm)), ;
      ALLTRIM( pc_AtyFirm) + CHR(13), "")
   c_Address = c_Address + IIF( NOT EMPTY( ALLTRIM( pc_Atycsz)), ;
      ALLTRIM( pc_Atycsz) + CHR(13), "")




 _Screen.MousePointer=0




RETURN  c_Address
