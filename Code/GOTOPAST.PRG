* Goes back in time*


PARA d_datein, l_display, l_reenter

PRIVATE n_month, n_dow, n_day, d_tmpdate


DO WHILE .T.

   * save original date
   d_tmpdate = d_datein

   * Convert Sat. and Sun. to the following Monday
   DO CASE
      CASE DOW( d_datein) = 1
         d_datein = d_datein-2
      CASE DOW( d_datein) = 7
         d_datein = d_datein - 1
   ENDCASE
   n_month = MONT(d_datein)
   n_dow = DOW (d_datein)
   n_day = DAY (d_datein)

   * Check for standard holidays
   DO CASE

      CASE INLIST(n_month, 3, 4, 6, 8)
         * Fall-through for months w/no holidays!

      CASE n_month = 1
         DO CASE
            CASE n_day = 1
               * New Year's on weekday
               * Move to next day, or next Monday if today is Friday
               d_datein = d_datein - IIF (DOW(d_datein)=6, 3, 1)
            CASE n_day = 2 AND n_dow = 2
               * New Year's on Sun. -> Monday Holiday: move to previous friday
               d_datein = d_datein - 3       
         ENDCASE

*!*	      CASE n_month = 2 AND n_dow = 2 AND BETWEEN( n_day, 15, 21)
*!*	         * President's day (3rd. Monday)
*!*	         d_datein = d_datein - 2
      CASE n_month = 5 AND n_dow = 2 AND BETWEEN( n_day, 25, 31)
         * Memorial Day (last Monday)
         d_datein = d_datein -3

      CASE n_month = 7
         DO CASE
           CASE n_day = 7 AND n_dow=2  
               *move to Thursday  before Holiday
               d_datein = d_datein 
            CASE n_day = 3 AND n_dow=6 
               * Independence Day on Sat. -> Friday Holiday
               d_datein = d_datein - 3
            CASE n_day = 4
               * Independence Day on weekday
               * Move to next day, or Monday if today is Friday

               d_datein = d_datein - IIF (DOW(d_datein)=6, 1, 1)
               
            CASE n_day = 5 AND n_dow = 2
               * Independence Day on Sun. -> Monday Holiday
               d_datein = d_datein -2
         ENDCASE

      CASE n_month = 9 AND n_dow = 2 AND n_day < 8
         * Labor Day (1st Monday)
         d_datein = d_datein - 3     
   CASE n_month = 10  and   n_dow =2 AND   BETWEEN(n_day, 4, 14)  
         *Columbus day -
          d_datein = d_datein - 3             
         
        
      CASE n_month = 11

         DO CASE        
         *Veterans Day 
         	 CASE n_day = 11 AND n_dow =2 &&monday
         	   d_datein = d_datein -3        
             CASE n_day = 11 AND n_dow =6  &&friday
          	    d_datein = d_datein -1    
             CASE n_day = 10 AND n_dow =6  &&friday
          	    d_datein = d_datein -1         	                 
             CASE n_dow = 2 AND BETWEEN(n_day, 22, 26)
               * Next Monday go to privious  friday
                d_datein = d_datein -3              
            CASE n_dow = 5 AND BETWEEN(n_day, 22, 28)
               * Thanksgiving (4th Thursday) go to wednesday
               d_datein = d_datein -1
*!*	             CASE n_dow = 6 AND BETWEEN(n_day, 22, 28)
*!*	               * Friday go to wednesday 
*!*	               d_datein = d_datein -2
         ENDCASE

      CASE n_month = 12
      * 12/26/2017 MD added to skip to the right day
	IF INLIST(n_day ,24,25) AND INLIST(DOW(d_datein),2,3,4,5,6)
	   llFindWorkDay=.F.
	    DO while llFindWorkDay=.F.
       	     d_datein=d_datein-1
	            IF INLIST(DOW(d_datein),2,3,4,5,6) AND  !INLIST(DAY (d_datein),24,25)
       	          llFindWorkDay=.T.
       	      ENDIF 
	     enddo                
         ENDIF 
         * not sure why the check is only for Saturday but for now keep it as it is
         
         IF n_Day=31 AND n_dow = 6
             d_datein = d_datein - 1
         ENDIF 
         * 12/26/2017 - MD commented code bellow
*!*	         DO CASE        
*!*	            CASE n_day = 24 AND n_dow = 6
*!*	               * Christmas Day on Sat. -
*!*	               d_datein = d_datein -1
*!*	            CASE n_day = 25
*!*	               * Christmas Day on weekday
*!*	               * Move to next day, or Monday if today is Friday
*!*	               d_datein = d_datein - IIF (DOW(d_datein)=6, 3, 1)
*!*	            CASE n_day = 26 AND n_dow = 2
*!*	               * move to friday
*!*	               d_datein = d_datein -3
*!*	            CASE n_day = 31 AND n_dow = 6
*!*	               * New Year's on Sat. 
*!*	               d_datein = d_datein - 1
*!*	         ENDCASE
   ENDCASE

   IF d_datein <> d_tmpdate
      IF l_display
         DEFINE WINDOW w_date FROM 18,0 TO 24,79 DOUBLE
         ACTI WINDOW w_date
         n_ok = 1
         @0,5 SAY DTOC( d_tmpdate)+ " is a weekend or holiday "+;
            "and should be changed to "+ DTOC( d_datein)+ "."
         @4,18 SAY "Highlight your choice and press <ENTER>."
         @2,14 PROMPT "Accept "+DTOC(d_datein)
         @2,32 PROMPT "Keep "+DTOC(d_tmpdate)
         @2,48 PROMPT "Re-enter Date"
         MENU TO n_ok
         DEACT WIND w_date
         DO CASE
            CASE n_ok = 2
               d_datein = d_tmpdate
            CASE n_ok = 3
               IF l_reenter
                  ACTI WIND w_date
                  @0,5 SAY DTOC( d_tmpdate)+ " is a weekend or holiday "+;
                     "and should be changed to "+ DTOC( d_datein)+ "."
                  @2,14 SAY "Accept "+DTOC(d_datein)
                  @2,32 SAY "Keep "+DTOC(d_tmpdate)
                  @2,48 SAY "Re-enter Date"
                  @4,23 SAY "Enter New Date : " GET d_datein
                  READ
                  DEACT WIND w_date
                  LOOP
               ELSE
                  d_datein = {}
               ENDIF
            CASE n_ok = 0
               d_datein = {}
         ENDCASE
         RELE WIND w_date
      ENDIF
   ENDIF

   EXIT

ENDDO

RETURN d_datein
