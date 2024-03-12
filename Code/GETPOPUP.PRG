PROCEDURE GetPopup
*******************************************************************
*** Getpopup.prg - A general popup routine to pop up information from
*** a database and allow selection.

* 03/24/05 DMA Activate Esc Key on "Cancel" bar of popup
* 10/25/01 HN  Adapted from GetPop.prg. Add a filter condition.
*              Make more generic (Remove code relating to Specific Files)
* 10/20/99 DMA Expand date field in popups for Y2K 4-digit years
* 10/12/01 DMA Exclude "retired" acct managers and sales staff
* 08/13/01 EF  Show only 'true' acctmgr/sales names
* 02/01/00 DMA Remove gly2k references

PARAMETERS fname, dispexp, toadd, retfld, title, row, col, initval, ;
   lNoSort, lcFilter

** ---------------  Parameter Descriptions -----------------
** fname    = Name of the file to bring up
** dispexp  = The expression to display from file
** toadd    = The text to add as a selection to popup
** retfld   = The field to be returned from the file
** title    = The title of the popup
** row      = The starting row of the popup
** col      = The starting column of the popup
** initval  = The initial value to display from the popup, if its "ZZZ"
**            no entry is added to the popup.
** lNoSort  = True if popup shouldn't be sorted on selection field
** lcFilter = Filter expression to use for lookup.
** ---------------------------------------------------------

SET CONFIRM ON
DO DefKey

PRIVATE curfile, rettxt, PopArr, maxwidth, startbar, n_numbars
curfile = ALIAS()
SELECT 0
USE &fname ALIAS TheFile AGAIN

IF TYPE("lcFilter") = "C"
   SELECT TheFile.&dispexp, TheFile.&retfld ;
      FROM TheFile INTO ARRAY PopArr WHERE &lcFilter
ELSE
   SELECT TheFile.&dispexp, TheFile.&retfld ;
      FROM TheFile INTO ARRAY PopArr
ENDIF

IF NOT (TYPE("lNoSort")=="L")
   lNoSort = .F.
ENDIF
IF NOT (lNoSort)
   =ASORT(PopArr)
ENDIF
maxwidth = LEN(title)+2
n_numbars = ALEN(PopArr, 1)
startbar = 1

FOR i = 1 TO n_numbars
   IF initval <> "ZZZ"
      IF ALLTRIM(initval) == ALLTRIM(PopArr[i,2])
         startbar = i
      ENDIF
   ENDIF

   DO CASE
      CASE TYPE("PopArr[i,1]") = "C"
         IF LEN(ALLTRIM(PopArr[i,1])) > maxwidth
            maxwidth = LEN(ALLTRIM(PopArr[i,1]))
         ENDIF
      CASE TYPE("PopArr[i,1]") = "D"
         maxwidth = MAX(maxwidth, 10)
   ENDCASE
ENDFOR

IF INITVAL <> "ZZZ"
   IF Startbar = 0                              && Not in the popup, will be added as choice
      DIMENSION PopArr(n_numbars+1, 2)
      n_numbars = n_numbars + 1
      PopArr(n_numbars, 1) = initval
      PopArr(n_numbars, 2) = initval
      IF NOT( lNoSort)
         = ASORT(PopArr)
      ENDIF

      startbar = 1
      FOR i = 1 TO n_numbars
         IF ALLTRIM(initval) == ALLTRIM(PopArr[i,2])
            startbar = i
         ENDIF
         DO CASE
            CASE TYPE("PopArr[i,1]") = "C"
               IF LEN(ALLTRIM(PopArr[i,1])) > maxwidth
                  maxwidth = LEN(ALLTRIM(PopArr[i,1]))
               ENDIF
            CASE TYPE("PopArr[i,1]") = "D"
               maxwidth = MAX(maxwidth, 10)
         ENDCASE
      ENDFOR
   ENDIF
ENDIF

SELECT TheFile
USE

DEFINE POPUP ThePop ;
   FROM row, col TO MIN(row+n_numbars+3, 23), MIN(col+maxwidth+3,79) ;
   TITLE title

FOR i = 1 TO n_numbars
   DEFINE BAR i OF ThePop ;
      PROMPT IIF(TYPE("PopArr[i,1]")="D", DTOC(PopArr[i,1]), PopArr[i,1])
ENDFOR

DEFINE BAR n_numbars+1 OF ThePop PROMPT "\-"
DEFINE BAR n_numbars+2 OF ThePop PROMPT "Cancel" KEY ESC

ON SELECTION POPUP ThePop DEACTIVATE POPUP ThePop
** SIZE POPUP ThePop TO CNTBAR("ThePop"),min(col+maxwidth,79)

DO WHILE .T.
   ACTIVATE POPUP ThePop BAR MAX(startbar, 1)
   IF BAR() >= 1
      EXIT
   ENDIF
ENDDO

IF BAR() > n_numbars
   rettxt  = ""
ELSE
   rettxt = PopArr[BAR(), 2]
ENDIF
IF NOT EMPTY(curfile)
   SELECT (curfile)
ENDIF

RELEASE curfile, PopArr, maxwidth, startbar

DEACTIVATE POPUP ThePop
RELEASE POPUP ThePop
SET CONFIRM OFF
POP KEY
RETURN rettxt

PROCEDURE DefKey
PUSH KEY CLEAR
*on key label "ESC" keyboard ""
RETURN
