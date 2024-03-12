*******************************************************************************

*PROCEDURE ListSubp
*EF 11/05/05- Lists all txn 11/44 for a tag. Called by frmDeponentoptions.
LOCAL c_TimesheetId as String


CREATE CURSOR DepoList (id_tblTimesheet c(36), Descript C(117))
SELECT spec_ins

IF NOT EOF() 
      scan
        INSERT INTO DepoList ;
            ( id_tblTimesheet, Descript ) ;
            VALUES ;
            ( spec_ins.id_tblTimesheet, DTOC(spec_ins.txn_date) +  STR(spec_ins.tag)  + STR(spec_ins.txn_code) + " " + LEFT(spec_ins.descript,90) +  ;
            IIF(spec_ins.type=="S", "SUBP", ;
            IIF(spec_ins.type=="A", "AUTH", "")))
              
         INSERT INTO DepoList ;
            ( id_tblTimesheet, Descript) ;
            VALUES ;
            ( spec_ins.id_tblTimesheet, SPAC(4)  + "*" + REPLICATE("-",180) + "*" )&&"Ú" + REPLICATE("Ä",66) + "¿")
            
         SELECT spec_ins
         FOR nLoop = 1 TO MEMLINES( spec_ins.spec_inst)
            IF NOT EMPTY(MLINE( spec_ins.spec_inst, nloop))
               INSERT INTO DepoList ;
                  ( id_tblTimesheet, Descript ) ;
                  VALUES ;
                  ( spec_ins.id_tblTimesheet, SPACE(4) +  "" +  ;
                  PADR(ALLTRIM(MLINE(spec_ins.spec_inst, nLoop)),80," ") + "")
            ENDIF
            SELECT spec_ins
         ENDFOR
         
         INSERT INTO DepoList ;
            ( id_tblTimesheet, Descript) ;
            VALUES ;
            ( spec_ins.id_tblTimesheet, SPACE(4)  + "*" + REPLICATE("-",180) + "*")&&"À" + REPLICATE("Ä",66) + "Ù")
      
     
   ENDSCAN
ON KEY

SELECT depolist
GO top

SET ESCAPE OFF
ON ESCAPE DO CLOSEWINDOW("")

DEFINE WINDOW w_2ndRQ from 1,3 to 19,89  ;
FONT 'Arial',9  ;
TITLE " Press <Ctrl+W> To Select Deponent; <Esc> To Cancel "
ACTIVATE WINDOW w_2ndRQ
BROWSE FIELDS Descript:H="DATE       TAG        DESCRIPTION" + ;
   "                                       TYPE" ; 
NOLGRID NORGRID    ;
COLOR SCHEME 10 NOEDIT 

DEACTIVATE WINDOW w_2ndRQ
RELEASE WINDOW w_2ndRQ



IF  LASTKEY()=27    
   c_TimesheetId= CLOSEWINDOW("")  
  
ELSE  
	c_TimesheetId= CLOSEWINDOW(DepoList.id_tblTimesheet)
ENDIF

ENDIF
RETURN c_TimesheetId
*****************************************************************
PROCEDURE CLOSEWINDOW()
PARAMETERS RetId
IF NOT EMPTY(RetId)
	l_cancel = .F.
    bSelect = .T.
ELSE
 	l_cancel = .T.
    bSelect = .F.
    
endif   
RETURN RetId