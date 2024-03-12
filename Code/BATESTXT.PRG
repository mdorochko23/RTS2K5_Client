*******************************************************************
* PROGRAM: BATESTXT
* INITIAL RELEASE DATE: 6/5/02
*
* ABSTRACT: Create and maintain cases' Bates text files
*
* Called by: bateslbl.prg
* Calls:  batestxt.spr, addbtxt.spr, gfuse.prg, gfyesno.prg
*         gfunuse.prg
* Modifications:
*  08/10/06  md	 Modified to check pd_closing
*            old code - IIF(TYPE('pd_closing')='D',pd_closing,CTOD(pd_closing))
*  08/02/06  kdl New Motley area lits- Lead, Cvil, Asbestos
*  06/06/06  kdl Added human tissue/Motley
*  03/20/06  kdl Added Zyprexa/Motley-Co_Cnsl
*  03/02/06  kdl Added civil lit/egerton
*  02/22/06  kdl Intergel/Minnesota Bates number cnaged to 6 characters
*  02/10/06  kdl For pc_litcode = "C " AND pc_area = "Chambliss", changed set bates num to .t.
*  02/07/06  dma Add Minnesota Intergel
*  02/03/06  dma Add Bextra/Motley-Co_Cnsl
*  11/21/05  kdl Set Civil Chambliss deponent string length to 20 characters
*  10/31/05  kdl Added Guidant/Motley Co-Counsel
*  10/24/05  kdl Added Civil Chambliss
*  10/04/05  kdl 1) Added the capability to add/maintain Bates text data for
*                 Celebrex/Motley-Co-Cnsl and Bextra/Motley-Co-Cnsl cases.
*  09/21/05  kdl added default deponent string setup for Intergel
*  09/19/05  kdl added Intergel litigation
*  09/07/05  kdl Add vioxx Motley-Co-Cnsl
*  06/30/05  kdl Added HRT Cohen - doesn't use deponent data.
*  05/11/05  kdl Changed vioxx motley to start all tags at user input number and
*                 modified case default string
*******************************************************************
LPARAMETERS u_idtblmaster, c_clcode
obmed=CREATEOBJECT('medgeneric')
IF NOT USED('master')
	**10/01/18 SL #109598
	*obmed.sqlexecute("SELECT + FROM tblmaster WITH (INDEX (pk_tblmaster)) WHERE id_tblmaster='&u_idtblmaster.'",master)
	obmed.sqlexecute("SELECT + FROM tblmaster WHERE id_tblmaster='&u_idtblmaster.'",master)
ENDIF
DO gfgetcas

pd_closing=convrtDate(pd_closing)
   
PRIVATE lc_Rtsnum, lc_Rtstag, lc_Filetxt, ll_Exists, lc_TagTxt, ln_Fhndle, ;
   lc_CurTxt, lc_CaseTxt, ln_counter, la_Tags, lc_TimeStp, ln_TagCnt, ;
   la_Tagtxt, lc_NewTag, lc_BateNum, lc_Startpge, ln_NewTag, lc_CurArea, ;
   lc_Recused, lc_Filetmp, ll_TagEnab, ll_CaEnab, ll_BaEnab, ll_pgEnab, ;
   n_whichtag, lc_Recused, lc_CurOrd, ln_BateLen, ln_BateNum, lc_Start, ;
   lc_End, ln_Number, lc_FileSav, ll_FileSav, c_TxtType, n_CurArea, ;
   l_EditCase, l_SetDef, c_UniqMod, c_Factsht, c_Plaint, c_Supplto, ;
   l_Supplm, n_FstrtPg, l_FstrtPg, l_SetBtnum, n_tagstnum, l_Setstart, ;
   n_decimals, l_Contnum, lc_BateNm2, l_uniqtag, l_Cnoshow


STORE '' TO lc_Rtsnum, lc_Rtstag, lc_Filetxt, lc_TagTxt, lc_CurTxt, ;
   lc_CaseTxt, lc_TimeStp, lc_NewTag
n_CurArea = SELECT()
n_Decimals = SET( "DECIMALS")

*--file type identifier
IF INLIST( pc_litcode, "5  ", "52 ", "51 ", "HRT") && PPA, HRT
   c_TxtType = "C_2LINE"                        && file type is continuous 2-line
ELSE
   c_TxtType = "N_1LINE"                        && file type is non-continuous
ENDIF

*--set default values
*--11/14/03 kdl start: save exact setting
c_Exact = SET( "EXACT")
SET EXACT ON

ln_NewTag = 000
lc_Startpge = '001'                             && starting page for placement of bates stamps
lc_BateNum = '000001'                           && bates starting number for next script run
ln_bateLen = 6                                  && length of bates number
ln_BateNum = VAL( m.lc_BateNum)                 && numeric type of starting bates number
ln_Fhndle = 0
l_SetBtnum = .F.                                && controlls access for setting tag bates starting number
n_tagstnum = 0                                  && tag's starting bates number

DIMENSION la_Tagtxt[1]
DIMENSION la_Tags[1, 14]
la_Tags[1,1] = 'NONE'
la_Tagtxt[1] = 'NONE'
l_EditCase = .T.                                && case text edit flag
l_SetDef = .F.                                  && flag to tell system to set default
c_UniqMod = "N"                                 && type indicator for unique modification
l_Addbenab = .F.                                && Enable setting for addbtxt screen questions
c_Factsht = "N"                                 && default for tag type factsheet
c_Plaint = "N"                                  && default for tag type palintiff counsel produced
c_Supplto = ""                                  && default for mirror of tag string
l_Supplm = .F.                                  && Supplemental tag eneabled
n_FstrtPg = 000                                 && default starting page for fact sheet record set
l_FstrtPg = .F.                                 && access control to n_FstrtPg get
l_Contnum = .F.                                 && Continuous bates numbering through the case in addtion
&& to tag level
l_Cnoshow = .F.                                 && Continuous through case, but without display on tag lines

lc_BateNm2 = "N/A"
*--6/10/04 kdl start: new flag to control unique tag check
l_uniqtag = .T.                                 && set unique tag check function on

&& of descrptions - "N" for nothing but number

&& case and tag bates descriptions

m.lc_Filetmp = 'C:\TEMP\BATESTMP.TXT'

*!*	IF NOT USED("record")
*!*	   ll_Recused = gfuse("record")
*!*	ELSE
*!*	   ll_Recused = .T.
*!*	ENDIF
*!*	SELECT RECORD
*!*	m.lc_CurOrd = ORDER()
*!*	SET ORDER TO cltag

*--create record cursor
**10/01/18 SL #109598
*c_sql="SELECT * FROM tblrecord WITH (INDEX (ix_tblrequests_2)) WHERE cl_code='&pc_clcode.' AND tag="+STR( m.ln_NewTag)+" active=1 AND delted IS null"
c_sql="SELECT * FROM tblrecord WHERE cl_code='&pc_clcode.' AND tag="+STR( m.ln_NewTag)+" active=1 AND delted IS null"
obmeg.sqlexecute(c_sql,'record')
*c_sql="SELECT * FROM tblspec_ins WITH (INDEX (ix_tblspec_ins_1)) WHERE cl_code='&pc_clcode.' AND tag="+STR( m.ln_NewTag)+" active=1 AND delted IS null"
c_sql="SELECT * FROM tblspec_ins WHERE cl_code='&pc_clcode.' AND tag="+STR( m.ln_NewTag)+" active=1 AND delted IS null"
obmeg.sqlexecute(c_sql,'spec_ins')

*--1st check if a text file already exists for the case
m.lc_Rtsnum = pc_lrsno
*m.lc_Rtsnum = ALLTRIM( STR( pn_lrsno))

***********************************  test settings  ***************************************
*--f_batesTXT = "C:\BATES\textfile\"
*--m.lc_Rtsnum = '22222'
***********************************  test settings end  ***********************************
DO CASE
	*--8/02/06  KDL: added Motley litigation combos
   CASE pc_litcode = "MTL"                      && Remicade
      	l_Setdef = .T.
      	c_UniqMod = "N"
      	lc_BateNum = '0001'
      	l_SetBtnum = .T.
      	ln_bateLen = 4
    	m.lc_Filetxt = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "MOTLEY\" ;
       		+ lc_Rtsnum + ".txt")
    	m.lc_FileSav = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "MOTLEY\" ;
         	+ lc_Rtsnum + ".sav")
   CASE pc_litcode = "RMD"                      && Remicade
      l_Setdef = .T.
      c_UniqMod = "N"
      lc_BateNum = '0001'
      l_SetBtnum = .T.
      ln_bateLen = 4
      *--09/15/04 kdl start: case number is no longer used, drop motley area
      *-- code breakout
      m.lc_Filetxt = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "REMIC\" ;
         + lc_Rtsnum + ".txt")
      m.lc_FileSav = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "REMIC\" ;
         + lc_Rtsnum + ".sav")
      l_Contnum = .F.
      l_uniqtag = .F.

   CASE pc_litcode = "SRZ"                      && Serzone
      m.lc_Filetxt = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "SERZONE\" ;
         + lc_Rtsnum + ".txt")
      m.lc_FileSav = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "SERZONE\" ;
         + lc_Rtsnum + ".sav")
      l_Setdef = .T.
      c_UniqMod = "("

   CASE pc_litcode = "2  "                      && Rezulin
      m.lc_Filetxt = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "REZULIN\" ;
         + lc_Rtsnum + ".txt")
      m.lc_FileSav = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "REZULIN\" ;
         + lc_Rtsnum + ".sav")
      l_Setdef = .T.
      c_UniqMod = "N"
      m.lc_BateNum = '00001'
      l_Addbenab = .T.
      l_Supplm = .T.

   CASE INLIST( pc_litcode, "5  ", "52 ", "51 ")&& PPA
      m.lc_Filetxt = UPPER( ALLTRIM( f_batestxt) + lc_Rtsnum + ".txt")
      m.lc_FileSav = UPPER( ALLTRIM( f_batestxt) + lc_Rtsnum + ".sav")

   CASE pc_litcode = "HRT" AND pc_area = "Keeley"
      m.lc_Filetxt = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "HRTKEELY\" ;
         + lc_Rtsnum + ".txt")
      m.lc_FileSav = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "HRTKEELY\" ;
         + lc_Rtsnum + ".sav")

   CASE pc_litcode = "HRT" AND pc_area = "Morgan"
      *--11/30/04 kdl start: set to true for continuous numbering through case
      *--   l_Cnoshow = .F.
      l_Cnoshow = .T.
      l_Setdef = .T.
      c_TxtType = "N_1LINE"
      m.lc_Filetxt = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "HRTMORGN\" ;
         + lc_Rtsnum + ".txt")
      m.lc_FileSav = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "HRTMORGN\" ;
         + lc_Rtsnum + ".sav")

      *--3/20/06 kdl start: added ZPX
		*--06/06/06 kdl start: human tissue
   CASE INLIST(pc_litcode,"VIX","ZPX","HTS" )AND pc_area = "Motley" && Vioxx / Motley
      l_Setdef = .T.
      c_UniqMod = "N"
      lc_BateNum = '0001'
      l_SetBtnum = .T.
      ln_bateLen = 4
		DO CASE
			CASE pc_litcode = "VIX"
				m.lc_Filetxt = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "VIXMOTLY\" ;
      		   + lc_Rtsnum + ".txt")
      		m.lc_FileSav = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "VIXMOTLY\" ;
      		   + lc_Rtsnum + ".sav")
         CASE pc_litcode = "ZPX"
            m.lc_Filetxt = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "ZPXMOTLY\" ;
               + lc_Rtsnum + ".txt")
            m.lc_FileSav = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "ZPXMOTLY\" ;
               + lc_Rtsnum + ".sav")
         CASE pc_litcode = "HTS"
            m.lc_Filetxt = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "HTSMOTLY\" ;
               + lc_Rtsnum + ".txt")
            m.lc_FileSav = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "HTSMOTLY\" ;
               + lc_Rtsnum + ".sav")
		ENDCASE
      l_Cnoshow = .T.
      l_uniqtag = .F.

   CASE pc_litcode = "ENB" AND pc_area = "Motley" && Enbrel / Motley
      l_Setdef = .T.
      c_UniqMod = "N"
      lc_BateNum = '0001'
      l_SetBtnum = .F.
      ln_bateLen = 4
      m.lc_Filetxt = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "ENBMOTLY\" ;
         + lc_Rtsnum + ".txt")
      m.lc_FileSav = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "ENBMOTLY\" ;
         + lc_Rtsnum + ".sav")
      l_Cnoshow = .T.
      l_uniqtag = .F.

      * 02/03/06 DMA Add Bextra/Motley
   CASE pc_litcode = "BXA" AND pc_area = "Motley" && Bextra / Motley
      l_Setdef = .T.
      c_UniqMod = "N"
      lc_BateNum = '0001'
      l_SetBtnum = .T.
      ln_bateLen = 4
      m.lc_Filetxt = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "BXAMOTLY\" ;
         + lc_Rtsnum + ".txt")
      m.lc_FileSav = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "BXAMOTLY\" ;
         + lc_Rtsnum + ".sav")
      l_Cnoshow = .T.
      l_uniqtag = .F.

      *--6/30/05 kdl start: Add hrt cohen
   CASE pc_litcode = "HRT" AND pc_area = "Cohen"
      l_Cnoshow = .F.
      l_Setdef = .T.
      c_TxtType = "N_1LINE"
      m.lc_Filetxt = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "HRTCOHEN\" ;
         + lc_Rtsnum + ".txt")
      m.lc_FileSav = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "HRTCOHEN\" ;
         + lc_Rtsnum + ".sav")

      *--9/07/05 kdl start:  Add vioxx Motley-Co-Cns
      *--10/4/05 kdl start: add celebrex and bextra Motley-Co-Cns
      *--10/31/05 kdl start: added GUI
   CASE INLIST( pc_litcode, "VIX", "CLX", "BXA", "GUI") ;
         AND pc_area = "Motley-Co-Cnsl"         && Vioxx / Motley Co Cnsl
      l_Setdef = .T.
      c_UniqMod = "N"
      lc_BateNum = '0001'
      l_SetBtnum = .T.
      ln_bateLen = 4
      DO CASE
         CASE pc_litcode = "VIX"
            m.lc_Filetxt = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "VIXMOTCC\" ;
               + lc_Rtsnum + ".txt")
            m.lc_FileSav = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "VIXMOTCC\" ;
               + lc_Rtsnum + ".sav")
         CASE pc_litcode = "CLX"
            m.lc_Filetxt = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "CLXMOTCC\" ;
               + lc_Rtsnum + ".txt")
            m.lc_FileSav = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "CLXMOTCC\" ;
               + lc_Rtsnum + ".sav")
         CASE pc_litcode = "BXA"
            m.lc_Filetxt = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "BXAMOTCC\" ;
               + lc_Rtsnum + ".txt")
            m.lc_FileSav = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "BXAMOTCC\" ;
               + lc_Rtsnum + ".sav")
         CASE pc_litcode = "GUI"
            m.lc_Filetxt = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "GUIMOTCC\" ;
               + lc_Rtsnum + ".txt")
            m.lc_FileSav = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "GUIMOTCC\" ;
               + lc_Rtsnum + ".sav")
      ENDCASE
      l_Cnoshow = .T.
      l_uniqtag = .F.
	*--03/02/06 kdl start: added litigation/area  Civil lit - Area Egerton
	CASE pc_litcode="C  " AND pc_area = "Egerton"      				           	 && Civil LitEvra / Egerton
      l_Setdef = .T.
      c_UniqMod = "N"
		lc_BateNum = '0001'
		l_SetBtnum = .T.
		ln_bateLen = 4
		m.lc_Filetxt = UPPER(LEFT(ALLT(f_batestxt),9) + "CEGERTON\" ;
    			+ lc_Rtsnum + ".txt")
  		m.lc_FileSav = UPPER(LEFT(ALLT(f_batestxt),9) + "CEGERTON\" ;
     			+ lc_Rtsnum + ".sav")
		l_Cnoshow = .T.
		l_uniqtag = .F.
   CASE pc_litcode = "IRG" AND pc_area <> "Minnesota" && Standard Intergel
      l_Setdef = .T.
      c_UniqMod = "N"
      lc_BateNum = '0001'
      l_SetBtnum = .T.
      ln_bateLen = 4
      m.lc_Filetxt = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "INTERGEL\" ;
         + lc_Rtsnum + ".txt")
      m.lc_FileSav = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "INTERGEL\" ;
         + lc_Rtsnum + ".sav")
      l_Cnoshow = .T.
      l_uniqtag = .F.

      * 02/06/06 DMA Minnesota Intergel
   CASE pc_litcode = "IRG" AND pc_area = "Minnesota" && Minnesota Intergel
      l_Setdef = .T.
      c_UniqMod = "N"
      lc_BateNum = '000001'
      l_SetBtnum = .T.
      ln_bateLen = 6
      m.lc_Filetxt = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "INTRGLMN\" ;
         + lc_Rtsnum + ".txt")
      m.lc_FileSav = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "INTRGLMN\" ;
         + lc_Rtsnum + ".sav")
      l_Cnoshow = .T.
      l_uniqtag = .F.

   CASE pc_litcode = "C " AND pc_area = "Chambliss" && Civil/Chambliss
      l_Setdef = .T.
      c_UniqMod = "N"
      lc_BateNum = '0001'
      l_SetBtnum = .T.
      ln_bateLen = 4
      m.lc_Filetxt = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "CIVILCHB\" ;
         + lc_Rtsnum + ".txt")
      m.lc_FileSav = UPPER( LEFT( ALLTRIM( f_batestxt), 9) + "CIVILCHB\" ;
         + lc_Rtsnum + ".sav")
      l_Cnoshow = .T.
      l_uniqtag = .F.

   OTHERWISE
      = lp_message("Case's litigation type not supported by this function.")
*--      = gfunuse("record", ll_Recused)
      SELECT (n_CurArea)
      SET EXACT &c_Exact
      RETURN
ENDCASE

*--5/11/04 kdl start:
SET DECIMALS TO 0

m.ll_Exists = FILE(lc_Filetxt)
*-- Don't allow access if there is already a user in the file. This is neccesary to prevent
*-- overwriting individual changes.
m.ll_FileSav = FILE(lc_FileSav)
IF m.ll_FileSav
   =lp_message('Case file not available at this time.  Please try again later.')
ELSE
   * DMA 10/14/03 Issue re-opening warning for a closed case.
   IF NOT EMPTY(pd_closing)
      DO gfReopen WITH .F., "Changing Bates-label information "
   ENDIF
   IF ll_Exists
      COPY FILE (m.lc_Filetxt) TO (m.lc_FileSav)
      DO READ_text
      IF  la_Tags[1,1] = 'NONE'
         *--the following set status of screen gets enable property
         STORE .T. TO m.ll_CaEnab, m.ll_BaEnab, m.ll_pgEnab
      ELSE
         STORE .F. TO m.ll_CaEnab, m.ll_BaEnab, m.ll_pgEnab
      ENDIF
      IF m.ln_Fhndle > 0
         IF EMPTY( lc_CaseTxt)
            lc_CaseTxt = lfbatdef( lc_CaseTxt, "CASE")
         ENDIF
         IF c_TxtType = "C_2LINE"
            DO batestxt.spr
         ELSE
            *--initialize field access variable
            l_EditCase = IIF( la_Tags[1,1] = 'NONE', .T. , .F. )
            lc_BateNm2 = IIF( l_Contnum OR l_Cnoshow, lc_BateNum, "N/A")
            *--kdl out 10/15/04: lc_BateNm2 = IIF( l_Contnum, lc_BateNum, "N/A")
            DO batesn1l.spr
         ENDIF
      ENDIF
      ERASE (m.lc_FileSav)
   ELSE
      STORE .T. TO m.ll_CaEnab, m.ll_BaEnab, m.ll_pgEnab
      m.lc_CaseTxt = lfbatdef( lc_CaseTxt, "CASE")
      IF c_TxtType = "C_2LINE"
         DO batestxt.spr
      ELSE
         l_EditCase = IIF( la_Tags[1,1] = 'NONE', .T. , .F. )
         lc_BateNm2 = IIF( l_Contnum OR l_Cnoshow, lc_BateNum, "N/A")
         DO batesn1l.spr
      ENDIF
   ENDIF
ENDIF

*--clean up and exit
SET DECIMALS TO (n_Decimals)
*!*	SET ORDER TO (m.lc_CurOrd) IN RECORD
*!*	=gfunuse("record",m.ll_Recused)
WAIT CLEAR 
SELECT (n_CurArea)
SET EXACT &c_Exact
RETURN

****************************************************************************
* PROCEDURE READ_TEXT
* Abstract: if the text file exists, opens it and extracts existing data into
* variables and arrays for display in the batestxt screen
****************************************************************************
PROCEDURE READ_text
*--always reset the arrays
DIMENSION la_Tagtxt[1]
DIMENSION la_Tags[1]
DIMENSION la_Tags[1, 14]
la_Tags[1,1] = 'NONE'
la_Tagtxt[1] = 'NONE'

m.ln_Fhndle = FOPEN(lc_Filetxt)
IF m.ln_Fhndle > 0
   m.ln_counter = 1
   m.ln_TagCnt = 1
   DO WHILE NOT FEOF(ln_Fhndle)
      lc_CurTxt = FGETS(ln_Fhndle)
      DO CASE
         CASE ln_counter = 1                    && Case bates text
            m.lc_CaseTxt = lc_CurTxt
         CASE ln_counter = 2                    && Starting bates number for next script run
            m.lc_BateNum = lc_CurTxt
            m.ln_BateLen = LEN( ALLTRIM( lc_CurTxt))
         CASE ln_counter = 3                    && Date stamp for last action on text file
            m.lc_TimeStp = lc_CurTxt
         CASE ln_counter = 4                    && This is the number of the page to start bates stamping on
            m.lc_Startpge = lc_CurTxt
         CASE ln_counter > 4 AND LEN( lc_CurTxt) >= 3 && rest of file is tag data
            IF ln_TagCnt > 1
               DIMEN la_Tags[ln_TagCnt, 14]
               DIMEN la_Tagtxt[ln_TagCnt]
            ENDIF
            *--this is the lookup array for existing tags
            la_Tags[ln_TagCnt,1] = LEFT( lc_CurTxt, 3) && user will get  an err msg if they try to enter an exist tag number

            * use longer description for 1 line text bates
            la_Tags[ln_TagCnt,2] = SUBSTR( lc_CurTxt, 6, ;
               IIF( c_TxtType = "C_2LINE",26,55)) && tag's description

            la_Tags[ln_TagCnt,3] = SUBSTR( lc_CurTxt, 61, 10) && starting number for tag
            la_Tags[ln_TagCnt,4] = SUBSTR( lc_CurTxt, 71, 10) && ending number for the tag

            la_Tags[ln_TagCnt,5] = SUBSTR( lc_CurTxt, 83, 10) && time stamp
            la_Tags[ln_TagCnt,5] = IIF( ALLTRIM( la_Tags[ln_TagCnt,5]) == '', ;
               '  /  /    ' , la_Tags[ln_TagCnt,5] )
            * trap for truncated date strings. Format is not important.
            IF LEN( la_Tags[ln_TagCnt,5]) < 10
               la_Tags[ln_TagCnt,5] = PADR( la_Tags[ln_TagCnt,5], 10)
            ENDIF
            IF LEN( lc_CurTxt) >= 107
               la_Tags[ln_TagCnt,6] = SUBSTR( lc_CurTxt, 107, 1) && script run counter
               IF EMPTY( la_Tags[ln_TagCnt,6])
                  la_Tags[ln_TagCnt,6] = '0'
               ENDIF
            ELSE
               la_Tags[ln_TagCnt,6] = '0'
            ENDIF

            IF LEN( lc_CurTxt) >= 110
               la_Tags[ln_TagCnt,7] = SUBSTR( lc_CurTxt, 110, 1) && label run counter
               IF EMPTY( la_Tags[ln_TagCnt,7])
                  la_Tags[ln_TagCnt,7] = '0'
               ENDIF
            ELSE
               la_Tags[ln_TagCnt,7] = '0'
            ENDIF
            IF LEN( lc_CurTxt) >= 113
               la_Tags[ln_TagCnt,8] = SUBSTR( lc_CurTxt, 113, 25) && user id
               la_Tags[ln_TagCnt,9] = SUBSTR( lc_CurTxt, 138, 10) && edit date
            ELSE
               la_Tags[ln_TagCnt,8] = SPACE(25)
               la_Tags[ln_TagCnt,9] = SPACE(10)
            ENDIF

            *--capture the segment that stores time and associated spacers
            IF LEN( lc_CurTxt) >= 95
               la_Tags[ln_TagCnt,10] = SUBSTR( lc_CurTxt, 95, 12) && date/time stamp
            ELSE
               la_Tags[ln_TagCnt,10] = SPACE(12)
            ENDIF

            *--6/10/03 kdl start: add the linked tag number (if there is one),
            *-- and flags for plaintiff fact sheet (F) and
            *-- records produced by plaintiff counsel (P)
            *--linked tag
            IF LEN( lc_CurTxt) >= 150
               la_Tags[ln_TagCnt,11] = SUBSTR( lc_CurTxt, 150, 3) && linked tag
            ELSE
               la_Tags[ln_TagCnt,11] = ''
            ENDIF
            *--plaintiff fact sheet
            IF LEN( lc_CurTxt) >= 154
               la_Tags[ln_TagCnt,12] = SUBSTR( lc_CurTxt, 154, 1) && fact sheet indicator
            ELSE
               la_Tags[ln_TagCnt,12] = 'N'
            ENDIF
            *--plainiff counsel materials
            IF LEN( lc_CurTxt) >= 156
               la_Tags[ln_TagCnt,13] = SUBSTR( lc_CurTxt, 156, 1) && plaintiff counsel materials
            ELSE
               la_Tags[ln_TagCnt,13] = 'N'
            ENDIF
            *--Fact sheet bates starting page
            IF LEN( lc_CurTxt) >= 158
               la_Tags[ln_TagCnt,14] = SUBSTR( lc_CurTxt, 158, 3) && fact sheet starting page
            ELSE
               la_Tags[ln_TagCnt,14] = '000'
            ENDIF

            *--this is the display string for the user screen
            la_Tagtxt[ln_tagCnt] = lfScrRow(ln_tagCnt)

            ln_TagCnt = ln_TagCnt + 1
      ENDCASE
      ln_counter = ln_counter + 1
   ENDDO
   =FCLOSE(ln_Fhndle)
   *--sort the arrays based on the tag numbers for display
   =ASORT(la_Tagtxt,1)
   =ASORT(la_Tags,1)

ELSE
   =lp_message('ERROR: Could not open text file.  Contact IT department.')   
RETURN
ENDIF
RETURN

****************************************************************************
*  PROCEDURE SAVEIT
*  Abstract: Called by exit button on batestxt screen.  Screen exit procedure
****************************************************************************
PROCEDURE saveit
*--create the text file if file did not previously exist
*--5/28/04 kdl start: reset case starting number to screen value if using temp
*-- variable
*--10/15/04 kdl start:
IF l_Contnum OR l_Cnoshow
   lc_BateNum = lc_BateNm2
ENDIF

IF NOT m.ll_Exists
   * 10/14/03 DMA Auto-open a closed case when change is made
   IF NOT EMPTY(pd_closing)
      WAIT WINDOW "NOTE: Case is being automatically re-opened." NOWAIT NOCLEAR 
      DO gfReOpen WITH .T., "changing Bates-label information."
   ENDIF
   m.lc_TimeStp = PADR( (DTOC(DATE())+' '+TIME()),20)
   m.ln_Fhndle = FCREATE(lc_Filetxt)
   IF m.ln_Fhndle > 0
      =FPUT( ln_Fhndle, m.lc_CaseTxt)
      =FPUT( ln_Fhndle, m.lc_BateNum)
      =FPUT( ln_Fhndle, m.lc_TimeStp)
      =FPUT( ln_Fhndle, m.lc_Startpge)
      =FPUT( ln_Fhndle, " ")
   ENDIF
   =FCLOSE(ln_Fhndle)
ELSE
   *--update header data if there are no tags
   IF la_Tags[1,1] = "NONE"
      * 10/14/03 DMA Auto-open a closed case when change is made
      IF NOT EMPTY(pd_closing)
         WAIT WINDOW "NOTE: Case is being automatically re-opened." NOWAIT NOCLEAR 
         DO gfReOpen WITH .T., "changing Bates-label information."
      ENDIF

      DO COPY_TXT WITH 'SAVEIT'
   ENDIF
ENDIF

POP KEY ALL
KEYBOARD "{CTRL+w}"
WAIT CLEAR
****************************************************************************
*  PROCEDURE DELTAG
*  Abstract: Called by DEL TAG button on batestxt screen.  Deletes selected tag
****************************************************************************
PROCEDURE deltag
PRIVATE lc_DelTag

IF n_whichtag >= 1
   IF pl_Admin
      *   IF gfAccess(pc_UserID, "Admin")
      IF CTOD(la_Tags[n_whichtag, 5]) > { /  /    }
         *--can't delete if already run
         =lp_message('ERROR: Can not delete a tag that has been used.')
         RETURN
      ELSE
         m.deltag = ALLTRIM( la_Tags[n_whichtag,1])
         IF lf_yesno('   Delete tag ' + m.deltag + '?')
            * 10/14/03 DMA Auto-open a closed case when change is made
            IF NOT EMPTY(pd_closing)
               WAIT WINDOW "NOTE: Case is being automatically re-opened." NOWAIT NOCLEAR 
               DO gfReOpen WITH .T., "deleting Bates-label information."
            ENDIF
            DO COPY_TXT WITH 'DELETE'
            *--update the screen dispaly (need to get any recent sript run)
            DO READ_text
         ENDIF                                  &&files openned
      ENDIF                                     &&confirm
   ENDIF                                        &&Not used yet
ELSE
   =lp_message('ERROR: You must be an administrator to delete tags.')
ENDIF
WAIT CLEAR
RETURN

****************************************************************************
*  PROCEDURE EDITTAG
*  Abstract: Called by Edit Tag button on batestxt screen.  Edits selected Tag
*****************************************************************************
PROCEDURE edittag
PARAMETER ll_AddTag
*--If 2 line, can not add tag untill case txt has been added
*--m.ll_Addtag is .T. for add tag mode, .F. fo edit mode
IF CTOD(la_Tags[n_whichtag, 5]) > { /  /    }
   *--can't delete if already run
   =lp_message('ERROR: Can not edit a tag that has been used.')
RETURN
ELSE
   m.ll_AddTag = .F.
   m.ln_NewTag = VAL( la_Tags[n_whichtag, 1])
   * 05/13/03 DMA Use global variable for TAMaster value

   IF RECCOUNT('record')>0
*--   IF SEEK( pc_clcode + "*" + STR( m.ln_NewTag), "Record")
      *   IF SEEK( tamaster.cl_code+'*'+STR( m.ln_NewTag), 'Record')
      m.lc_desc = Record.Descript
   ENDIF

   m.lc_TagTxt = la_Tags[n_whichtag, 2]

   *--5/11/04 kdl start: allow edit of starting number if script has not been run
   l_Setstart = l_SetBtnum AND (la_Tags[n_whichtag, 6] = "0") AND ;
      (la_Tags[n_whichtag, 7] = "0")

   *--5/27/04 kdl start: strip out tag portion of number if it includes case number also
   IF l_Contnum AND l_Setstart
      n_tagstnum = VAL( SUBSTR( la_Tags[n_whichtag, 3], 1, 4))
   ELSE
      n_tagstnum = IIF( l_Setstart, VAL( la_Tags[n_whichtag, 3]), 0)
   ENDIF
   *--5/27/04 kdl end:

   c_Supplto  = la_Tags[n_whichtag, 11]
   c_factsht = la_Tags[n_whichtag, 12]
   c_Plaint  = la_Tags[n_whichtag, 13]
   n_FstrtPg = VAL( la_Tags[n_whichtag, 14])

   IF  NOT ALLTRIM( lc_CaseTxt)==''
      DO addbtxt.spr WITH "EDIT"
   ENDIF
ENDIF

****************************************************************************
*  PROCEDURE ADDTAG
*  Abstract: Called by add Tag button on batestxt screen.  Adds new Tag
*****************************************************************************
PROCEDURE addtag
PARAMETER ll_AddTag
*--can not add tag until case txt has been added
*--m.ll_Addtag is .T. for add tag mode, .F. fo edit mode

m.ln_NewTag = 000
m.lc_desc = ""
m.lc_TagTxt = ""
n_FstrtPg = 000
c_factsht = ""
c_Plaint  =  ""
c_Supplto = ""
n_FstrtPg = 0
n_tagstnum = IIF( l_SetBtnum, 1, 0)

*--5/11/04 kdl start: pass add starting number control variable
l_Setstart = l_SetBtnum

IF  NOT ALLTRIM( lc_CaseTxt)==''
   DO addbtxt.spr WITH "ADD"
ELSE
   IF c_TxtType = "C_2LINE"
      =lp_message('Error: Can not add tag until First text line is entered.')
   ELSE
      =lp_message('Error: Can not add tag until Case text is entered.')
   ENDIF
ENDIF

****************************************************************************
*  PROCEDURE SAVE_TAG
*  Abstract: Called by Save button on addbtxt screen.  Saves new tag to text file
*  and updates display
*****************************************************************************
PROCEDURE save_tag
*--check if the tag description is already in use.
*-- for a different tag
*--check that the combined length of the case and tag descriptions are less
*-- than 19e

n_Elem = ASCAN(la_Tags,ALLTRIM( lc_TagTxt))
IF n_Elem > 0 AND ;
      ALLTRIM( la_Tags(n_Elem)) == ALLTRIM( lc_TagTxt) AND ;
      la_Tags(n_Elem-1) <> PADL( ALLTRIM( STR( m.ln_NewTag)),3,'0') AND ;
      gfNo_Yes("Bates tag description already in use. Cancel?", "Y")
   lc_TagTxt = ""
RETURN
ENDIF

* 10/14/03 DMA Auto-open a closed case when change is made
IF NOT EMPTY(pd_closing)
   WAIT WINDOW "NOTE: Case is being automatically re-opened." NOWAIT NOCLEAR  
   DO gfReOpen WITH .T., "changing Bates-label information."
ENDIF
IF m.ll_AddTag
   IF NOT la_Tags[1,1] = "NONE"
      ln_TagCnt=ALEN( la_Tags,1) + 1
      DIMENSION la_Tags[ln_TagCnt,14], la_Tagtxt[ln_TagCnt]
   ELSE
      ln_TagCnt = 1
   ENDIF

   la_Tags[ln_TagCnt,1] = PADL( ALLTRIM( STR( m.ln_NewTag)), 3, '0')
   *--vary length of saved description
   la_Tags[ln_TagCnt,2] = PADR( ALLTRIM( lc_TagTxt), ;
      IIF( c_TxtType = "C_2LINE", 26, 55))

   *-- show user entered starting number
   la_Tags[ln_TagCnt,3] = IIF( n_tagstnum > 0, ;
      PADR( PADL( ALLTRIM( STR( n_tagstnum)), ln_bateLen, '0'), 10), SPACE(10))

   la_Tags[ln_TagCnt,4] = SPACE(10)

   la_Tags[ln_TagCnt,5] = '  /  /    '
   la_Tags[ln_TagCnt,6] = '0'
   la_Tags[ln_TagCnt,7] = '0'
   la_Tags[ln_TagCnt,8] = PADR( ALLTRIM( pc_UserID),25)
   la_Tags[ln_TagCnt,9] = DTOC(DATE())
   la_Tags[ln_TagCnt,10] = SPACE(12)

   la_Tags[ln_TagCnt,11] = c_Supplto
   la_Tags[ln_TagCnt,12] = c_factsht
   la_Tags[ln_TagCnt,13] = c_plaint
   la_Tags[ln_TagCnt,14] = PADL( ALLTRIM( STR( n_FstrtPg)), 3, '0')

   *--screen display row
   la_Tagtxt[ln_tagCnt] = lfScrRow(ln_tagCnt)

   *--format new tag's text line (for insertion into the text file)
   lc_NewTag = lfCurRow(ln_TagCnt)
ELSE
   *--5/11/04 kdl start: Add else condition to set the starting number for tags
   IF n_tagstnum > 0
      IF l_contnum
         la_Tags[n_whichtag,3] = lfconnum( n_tagstnum, la_Tags[n_whichtag,3])
      ELSE
         la_Tags[n_whichtag,3] = PADR( PADL( ALLTRIM( STR( n_tagstnum)), ln_bateLen, '0'), 10)
      ENDIF

      la_Tags[n_whichtag,4] = SPACE(10)
   ENDIF
   *-5/11/04 kdl end:
ENDIF

IF ll_Exists
   DO COPY_TXT WITH 'ADDEDIT'
ELSE                                            &&new file
   *--create the text file
   m.ln_Fhndle = FCREATE(lc_Filetxt)
   m.lc_TimeStp = DTOC(DATE())+' '+TIME()
   IF m.ln_Fhndle > 0
      =FPUT( ln_Fhndle, m.lc_CaseTxt)
      =FPUT( ln_Fhndle, m.lc_BateNum)
      =FPUT( ln_Fhndle, m.lc_TimeStp)
      =FPUT( ln_Fhndle, m.lc_Startpge)
      =FPUT( ln_Fhndle, lc_NewTag)
      =FPUT( ln_Fhndle, " ")
   ENDIF
   =FCLOSE(ln_Fhndle)
   m.ll_Exists = .T.
ENDIF
WAIT CLEAR
RETURN

****************************************************************************
*  PROCEDURE COPY_TXT
*  Abstract: Called by Save button on addbtxt screen.  Saves new tag to text file
*  and updates display
*****************************************************************************
PROCEDURE COPY_TXT
PARAMETER lc_CpyType

IF FILE(lc_Filetmp)
   ERASE (lc_Filetmp)
ENDIF

m.ln_Fhndle = FOPEN(lc_Filetxt)
m.ln_Fhtemp = FCREATE(lc_Filetmp)
IF m.ln_Fhndle > 0 AND m.ln_Fhtemp > 0
   *--use counter to accomodate text file types
   *--ln_counter = IIF( c_TxtType = "C_2LINE", 1, 3)
   ln_counter = 1
   m.ln_TagCnt = 1
   DO WHILE NOT FEOF(m.ln_Fhndle)
      lc_CurTxt = FGETS(ln_Fhndle)

      DO CASE
         CASE ln_counter = 1                    && Case bates text
            IF ALLTRIM( m.lc_CurTxt) == ALLTRIM( m.lc_CaseTxt)
               =FPUT( ln_FHtemp, m.lc_CurTxt)
            ELSE
               =FPUT( ln_FHtemp, m.lc_CaseTxt)
            ENDIF
         CASE ln_counter = 2                    && Starting bates number for next script run
            IF ALLTRIM( m.lc_CurTxt) == ALLTRIM( m.lc_BateNum)
               =FPUT( ln_FHtemp, m.lc_CurTxt)
            ELSE
               =FPUT( ln_FHtemp, m.lc_BateNum)
            ENDIF
         CASE ln_counter = 3                    && Date stamp for last action on text file
            IF NOT (ALLTRIM( m.lc_CurTxt) == '' OR INLIST( m.lc_CpyType,"PRINTLBL","SAVEIT"))
               =FPUT( ln_FHtemp, m.lc_CurTxt)
            ELSE
               =FPUT( ln_FHtemp, m.lc_TimeStp)
            ENDIF
         CASE ln_counter = 4                    && This is the number of the page to start bates stamping on
            IF ALLTRIM( m.lc_CurTxt) == ALLTRIM( m.lc_Startpge)
               *--kdl out 8/13:            IF NOT ALLTRIM( m.lc_CurTxt) == ''
               =FPUT( ln_FHtemp, m.lc_CurTxt)
            ELSE
               =FPUT( ln_FHtemp, m.lc_Startpge)
            ENDIF
         CASE ln_counter > 4 AND LEN( lc_CurTxt)>=3 && rest of file is tag data

            DO CASE
               CASE m.lc_CpyType = 'ADDEDIT' AND NOT m.ll_AddTag
                  IF (NOT LEFT( m.lc_CurTxt,3)  == la_Tags[n_whichtag,1]) ;
                        OR (CTOD( SUBSTR( lc_CurTxt, 83, 10)) > { /  /    })
                     *--put in the original line if tag has now been used
                     =FPUT( ln_FHtemp, m.lc_CurTxt)
                  ELSE
                     *--put in the edited line
                     la_Tags[m.n_whichtag,2] = PADR( ALLTRIM( lc_TagTxt), ;
                        IIF( c_TxtType = "C_2LINE", 26, 55)) && tag's description

                     *-- add the user id and date to the text file when the tag line is edited or added
                     la_Tags[n_whichtag,8] = PADR( ALLTRIM( pc_UserID), 25)
                     la_Tags[n_whichtag,9] = DTOC(DATE())

                     *--6/11/03 kdl start: add values for new file columns
                     la_Tags[n_whichtag,11] = c_Supplto
                     la_Tags[n_whichtag,12] = c_Factsht
                     la_Tags[n_whichtag,13] = c_Plaint
                     la_Tags[n_whichtag,14] = PADL( ALLTRIM(  STR( n_FstrtPg)), 3, '0')
                     *--6/11/03 kdl end:

                     *--this line goes in the text file
                     m.lc_CurTxt = lfCurRow(n_whichtag)

                     *--this line is only displayed on the screen
                     la_Tagtxt[n_whichtag] = lfScrRow(n_whichtag)

                     =FPUT( ln_FHtemp, m.lc_CurTxt)
                  ENDIF
               CASE m.lc_CpyType = "DELETE"
                  *--will skip the put for the deleted tag
                  IF (NOT LEFT( lc_CurTxt,3) == m.deltag) OR ;
                        (CTOD(SUBSTR( lc_CurTxt,83,10)) > { /  /    })
                     *--don't delete if tag has now been used
                     =FPUT( ln_FHtemp, m.lc_CurTxt)
                  ENDIF
                  *--print label addition
               CASE m.lc_CpyType = "PRINTLBL"
                  *--put in the edited line
                  IF LEFT( lc_CurTxt,3) == la_Tags[n_whichtag,1]
                     *--this is the display text
                     la_Tagtxt[n_whichtag] = lfScrRow(n_whichtag)
                     *--this is the text for the file

                     m.lc_CurTxt = lfCurRow(n_whichtag)

                  ENDIF
                  =FPUT( ln_FHtemp, m.lc_CurTxt)
                  *--6/12/02 kdl end:
               OTHERWISE
                  =FPUT( ln_FHtemp, m.lc_CurTxt)
            ENDCASE
      ENDCASE
      ln_counter = ln_counter + 1
   ENDDO

   IF m.lc_CpyType = 'ADDEDIT' AND m.ll_AddTag
      =FPUT( ln_FHtemp, lc_NewTag)
      STORE .F. TO m.ll_BaEnab, m.ll_pgEnab
      IF NOT l_EditCase
         STORE .F. TO m.ll_CaEnab
      ENDIF
   ENDIF

   =FCLOSE(ln_Fhtemp)
   =FCLOSE(ln_Fhndle)
   COPY FILE (lc_Filetmp) TO (lc_Filetxt)
   ERASE (lc_Filetmp)
   * 10/14/03 DMA Auto-open a closed case when change is made
   IF NOT EMPTY(pd_closing)
      WAIT WINDOW "NOTE: Case is being automatically re-opened." NOWAIT NOCLEAR 
      DO gfReOpen WITH .T., "changing Bates-label information."
   ENDIF
ENDIF
WAIT CLEAR

****************************************************************************
*  PROCEDURE BATESPRINT
*  Abstract: Called by Print Lbl batestxt screen.  Generates printed bates labels
*    for selected tag and updates text file accordingly
*  Added: 6/12/02 by kdl
*****************************************************************************
PROCEDURE PRINTBATES
PRIVATE m.lc_prtstr, m.ln_CurArea, n_BateNum, c_BateNum, c_PrntStr1, ;
   n_BateNum2, c_BateNum2
*IF NOT gfaccess(pc_UserID, "UNITMGR")
IF NOT pl_UnitMgr
   = lp_message("Not authorized. Please check with your manager.")
ELSE
   PRIVATE m.lc_Lbls, m.ln_Lbls
   *--prompt user for number of labels
   SET INTENSITY ON
   IF NOT WEXIST("getnum")
      DEFINE WINDOW getnum ;
         FROM INT((SROW()-5)/2),INT((SCOL()-28)/2) ;
         TO INT((SROW()-5)/2)+4,INT((SCOL()-28)/2)+30 ;
         TITLE " Enter Number of Labels " ;
         FOOTER " Press <ENTER> " ;
         NOFLOAT ;
         NOCLOSE ;
         SHADOW ;
         NOMINIMIZE ;
         COLOR SCHEME 1
   ENDIF
   ACTIVATE WINDOW getnum
   @ 1,13 GET m.lc_Lbls ;
      PICTURE '999';
      SIZE 1,3 ;
      DEFAULT " " ;
      COLOR SCHEME 4
   READ
   RELEASE WINDOW getnum
   m.lc_Lbls = IIF( ALLTRIM( m.lc_Lbls)=='','0' , ALLTRIM( m.lc_Lbls))
   m.ln_Lbls = VAL( m.lc_Lbls)
   IF m.ln_Lbls = 0
      RETURN
   ELSE
      WAIT WINDOW "Preparing Bates Labels print file." NOWAIT NOCLEAR 
   ENDIF
   *--adjust request number to be inclusive of starting bates number
   m.ln_Lbls = m.ln_Lbls-1

   *--check type of file to determine starting number
   IF c_TxtType = "C_2LINE" OR l_Cnoshow
      *--IF c_TxtType = "C_2LINE"
      *--get the current bates starting number for the case
      n_BateNum = VAL( m.lc_BateNum)
      c_BateNum = m.lc_BateNum
      IF  l_Cnoshow
         n_BateNum2 = n_BateNum
         c_BateNum2 = c_BateNum
      ENDIF
   ELSE
      *--get the last number used for the tag and increment by 1
      *--5/11/04 kdl start: if this is for user entered tag starting numbers, use the
      *-- tag starting number unless a run has already been made ( an ending number exists)
      n_BateNum = VAL( la_Tags[n_whichtag, 4])
      n_BateNum = IIF( n_BateNum = 0, VAL( la_Tags[n_whichtag, 3]), n_BateNum + 1)
      n_BateNum = IIF( n_BateNum = 0, n_BateNum + 1, n_BateNum)
      *--kdl out 5/11/04: n_BateNum = VAL( la_Tags[n_whichtag, 4]) +  1
      c_BateNum = PADL( ALLTRIM( STR( n_BateNum)), ln_bateLen,"0")
      *--for single line with continous also
      *--10/15/04 kdl start:
      IF l_Contnum
         n_BateNum2 = VAL( m.lc_BateNum)
         c_BateNum2 = m.lc_BateNum
      ENDIF
   ENDIF

   IF sendmsg("Start New label file?", 2, .T.) = 1
      SET PRINTER TO "c:\temp\labels2.txt"
   ELSE
      SET PRINTER TO "c:\temp\labels2.txt" ADDITIVE
   ENDIF
   SET CONSOLE OFF
   SET PRINT ON
   *--5/19/03 kdl start: modify for single line Bates strings (remove the comma)
   c_PrntStr1 = IIF( c_TxtType = "C_2LINE", (ALLTRIM( m.lc_CaseTxt) + ","), ;
      ALLTRIM( m.lc_CaseTxt))
   FOR i = n_BateNum TO (n_BateNum + m.ln_Lbls)
      *--10/22/03 kdl start: adjust format of printed labels for rezulin/serzone
      DO CASE
         CASE INLIST( pc_litcode, "2  ", "SRZ")
            m.lc_prtstr = c_PrntStr1 + " " + ALLTRIM( la_Tags[n_whichtag, 2]) + ;
               " " + BatePad( n_BateNum)
         CASE pc_litcode = "RMD" AND l_Contnum  && Remicade
            m.lc_prtstr = c_PrntStr1 + ALLTRIM( la_Tags[n_whichtag, 2]) + ;
               BatePad( n_BateNum) + "," + BatePad( n_BateNum2)
         OTHERWISE
            m.lc_prtstr = c_PrntStr1 + ALLTRIM( la_Tags[n_whichtag, 2]) + BatePad( n_BateNum)
      ENDCASE
      *--kdl out 10/22/03: m.lc_prtstr = c_PrntStr1 + ALLTRIM( la_Tags[n_whichtag, 2]) + BatePad( n_BateNum)
      *--10/22/03 kdl end:
      IF i = VAL( c_BateNum)
         ?? m.lc_prtstr
      ELSE
         ? m.lc_prtstr
      ENDIF
      n_BateNum = n_BateNum + 1
      *--5/27/04 kdl start: add incrementing for 2nd tracking nuumber
      *--10/15/04 kdl start:
      IF l_Contnum  OR l_Cnoshow
         n_BateNum2 = n_BateNum2 + 1
      ENDIF
   ENDFOR
   ?
   SET PRINT OFF
   SET PRINTER TO
   SET CONSOLE ON
   *--update the displayed data
   *--5/27/04 kdl start: add fomatting for cont + tag number tracking
   IF l_contnum
      la_Tags[n_whichtag,3] = lfconnum(VAL( c_Batenum))
   ELSE
      la_Tags[n_whichtag, 3] = PADR( c_Batenum,10)
   ENDIF
   *--5/11/04 kdl start: set length based on case settings
   c_Batenum = PADL( ALLTRIM( STR( n_BateNum - 1)), ln_bateLen, "0")
   *--KDL OUT 5/11/04: c_Batenum = PADL( ALLTRIM( STR( n_BateNum-1)), 6, "0")

   *--5/27/04 kdl start: update the 2nd tracking number
   *--10/15/04 kdl start:
   IF l_Contnum OR l_Cnoshow
      c_Batenum2 = PADL( ALLTRIM( STR( n_BateNum2 - 1)), ln_bateLen, "0")
      m.ln_BateNum = n_BateNum2
      m.lc_BateNum = BatePad( m.ln_BateNum2)
      lc_BateNm2 = m.lc_BateNum
   ENDIF

   IF l_contnum
      la_Tags[n_whichtag, 4] = PADR( c_Batenum + "(" + c_Batenum2 + ")", 10)
   ELSE
      la_Tags[n_whichtag, 4] = PADR(  c_Batenum,10)
   ENDIF


   la_Tags[n_whichtag, 5] = DTOC(DATE())

   *--update the starting bates num and and time stamp variables
   IF c_TxtType = "C_2LINE"
      m.ln_BateNum = n_BateNum
      m.lc_BateNum = BatePad( m.ln_BateNum)
   ENDIF

   *--set value of time element in array.
   la_Tags[n_whichtag, 10] = PADR( TIME(),12)

   *--increment the label print counter
   la_Tags[n_whichtag,7] = ALLTRIM( STR(  (VAL( la_Tags[n_whichtag,7])+1) ))

   *--update the text file
   DO COPY_TXT WITH 'PRINTLBL'
   
   gfmessage("Labels printed to C:\Temp\Labels2.txt. Run Avery Label Printer.")
   * 10/14/03 DMA Auto-open a closed case when change is made
   IF NOT EMPTY(pd_closing)
      WAIT WINDOW "NOTE: Case is being automatically re-opened." NOWAIT NOCLEAR 
      DO gfReOpen WITH .T., "changing Bates-label information."
   ENDIF
ENDIF
WAIT CLEAR

****************************************************************************
*  PROCEDURE BatePad
*  Abstract: Pads the starting bates number
*  Added 6/12/02 by kdl
*****************************************************************************
FUNCTION BatePad
PARAMETER ln_number
PRIVATE lc_batestr
m.lc_batestr = ALLTRIM( STR( m.ln_Number))
m.lc_batestr = PADL( m.lc_batestr, m.ln_BateLen, '0')
RETURN m.lc_batestr

****************************************************************************
*  FUNCTION LFCURROW
*  Abstract: Return the current compiled text line for insertion into the
*     text file
*  Added 2/20/02 by kdl
*****************************************************************************
FUNCTION lfCurRow
PARAMETER n_ArrayRow
PRIVATE c_CurText
*--6/11/03 add new fields for mirror of tag and fact sheet and plaintiff
*-- produced documents flags
c_CurText = la_Tags[n_ArrayRow,1] + SPACE(2)+;
   la_Tags[n_ArrayRow,2] + IIF( c_TxtType = "C_2LINE", SPACE(29), "") + ;
   la_Tags[n_ArrayRow,3] + la_Tags[n_ArrayRow,4] + SPACE(2) + ;
   la_Tags[n_ArrayRow,5] + SPACE(2) + la_Tags[n_ArrayRow,10] + ;
   la_Tags[n_ArrayRow,6] + SPACE(2) + la_Tags[n_ArrayRow,7] + ;
   SPACE(2) + la_Tags[n_ArrayRow,8] + la_Tags[n_ArrayRow,9] + ;
   SPACE(2) + PADR( la_Tags[n_ArrayRow,11],3) + SPACE(1) + ;
   PADR( la_Tags[n_ArrayRow,12], 1) + SPACE(1) + ;
   PADR( la_Tags[n_ArrayRow,13], 1) + SPACE(1) + ;
   PADR( la_Tags[n_ArrayRow,14], 3)

RETURN c_CurText

****************************************************************************
*  FUNCTION LFSCRROW
*  Abstract: Return the compiled text line for screen display
*  Added 2/20/02 by kdl
*****************************************************************************
FUNCTION lfScrRow
PARAMETER n_ArrayRow
PRIVATE c_CurText
c_CurText = la_Tags[n_ArrayRow,1] + "  "+ ;
   LEFT( la_Tags[n_ArrayRow,2],26) + "  " + ;
   la_Tags[n_ArrayRow,3] + "  " + ;
   la_Tags[n_ArrayRow,4] + "  " + ;
   PADR( la_Tags[n_ArrayRow,5],10) + "  " + ;
   la_Tags[n_ArrayRow,6] + " " + ;
   la_Tags[n_ArrayRow,7]

RETURN c_CurText

****************************************************************************
*  FUNCTION LFUNIQCS
*  Abstract: Check that the case string is unique for the litigation
*  Added 5/29/03 by kdl
*  Called by: batesn1l.spr
*****************************************************************************
FUNCTION lfuniqcs
PARAMETER c_Casetxt, c_Action
PRIVATE n_CurArea, c_CurOrd, l_Usebcse, l_Result, n_cnt, c_TestStr
c_Casetxt = UPPER( LTRIM(c_Casetxt))
IF EMPTY( c_Casetxt)
   = lp_message("ERROR: Case text is required.")
	RETURN ""
ENDIF
n_CurArea = SELECT()
l_Result = .T.
*!*	l_Usebcse = gfuse("batescse")
*!*	SELECT batescse
*!*	c_CurOrd = ORDER()
*!*	SET ORDER TO lit_txt
c_TestStr = ""
n_Cnt = 2
**10/01/18 SL #109598
*c_sql-"SELECT * FROM tblbatescse WITH (INDEX (ix_tblbatescse_1)) WHERE lit_code='&pc_litcode.' AND case_text='&c_Casetxt.' AND active=1 AND delted IS null"
c_sql-"SELECT * FROM tblbatescse WHERE lit_code='&pc_litcode.' AND case_text='&c_Casetxt.' AND active=1 AND delted IS null"
obmed.sqlexecute(c_sql,'batescse')
IF RECCOUNT('batescsc')>0
*--IF SEEK( pc_litcode + c_Casetxt) AND ;
      NOT batescse.cl_code = pc_Clcode
   c_CaseTxt = ALLTRIM( c_Casetxt)
   DO WHILE .T.
      c_TestStr = c_Casetxt
      c_TestStr = LEFT( c_TestStr, 60-LEN( ALLTRIM( STR( n_Cnt))))
      IF c_UniqMod = "N"
         c_TestStr = c_TestStr + ALLTRIM( STR( n_Cnt))
      ELSE
         c_TestStr = c_TestStr + "(" + ALLTRIM( STR( n_Cnt)) + ")"
      ENDIF
      GO TOP
      	**10/01/18 SL #109598
		*c_sql-"SELECT * FROM tblbatescse WITH (INDEX (ix_tblbatescse_1)) WHERE lit_code='&pc_litcode.' AND case_text='&c_Casetxt.' AND active=1 AND delted IS null"
		c_sql-"SELECT * FROM tblbatescse WHERE lit_code='&pc_litcode.' AND case_text='&c_Casetxt.' AND active=1 AND delted IS null"
		obmed.sqlexecute(c_sql,'batescse')
      IF RECCOUNT('batescse')>0 AND ;
            NOT batescse.cl_code = pc_Clcode
         n_Cnt = n_Cnt + 1
         LOOP
      ELSE
         c_Casetxt = c_TestStr
         EXIT
      ENDIF
   ENDDO
ENDIF
DO lpAddcs WITH c_Casetxt
*--SET ORDER TO (c_CurOrd)
USE IN batescse
= gfunuse("batescse", l_Usebcse)
SELECT (n_CurArea)

RETURN c_Casetxt

****************************************************************************
*  PROCEDURE LPADDCSE
*  Abstract: Add/replace litigation case text in batescse table
*  Added 5/29/03 by kdl
*  Called by: lfuniqcs
*****************************************************************************
PROCEDURE Lpaddcs
PARAMETER c_Text
PRIVATE n_CurArea, c_CurOrd, l_Usebcse, l_Result, case_txt, add_date, ;
   add_by, lrs_no, cl_code, lit_code
*--n_CurArea = SELECT()
*--l_Usebcse = gfuse("batescse")

* 10/14/03 DMA Auto-open a closed case when change is made
IF NOT EMPTY(pd_closing)
   WAIT WINDOW "NOTE: Case is being automatically re-opened." NOWAIT NOCLEAR 
   DO gfReOpen WITH .T., "changing Bates-label information."
ENDIF

SELECT batescse
SET ORDER TO lit_cl
GO TOP


IF SEEK( pc_Litcode + pc_Clcode)
   IF NOT c_Text == ALLTRIM( batescse.case_txt)
	  c_sql="UPDATE tblbatescse SET case_txt='&c_Text.',edited='"+DTOC(d_today)+"',editby='&pc_userid.' "+;
		 " WHERE lit_code='&pc_litcode.' AND cl_code='&pc_Clcode.' AND active=1 AND delted IS null"
	  obmed.sqlexecute(c_sql)

*!*	      DO WHILE NOT RLOCK()
*!*	      ENDDO
*!*	      REPLACE batescse.case_txt WITH c_Text, ;
*!*	         batescse.edit_date WITH DATE(), ;
*!*	         batescse.edit_by WITH pc_UserId
*!*	      UNLOCK
   ENDIF
ELSE
*!*	   m.Lit_code = pc_Litcode
*!*	   m.cl_code = pc_Clcode
*!*	   m.lrs_no = pn_Lrsno
*!*	   m.Case_txt = c_Text
*!*	   m.Add_date = DATE()
*!*	   m.Add_by = pc_UserId
*!*	   INSERT INTO batescse FROM MEMVAR
	  c_sql="INSERT INTO tblbatescse "+;
	  	"(lit_code,cl_code,lrs_no,case_Txt,created,createdby,active) "  +;
	  	"VALUES "+;
	  	"("+;
	  	"'"+pc_Litcode+"'"+;
	  	",'"+pc_clcode+"'"+;
	  	","+STR(pn_lrsno)+;
	  	",'"+c_text+"'"+;
	  	",'"+DTOC(d_today)+"'"+;
	  	",'"+pc_userid+"'"+;
	  	","+'0'+;
	  	")"
	  obmed.sqlexecute(c_sql)
ENDIF
*-- =gfunuse("batescse", l_Usebcse)
*-- SELECT (n_CurArea)
WAIT CLEAR
RETURN

****************************************************************************
*  FUNCTION LFBATDEF
*  Abstract: Set default case and deponent bates strings
*  Added 6/01/03 by kdl
*  Called by: addbtxt.spr
*****************************************************************************
FUNCTION lfbatdef
PARAMETER c_Btext, c_Action
PRIVATE c_Newtxt, n_Cnt, n_pos
c_Newtxt = ""
IF l_Setdef
   *--assumes that pointer is already on correct record in Record.dbf
   IF c_Action = "TAG"
      DO CASE

         CASE pc_litcode = "SRZ"                && serzone
            *--strip out spaces and add hyphen
            c_Newtxt = UPPER( ALLTRIM( Record.Descript))
            IF LEN( c_Newtxt) > 45
               c_Newtxt = LEFT( c_Newtxt,42)+"..."
            ENDIF
            c_Newtxt = lfuniqtg(c_Newtxt, ln_Newtag)

         CASE pc_litcode = "2  "                && rezulin
            c_Newtxt = UPPER( ALLTRIM( Record.Descript))
            c_Newtxt = LFRezdef(c_Newtxt)

         CASE pc_litcode = "HRT" AND pc_area = "Morgan"
            c_Newtxt = UPPER( ALLTRIM( Record.Descript))
            IF LEN( c_Newtxt) > 45
               c_Newtxt = LEFT( c_Newtxt,42)+"..."
            ENDIF
            c_Newtxt = lfuniqtg(c_Newtxt, ln_Newtag)

            *--6/30/05 kdl start:
         CASE pc_litcode = "HRT" AND pc_area = "Cohen"
            c_Newtxt = UPPER( ALLTRIM( Record.Descript))
            IF LEN( c_Newtxt) > 45
               c_Newtxt = LEFT( c_Newtxt,42)+"..."
            ENDIF

            *--9/21/05 kdl start:
         CASE pc_litcode = "IRG" AND pc_area <> 'Minnesota' && std. intergel
            *--strip out spaces and add hyphen
            c_Newtxt = "TAG" + ALLTRIM( STR( Record.Tag)) + UPPER( ALLTRIM( Record.Descript))
            c_Newtxt= lfFtrans(c_Newtxt,"NO")
            c_Newtxt=STRTRAN( c_Newtxt,' ')
            IF LEN( c_Newtxt) > 45
               c_Newtxt = LEFT( c_Newtxt,42)+"..."
            ENDIF
            c_Newtxt = lfuniqtg(c_Newtxt, ln_Newtag)

         CASE pc_litcode = "C " AND pc_area = "Chambliss" && Civil/Chambliss
            *--strip out spaces and add hyphen
            c_Newtxt = UPPER( ALLTRIM( Record.Descript))
            c_Newtxt= lfFtrans(c_Newtxt,"NO")
            c_Newtxt=LEFT( STRTRAN( c_Newtxt,' '),20)
            c_Newtxt = lfuniqtg(c_Newtxt, ln_Newtag)
         OTHERWISE
      ENDCASE
   ELSE
      DO CASE

         CASE pc_litcode = "SRZ"                && serzone
            c_Newtxt = UPPER( pc_pllname) + "." + UPPER( pc_plfname) +;
               ":" + pc_pladdr2
            *--remove the zip code from the address string
            c_Newtxt = ALLTRIM( Lfnonum(c_Newtxt))
            *--make sure the name is unique
            c_Newtxt = lfuniqcs(c_Newtxt)

         CASE pc_litcode = "2  "                && rezulin
            c_Newtxt = UPPER( LEFT( pc_plFname, 1)) + ALLTRIM( pc_plminit) + ;
               UPPER( LEFT( pc_plLname,1))
            *--make sure the name is unique
            c_Newtxt = lfuniqcs(c_Newtxt)

         CASE pc_litcode = "RMD"                && remicade
            c_Newtxt = UPPER( LEFT( pc_plLname,4))
            *--make sure the name is unique
            c_Newtxt = lfuniqcs(c_Newtxt)

         CASE pc_litcode = "HRT" AND pc_area = "Morgan"
            c_Newtxt = UPPER( LEFT( pc_plFname, 1)) + "." + UPPER( pc_plLname)
            *--make sure the name is unique
            c_Newtxt = lfuniqcs(c_Newtxt)

            *--11/17/04 kdl start: default strings for Enbrel/Morgan and Viox/Morgan
            *--9/07/05 kdl start:  Add vioxx Motley-Co-Cnsl
            *--10/04/05 kdl start: and bextra and celebrex
            *--10/31/05 kdl start: added GUI
				*--03/02/06 kdl start: added civil lit/egerton
				*--03/20/06 kdl start: added civil zpx
				*--06/06/06 kdl start: human tissue
			 CASE (INLIST( pc_litcode, "VIX", "CLX", "BXA", "GUI", "ZPX","HTS") ;
              AND INLIST( pc_area,"Motley", "Motley-Co-Cnsl")) OR ;
				  (pc_litcode="C  " AND pc_area = "Egerton") OR ;
				  pc_litcode='MTL'

            c_Newtxt = UPPER( LEFT( pc_plFname, 1)) + ;
               IIF( NOT EMPTY( UPPER( LEFT( pc_plFname, 1))), "." , "") + ;
               UPPER( LEFT( pc_plLname,4))
            c_Newtxt = lfuniqcs(c_Newtxt)

         CASE pc_litcode = "ENB" AND pc_area = "Motley"
            c_Newtxt = UPPER( LEFT( pc_plLname,4))
            c_Newtxt = lfuniqcs(c_Newtxt)

         CASE pc_litcode = "HRT" AND pc_area = "Cohen"
            c_Newtxt = UPPER( LEFT( pc_plFname, 1)) + ;
               IIF( NOT EMPTY( UPPER( LEFT( pc_plFname, 1))), "." , "") + ;
               UPPER( ALLTRIM( pc_plLname)) + " " + ALLTRIM( STR( pn_Lrsno))
            c_Newtxt = lfuniqcs(c_Newtxt)

         CASE pc_litcode = "IRG" AND pc_area <> 'Minnesota' && Std. Intergel
            c_Newtxt = UPPER( LEFT( pc_plLname,3))
            *--make sure the name is unique
            c_Newtxt = lfuniqcs(c_Newtxt)

         CASE pc_litcode = "C " AND pc_area = "Chambliss" && Civil/Chambliss
            c_Newtxt = pc_lrsno
            *--c_Newtxt = UPPER( LEFT( pc_plLname,8))
            *--make sure the name is unique
            *--c_Newtxt = lfuniqcs(c_Newtxt)
         OTHERWISE
      ENDCASE
   ENDIF
ENDIF

RETURN c_Newtxt

****************************************************************************
*  FUNCTION LFUNIQTG
*  Abstract: Check for duplicate tag description in case. Create unique
*   description if duplicate is found
*  Added 6/01/03 by kdl
*  Called by: addbtxt.spr
*****************************************************************************
FUNCTION Lfuniqtg
PARAMETER c_String, n_TestTag
IF NOT l_uniqtag
RETURN c_String
ENDIF
PRIVATE n_LenTag, n_Elem, n_Cnt, c_TestStr
c_String = ALLTRIM( c_String)
n_LenTag = LEN( ALLTRIM( STR( n_TestTag)))
n_Elem = ASCAN(la_Tags,c_String)
IF n_Elem > 0 AND ;
      ALLTRIM( la_Tags(n_Elem)) == ALLTRIM( c_String) AND ;
      la_Tags(n_Elem-1) <> PADL( ALLTRIM( STR( m.ln_NewTag)),3,'0')
   *--if tag description already exists, for a different tag, make new descript
   *--descript unique by adding sequential number to it
   IF LEN( c_String) > 45
      c_String = LEFT( c_String, 42) + "..."
   ENDIF
   n_Cnt = 2
   DO WHILE .T.
      c_TestStr = c_String
      IF c_UniqMod = "N"
         c_TestStr = LEFT( c_TestStr, 45-LEN( ALLTRIM( STR( n_Cnt))))
         c_TestStr = c_TestStr + ALLTRIM( STR( n_Cnt))
      ELSE
         c_TestStr = LEFT( c_TestStr, 43-LEN( ALLTRIM( STR( n_Cnt))))
         c_TestStr = c_TestStr + "(" + ALLTRIM( STR( n_Cnt)) + ")"
      ENDIF
      n_Elem = ASCAN(la_Tags,c_TestStr)
      IF n_Elem > 0 AND ;
            ALLTRIM( la_Tags(n_Elem)) == ALLTRIM( c_TestStr) AND ;
            la_Tags(n_Elem-1) <> PADL( ALLTRIM(  STR( m.ln_NewTag)),3,'0')
         n_Cnt = n_Cnt + 1
         LOOP
      ELSE
         c_String = c_TestStr
         EXIT
      ENDIF
   ENDDO
ENDIF
RETURN c_String

****************************************************************************
*  FUNCTION LFTRANS
*  Abstract: Remove non-alpha characters from an expression
*  Added 6/01/03 by kdl
*  Called by: addbtxt.spr
*****************************************************************************
FUNCTION lfFtrans
PARAMETER c_String, c_action
IF PARAMETERS() < 2
   c_action = 'ALL'
ENDIF
PRIVATE n_Cnt
IF c_Action='ALL'
   n_Cnt = 1
   DIMENSION a_Trash [2]
   a_Trash[1] = "DR."
   a_Trash[2] = "DOCTOR"
   *--remove no-alpha characters, replace with no space
   FOR n_Cnt = 1 TO ALEN( a_Trash, 1)
      c_String = STRTRAN( c_String, (a_Trash[n_Cnt]))
   ENDFOR
ENDIF

*--strip out symbols from text string
DIMENSION a_Trash [10]
a_Trash[1] = "/"
a_Trash[2] = ","
a_Trash[3] = "("
a_Trash[4] = ")"
a_Trash[5] = "'"
a_Trash[6] = "-"
a_Trash[7] = "."
a_Trash[8] = ":"
a_Trash[9] = "*"
a_Trash[10] = "|"

*--remove no-alpha characters, replace with a space
FOR n_cnt = 1 TO ALEN( a_Trash, 1)
   c_String = STRTRAN( c_String, (a_Trash[n_Cnt]), " ")
ENDFOR

RETURN c_String

****************************************************************************
*  FUNCTION LFNONUM
*  Abstract: Remove numbers from an expresion
*  Added 6/01/03 by kdl
*  Called by: addbtxt.spr
*****************************************************************************
FUNCTION Lfnonum
PARAMETER c_String
PRIVATE n_cnt
*--remove numbers from the string
FOR n_cnt = 48 TO  57
   c_String = STRTRAN( c_String, CHR(n_cnt))
ENDFOR
RETURN c_String

****************************************************************************
*  FUNCTION LFREZDEF
*  Abstract: Develop defaul rezulin tag string
*  Added 6/06/03 by kdl
*  Called by:
*****************************************************************************
FUNCTION Lfrezdef
PARAMETER c_RezTxt
PRIVATE n_Cnt, n_Alen, c_RezNew, c_ChkTxt, l_Used, c_dept, n_Curarea, ;
   l_Found, l_Plink
c_RezTxt = ALLTRIM( c_RezTxt)
*--if plaintiff supplied records, check with user for specific deponent link
l_Plink = .F.                                   && records linked to specific deponent flag
IF c_Plaint = "Y"
   IF gfNo_Yes("Is this plaintiff record for a known facility?", "Y")
      l_Plink = .T.
   ENDIF
ENDIF

*--Check if this is a repeated a supplemental request.
*--is supp if field Record.supplem_tof (pn_soppto) is populated
c_Supplto = lfsuppl()
DO CASE
   CASE NOT EMPTY( c_Supplto)
      *--retrieve supplemented tag's bates description
      l_Found = .F.
      FOR ln_count = 1 TO ALEN( la_Tags,1)
         IF la_Tags[ln_count,1] = c_Supplto
            c_RezTxt = ALLTRIM( la_Tags[ln_count,2])
            l_Found = .T.
            EXIT
         ENDIF
      ENDFOR
      IF l_Found
         *--12/4/03 kdl start: prevent multiple occurences of term "SUPP"
         IF AT( " SUPP", c_RezTxt) = 0
            c_RezTxt = c_RezTxt + " SUPP"
         ENDIF
         *--kdl out 12/4/03: c_RezTxt = c_RezTxt + " SUPP"
         *--12/4/03 kdl end:
      ELSE
         = lp_message("ERROR: Supplemented tag " + c_Supplto + " not found in text file.")
         CLEAR READ
         RETURN
      ENDIF
   CASE c_factsht = "Y"
      c_RezTxt = "PLTFS"
   CASE c_Plaint = "Y" AND NOT l_Plink
      c_RezTxt = "PLT"
   OTHERWISE
      *--10/14/03 kdl start: strip off any text enclosed in parenthesis
      *--at end of deponent texe, if not hospital
      IF NOT UPPER(  LEFT( Record.mailid_no, 1)) == "H" AND ;
            RIGHT(c_RezTxt, 1) == ")"
         n_Pos = RAT( "(", c_RezTxt)
         IF n_Pos > 1
            c_RezTxt = LEFT( c_RezTxt, (n_Pos -1))
         ENDIF
      ENDIF
      *--10/14/03 kdl end:

      *--clean out unwanted text/symbols
      c_RezTxt = ALLTRIM( lFftrans(c_RezTxt))
      *--build an array of the spaces in the text string
      DIMENSION a_Spaces[1]
      a_Spaces[1] = 0
      n_Cnt = 1
      n_Pos = 1
      c_RezNew = ""
      DO WHILE n_pos > 0
         n_Pos = AT( " ", c_RezTxt, n_Cnt)
         IF n_Pos > 0
            n_cnt = n_Cnt + 1
            DIMENSION a_Spaces[n_Cnt]
            a_Spaces[n_Cnt] = n_Pos
         ENDIF
      ENDDO
      n_Alen = ALEN( a_Spaces, 1)
      IF n_Alen > 1 OR UPPER( LEFT( Record.mailid_no, 1)) = "H"
         *--now build the bates string from first letters
         pc_deptype = UPPER( LEFT( Record.mailid_no, 1))
         IF NOT INLIST( pc_deptype, "H", "E", "A", "D")
            pc_deptype = "D"
         ENDIF
         IF NOT pc_deptype = "H"
            FOR n_Cnt = 1 TO n_Alen
               c_RezNew = c_RezNew + SUBSTR( c_RezTxt, a_Spaces[n_Cnt] + 1, 1)
            ENDFOR
            c_RezTxt = STRTRAN( c_RezNew, " ")
         ELSE
            FOR n_Cnt = 1 TO (n_Alen - 1)
               c_RezNew = c_RezNew + SUBSTR( c_RezTxt, a_Spaces[n_Cnt] + 1, 1)
            ENDFOR
            c_RezNew = STRTRAN( c_RezNew, " ")
            *--now check if the last word is the hosp dept
            c_ChkTxt =  RIGHT(c_RezTxt, (LEN( c_RezTxt) - a_Spaces[n_Cnt]))
            IF INLIST( c_ChkTxt, "BILL", "ECHO", "MED", "PATH", "RAD")
               *--10/21/03 kdl start: do not include med dept in deponent string
               c_RezTxt = c_RezNew  +  ;
                  IIF( ALLTRIM( c_ChkTxt) == "MED", "", " " + c_ChkTxt )
               *--kdl out 10/21/03: c_RezTxt = c_RezNew + " " + c_ChkTxt
            ELSE
               *--get first letter of last word
               c_RezNew = c_RezNew + SUBSTR( c_RezTxt, a_Spaces[n_alen] + 1, 1)
               *--we need to get the dept from spec_ins table
               n_CurArea = SELECT()

*!*	               l_Used = gfuse("spec_ins")
*!*	               SELECT Spec_Ins
*!*	               SET ORDER TO cltag
               c_dept = ""                      && hospital department
				IF RECCOUNT('spec_ins')>0
*!*	               IF SEEK( pc_Clcode + "*" + ALLTRIM( STR( Record.Tag)))

                  DO CASE
                     CASE INLIST( Spec_Ins.Dept, "M", " ")
                        c_dept =  ''            && show no dept for medical records
                     CASE Spec_Ins.Dept = "B"
                        c_dept =  'B'
                     CASE Spec_Ins.Dept = "E"
                        c_dept =  'ECHO'
                     CASE Spec_Ins.Dept = "P"
                        c_dept =  'PATH'
                     CASE Spec_Ins.Dept = "R"
                        c_dept =  'RAD'
                  ENDCASE
               ENDIF
*!*	               = gfunuse("spec_ins", l_Used)
*!*	               SELECT (n_Curarea)
               c_RezTxt = c_RezNew + " " + c_dept
            ENDIF
         ENDIF
      ELSE
         c_RezTxt = LEFT( c_RezTxt, 1)
      ENDIF
      IF l_Plink
         c_RezTxt = "PLT " + c_RezTxt
      ENDIF
ENDCASE
c_RezTxt = lfuniqtg(c_RezTxt, ln_Newtag)
RETURN  c_RezTxt

****************************************************************************
*  FUNCTION LFSUPPL
*  Abstract: Identify supplemented tag
*  Added 6/11/03 by kdl
*  Called by:
*****************************************************************************
FUNCTION Lfsuppl
PRIVATE c_Supp
IF Record.Supplem_to > 0
   c_Supp = PADL( ALLTRIM( STR( Record.Supplem_to)), 3, "0")
ELSE
   c_Supp = ""
ENDIF
RETURN c_Supp


****************************************************************************
*  FUNCTION LFCONNUM
*  Abstract: Format tag + case continuous number string
*  Added 5/27/04 by kdl
*  Called by:
*****************************************************************************
FUNCTION Lfconnum
PARAMETERS n_newnum, c_origstrg
PRIVATE n_Pos, c_Contnum, c_String, c_newnum
c_newnum = ALLTRIM( STR(  n_newnum))
c_newnum = PADL( c_newnum, 4, '0')
IF PARAMETERS() = 2
   n_Pos1 = AT( "(", c_origstrg) - 1
   n_Pos2 = AT( ")", c_origstrg) - 1
   c_Contnum = SUBSTR( c_origstrg, n_Pos1, n_Pos2 - n_Pos1)
ELSE
   c_Contnum = "(" + lc_BateNum  + ")"

ENDIF

c_String = ;
   PADR( c_newnum + c_Contnum, 10)

RETURN c_String

*****************************************************************************
* FUNCTION: lf_yesno
*
*-- Abstract: Prompt user for yes or no answer
*****************************************************************************
FUNCTION lf_yesno
PARAMETERS lc_message
LOCAL l_response
lo_message = CREATEOBJECT('rts_message_yes_no',lc_message)
lo_message.SHOW
l_response=IIF(lo_message.exit_mode="YES",.T.,.F.)
lo_message.release
RELEASE lo_message
RETURN l_response

*****************************************************************************
* PROCEDURE: lp_message
*
*-- Abstract: display a mesage to the user
*****************************************************************************
PROCEDURE lp_message
LPARAMETERS c_message
o_message = CREATEOBJECT('rts_message',c_message)
o_message.SHOW
RELEASE o_message
