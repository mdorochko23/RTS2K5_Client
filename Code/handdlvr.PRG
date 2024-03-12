**Procedure HandDlvr
** Hand Delivery page to go with a request when a Hand Delivery or Orig subp requered by a location's data
PARAMETERS mv,  n_Tag, c_dep, d_date, c_phone	

WAIT WINDOW "Printing Service Form" NOWAIT 
			DO PrintGroup WITH mv, "HandDelivery"
			
			DO PrintField WITH mv,"DeponentName", c_dep	
			DO PrintField WITH mv,"DeponentPhone", c_phone	
			DO PrintField WITH mv, "CaseName", ALLTRIM( pc_plnam)						
			DO PrintGroup WITH mv, "Control"
			DO PrintField WITH mv, "Date", d_date
			DO PrintField WITH mv, "LrsNo", pc_lrsno
			DO PrintField WITH mv, "Tag", ALLTRIM( STR( n_Tag))
			
			

	
	RETURN  