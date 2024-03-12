**function qcdoctype

PARAMETERS lcCode
LOCAL c_code as String


*!*	NCLC	Tag Level Docs                                    
*!*	NCC1	Case Levl Authorization                           
*!*	NCC2	Case Level with Tags                              
*!*	FA01	Authorizations                                    
*!*	FI01	Interrogatories                                   
*!*	FS01	Supporting Documents                              
*!*	FC01	Counsel Produced Records                          
*!*	FO01	Case Level Other Docs     

DO case

CASE  INLIST(lcCode , 'NCC1', 'NCLC') &&AUTHORIZATION/ tag level -old way
	c_code='A'
CASE lcCode ='NCC2' &&case level-old way
	c_code='C'
CASE lcCode='FC01'
	c_code='F' && Councel Produced Records	
CASE lcCode='FI01'
	c_code='I' && Interrogatories    
CASE lcCode='FS01'
	c_code='S' && Supporting docs
CASE lcCode='FO01'
	c_code='O' && Other case level docs	
CASE lcCode='FA01'
	c_code='Z' && Authorizations  new way	
OTHERWISE 
	c_code='W' && all web images
ENDCASE





RETURN c_code