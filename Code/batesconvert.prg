*-----------------------------------
*--convert text bates to table bates
*-----------------------------------
PARAMETERS  cRt,nDefid,nCaseid

IF PCOUNT()>3
	RETURN
ENDIF

LOCAL ocon,cCaseid,cLit,cArea,cBatesbase,ncurarea

ncurarea=SELECT()

SET CLASSLIB TO dataconnection ADDITIVE

ocon=CREATEOBJECT("dataconnection.cntdataconn")

cCaseid= ALLTRIM(STR(nCaseid))
cBatesbase = "\\datastor\volume1\bates\"

c_sql="SELECT * from tblbatesdef where nid=" + ALLTRIM(STR(nDefid)) +" and active=1"
nr=ocon.sqlpassthrough(c_sql,'batesdef')

IF RECCOUNT('batesdef')>0
	cLit=UPPER(ALLTRIM(NVL(batesdef.slit,'')))
	cArea=UPPER(ALLTRIM(NVL(batesdef.sarea,'')))
ELSE
	RETURN
ENDIF

CREATE CURSOR curtagcon (tag_1 c(3), text_2 c(55),DESCRIPT c (50),Stnum_3 c(8),Endnum_4 c(8),stampdt_5 d,lblecnt_7 c(2),Linktag_11 c(3),user_8 c(25),Editdt_9 d,stamptm_10 c(12) ;
	,Factsht_12 c(1),Plcmat_13 c(1),StpgFs_14 c(3), nrecno INT,stamped_6 c(1))

*-- check for a bates text file for the Rt
N=ADIR(afolders,cBatesbase +"*","D")

FOR icnt=1 TO N
	IF "D" $ afolders[icnt,5] AND NOT INLIST(ALLTRIM(afolders[icnt,1]),".","..")

		RELEASE afile

		lc_Filetxt=cBatesbase + ADDBS(ALLTRIM(afolders[icnt,1])) + cRt + ".txt"
		N2=ADIR(afile,lc_Filetxt)
		IF N2>0
*-- check for litgation/area match of text file folder and case
			IF USED('batestxtdata')
				USE IN batestxtdata
			ENDIF
			c_sql="SELECT * from tblbatestextdata where pathname='"+ALLTRIM(afolders[icnt,1])+"'"
			nr=ocon.sqlpassthrough(c_sql,'batestxtdata')
			DO CASE
			CASE NOT UPPER(ALLTRIM(batestxtdata.litigation))==cLit
				LOOP
			CASE batestxtdata.a1notarea
				IF UPPER(ALLTRIM(batestxtdata.area1))==cArea
					LOOP
				ENDIF
			CASE batestxtdata.a2notarea
				IF UPPER(ALLTRIM(batestxtdata.area2))==cArea
					LOOP
				ENDIF

			CASE ((NOT INLIST(ALLTRIM(ALLTRIM(batestxtdata.area1)),"*","")) AND (NOT (UPPER(ALLTRIM(batestxtdata.area1))==cArea OR UPPER(ALLTRIM(batestxtdata.area2))==cArea)))
				LOOP
			ENDCASE

			ln_Fhndle = FOPEN(lc_Filetxt)
			IF ln_Fhndle > 0
				IF USED('curreq')
					USE IN curreq
				ENDIF
				c_sql="exec dbo.getrequestbylrsno &crt."
				nr=ocon.sqlpassthrough(c_sql,'curreq')

				m.ln_counter = 1
				m.ln_TagCnt = 1
				DO WHILE NOT FEOF(ln_Fhndle)
					lc_curtxt = FGETS(ln_Fhndle)
					DO CASE
					CASE ln_counter = 1                    && Case bates text
						lc_CaseTxt = lc_curtxt
					CASE ln_counter = 2                    && Starting bates number for next script run
						lc_BateNum = lc_curtxt
						ln_bateLen = LEN( ALLTRIM( lc_curtxt))
					CASE ln_counter = 3                    && Date stamp for last action on text file
						lc_TimeStp = lc_curtxt
					CASE ln_counter = 4                    && This is the number of the page to start bates stamping on
						lc_Startpge = lc_curtxt
					CASE ln_counter > 4 AND LEN( lc_curtxt) >= 3 && rest of file is tag data
						ctag_1=LEFT( lc_curtxt, 3)

						ctext_2=SUBSTR( lc_curtxt, 6, 55) && tag's description
						cStnum_3  = SUBSTR( lc_curtxt, 61, 10) && starting number for tag
						cEndnum_4  = SUBSTR( lc_curtxt, 71, 10) && ending number for the tag
						dstampdt_5 = SUBSTR( lc_curtxt, 83, 10) && time stamp
						dstampdt_5 = IIF( ALLTRIM( dstampdt_5) == '', ;
							'  /  /    ' , dstampdt_5 )

						IF LEN( dstampdt_5 )< 10
							dstampdt_5 = PADR( dstampdt_5, 10)
						ENDIF
						dstampdt_5=CTOD(dstampdt_5)

						cstamptm_10=SPACE(12)
						IF LEN( lc_curtxt) >= 95
							cstamptm_10 = SUBSTR( lc_curtxt, 95, 12) && date/time stamp
						ENDIF

						cstamped_6 = '0'
						IF LEN( lc_curtxt) >= 107
							cstamped_6 = SUBSTR( lc_curtxt, 107, 1) && script run counter
							IF EMPTY( cstamped_6 )
								cstamped_6  = '0'
							ENDIF
						ENDIF
						clblecnt_7 = '0'
						IF LEN( lc_curtxt) >= 110
							clblecnt_7 = SUBSTR( lc_curtxt, 110, 1) && label run counter
							IF EMPTY( clblecnt_7)
								clblecnt_7= '0'
							ENDIF
						ENDIF

						IF LEN( lc_curtxt) >= 113
							cuser_8= SUBSTR( lc_curtxt, 113, 25) && user id
							dEditdt_9 = CTOD(SUBSTR( lc_curtxt, 138, 10)) && edit date
						ELSE
							cuser_8 = SPACE(25)
							dEditdt_9 = {"  /  /    "}
						ENDIF
*--linked tag
						cLinktag_11 = ''
						IF LEN( lc_curtxt) >= 150
							cLinktag_11 = SUBSTR( lc_curtxt, 150, 3) && linked tag
						ENDIF

*--plaintiff fact sheet
						IF LEN( lc_curtxt) >= 154
							cFactsht_12 = SUBSTR( lc_curtxt, 154, 1) && fact sheet indicator
						ELSE
							cFactsht_12 = 'N'
						ENDIF
*--plainiff counsel materials
						IF LEN( lc_curtxt) >= 156
							cPlcmat_13 = SUBSTR( lc_curtxt, 156, 1) && plaintiff counsel materials
						ELSE
							cPlcmat_13 = 'N'
						ENDIF
*--Fact sheet bates starting page
						IF LEN( lc_curtxt) >= 158
							cStpgFs_14 = SUBSTR( lc_curtxt, 158, 3) && fact sheet starting page
						ELSE
							cStpgFs_14 = '000'
						ENDIF
*--update the cursor
						cdesc=""
						SELECT DESCRIPT FROM curreq INTO ARRAY atags WHERE TAG= VAL(ctag_1)
						IF _TALLY>0
							cdesc =atags[1]
						ENDIF
						csupp="0"
						SELECT Supplem_to FROM curreq INTO ARRAY atags WHERE TAG= VAL(ctag_1)
						IF _TALLY>0
							csupp =ALLTRIM(STR(atags[1]))
						ENDIF

						INSERT INTO curtagcon (tag_1,text_2,DESCRIPT,Stnum_3,Endnum_4,stampdt_5,stamptm_10,stamped_6,lblecnt_7,user_8,Editdt_9 ;
							,Linktag_11,Factsht_12,Plcmat_13,StpgFs_14,nrecno) VALUES ;
							(ctag_1,ctext_2,cdesc,cStnum_3,cEndnum_4,dstampdt_5,cstamptm_10,cstamped_6,clblecnt_7,cuser_8,dEditdt_9 ;
							,csupp,cFactsht_12,cPlcmat_13,cStpgFs_14,ln_TagCnt)

						ln_TagCnt = ln_TagCnt + 1
					ENDCASE
					ln_counter = ln_counter + 1
				ENDDO

				=FCLOSE(ln_Fhndle)

				IF RECCOUNT('curtagcon')>0

					c_sql="select * from tblbatestag where ncaseid = &cCaseid. and dtdeleted is null and active=1"
					nr=ocon.sqlpassthrough(c_sql,"batestags")

					SELECT curtagcon
					SCAN
						SELECT * FROM batestags INTO ARRAY atags WHERE ntag=VAL( curtagcon.tag_1)
						IF _TALLY=0

							c_sql= "insert into tblbatestag (nCaseID,nTag,sTagBates,dtCreated,nFirstPage,nLastPage,dtDone,sUser " + ;
								",active,bplaintiff,bdefendant,bfactsheet,nsupplementalto,nfactsheetstartpage,bstamped,nlabelprintcount " + ;
								",editedby,DELETEDBY) values  (" + ;
								cCaseid + ;
								"," + ALLTRIM(curtagcon.tag_1) + ;
								"," + cleanstr(ALLTRIM(curtagcon.text_2)) + ;
								"," + cleanstr(DTOC(curtagcon.Editdt_9)) + ;
								"," + ALLTRIM(curtagcon.Stnum_3) + ;
								"," + ALLTRIM(curtagcon.Endnum_4) + ;
								"," + cleanstr(DTOC(curtagcon.stampdt_5) + " " + ALLTRIM(curtagcon.stamptm_10)) + ;
								"," + cleanstr(ALLTRIM(curtagcon.user_8)) + ;
								"," + "1" + ;
								"," + IIF(EMPTY(ALLTRIM(curtagcon.Plcmat_13)),"0",ALLTRIM(curtagcon.Plcmat_13)) + ;
								"," + "0" + ;
								"," + IIF(EMPTY(ALLTRIM(curtagcon.Factsht_12)),"0",ALLTRIM(curtagcon.Factsht_12)) + ;
								"," + IIF(EMPTY(ALLTRIM(curtagcon.Linktag_11)),"0",ALLTRIM(curtagcon.Linktag_11)) + ;
								"," + IIF(EMPTY(ALLTRIM(curtagcon.StpgFs_14)),"0",ALLTRIM(curtagcon.StpgFs_14)) + ;
								"," + IIF(ISNULL(curtagcon.stampdt_5),"0","1") + ;
								"," + ALLTRIM(curtagcon.lblecnt_7) + ;
								",'','')"

							nr=ocon.sqlpassthrough(c_sql)

						ENDIF
						SELECT curtagcon
					ENDSCAN

					RENAME (cBatesbase + ADDBS(afolders[icnt,1]) + cRt + ".txt") TO (cBatesbase + ADDBS(afolders[icnt,1]) + cRt + ".aut")

				ENDIF


			ENDIF	&& ln_Fhndle > 0 - file is openned

		ENDIF	&& N>0  - text file is found

	ENDIF   && "D" $ afolders[icnt,5] - is a folder

NEXT

IF USED("btagscon")
	USE IN btagscon
ENDIF
IF USED("curreqcon")
	USE IN curreqcon
ENDIF
IF USED("curtagcon")
	USE IN curtagcon
ENDIF

SELECT (ncurarea)

******************************************************************************************************************
FUNCTION cleanstr
PARAMETERS stringin
LOCAL stringout
stringout = "'" + STRTRAN(ALLTRIM(stringin),"'","''") + "'"
RETURN stringout
