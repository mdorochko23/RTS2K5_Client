FUNCTION RevwStat
*  Determines record's review status text description, based
*  on the review status code (passed as a parameter)
*  03/25/04 IZ if parameter is equal "C", then line will read 
*              "Review Completed By" as per Drew request of holding the user's name
lPARAMETERS c_revstat
LOCAL lretval

DO CASE
   CASE PCOUNT() = 0
      lretval = "Unknown"
   CASE c_revstat = "N"
      lretval = "Non-review deponent"
   CASE c_revstat = "A"
      lretval = "Awaiting review"
   CASE c_revstat = "C"
      lretval = "Review completed by "
   CASE c_revstat = "U"
      lretval = "Record not received"
   OTHERWISE
      lretval = "Unknown"
ENDCASE
RETURN lretval
