

**Abstract- strips off the non-ascii spaces
LPARAMETERS lcString
LOCAL lcLine, lnXX, lcChar
lcLine=""
IF ISNULL(lcString) OR TYPE("lcString")!="C"
   RETURN
ENDIF    
FOR lnXX=1 TO LEN(lcString)
    lcChar=SUBSTR(lcString,lnXX,1)
    IF (ASC(lcChar)>31 AND ASC(lcChar)<127) OR (INLIST(ASC(lcChar),145,146,10,13))
       lcLine=lcLine+lcChar
    ENDIF  
NEXT
RETURN lcLine   
