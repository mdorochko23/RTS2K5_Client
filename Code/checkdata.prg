** abstruct: checks the data

LPARAMETERS lcAlias
LOCAL lnFldCnt, lcFld, lnCurArea
lnCurArea=SELECT()
SELECT &lcAlias
SCAN
	FOR lnFldCnt=1 TO AFIELDS(laFlds)
	    lcFld=laFlds[lnFldCnt,1]
	    IF ISNULL(&lcFld)=.T.
		    DO CASE 
		       CASE  laFlds[lnFldCnt,2]="C"             
		             replace &lcFld WITH NVL(&lcFld,"")
		             IF ALLTRIM(&lcFld)=="0"
		                replace &lcFld WITH ""
		             ENDIF     
		       CASE  laFlds[lnFldCnt,2]="N"             
		             replace &lcFld WITH NVL(&lcFld,0)
		       CASE  laFlds[lnFldCnt,2]="L"             
		             replace &lcFld WITH NVL(&lcFld,.F.)
		       CASE  INLIST(laFlds[lnFldCnt,2],"D","T")  	                         
		             replace &lcFld WITH NVL(&lcFld,{})  	               
		       CASE  laFlds[lnFldCnt,2]="M"             
		             replace &lcFld WITH NVL(&lcFld,"")
		       CASE  laFlds[lnFldCnt,2]="M"             
		             replace &lcFld WITH NVL(&lcFld,"") 
		   ENDCASE 
		ENDIF  
		IF  INLIST(laFlds[lnFldCnt,2],"D","T") AND  CTOD(DTOC(&lcFld))={01/01/1900}            
		    replace &lcFld WITH {}
		ENDIF            
		IF  INLIST(laFlds[lnFldCnt,2],"C") AND  LEFT(ALLTRIM(&lcFld),10)="01/01/1900"
		    replace &lcFld WITH ""
		ENDIF          
	NEXT   
SELECT &lcAlias
ENDSCAN              
SELECT &lcAlias
GO TOP
SELECT (lnCurArea)