**********************************************************************
*PROCEDURE QCQUICKTAG
LPARAMETERS nrt,cdescript,ccsource, c_path
LOCAL lcSQLLine, lcIDTblTimeSheet, ncurarea,cclcode

ncurarea=SELECT()
SET CLASSLIB TO issued ADDIT
_SCREEN.MOUSEPOINTER=11
PRIVATE OMED AS OBJECT
OMED=CREATEOBJECT("REQUEST.medREQUEST")
SELECT 0
IF NOT FILE(c_path)&&+ALLTRIM(newtag.file_name))
	gfmessage("Add tag cancelled. Image file not found.")
	RETURN
ENDIF
c_today=DTOC(DATE())
*//Provider
c_provtype=''
*c_provtype=NVL(cplaintiff,'P')
c_mailid='A456475'

lcSQLLine="select dbo.GetdepName ( '" + c_mailid + "')"
OMED.sqlexecute(lcSQLLine,"TagDesc")
IF EMPTY(ALLTRIM(cdescript))
	cdescript=NVL(TagDesc.EXP,"")
ENDIF


lcSQLLine="exec dbo.GetMasterbyRTNumber " + ALLTRIM(nrt)
nr=OMED.sqlexecute(lcSQLLine,"master")

IF RECCOUNT("master")=0
	RETURN .F.
ENDIF

cclcode=MASTER.cl_code

*// Request
lcSQLLine="exec  dbo.InsertQuickRequest '"+ALLTRIM(MASTER.id_tblmaster)+"', "+;
	"'"+fixquote(ALLTRIM(cclcode))+"', '"+ALLTRIM(c_mailid)+"', "+;
	"'"+LEFT(fixquote(ALLTRIM(UPPER(cdescript))),50)+"', "+;
	"'"+c_today+"', 'R', "+;
	'1'+", '(QCQR) "+ALLTRIM(Pc_userid)+"'"
nr=OMED.sqlexecute(lcSQLLine,"viewReq")
SELECT viewReq
IF RECCOUNT()=0
	RETURN .F.
ENDIF

lcSQLLine="SELECT TAG, MAILID_NO, REQ_DATE, REQDUEDATE,expedite, id_tblrequests FROM tblrequest with (nolock) WHERE id_tblrequests ='"+viewReq.id_tblrequests+ "' AND ACTIVE =1 "
nr=OMED.sqlexecute(lcSQLLine,"viewRequest")

*//Set Public Var
pl_GotCase=.F.
DO gfGetCas
pl_GotDepo=.F.
DO gfGetDep WITH MASTER.cl_code,viewRequest.TAG

*// TXN 11
lcIDTblTimeSheet=OMED.addtxnrec("I",d_today,;
	ALLTRIM(UPPER(fixquote(cdescript))), ALLTRIM(cclcode),11,;
	viewRequest.TAG,ALLTRIM(c_mailid), 0,0.0000, 0, "","","",0, ;
	"", "",Pc_userid, viewRequest.id_tblrequests, "")

*// SpecIns
lcSQLLine="Exec dbo.EditSpecIns  NULL, '"+lcIDTblTimeSheet+"', "+;
	"'"+fixquote(ALLTRIM(cclcode))+"', '"+ALLTRIM(STR(viewRequest.TAG))+"',"+;
	"'','"+LEFT(fixquote(ALLTRIM(UPPER(cdescript))),50)+"',"+;
	"'"+DTOC(convrtDate(d_today))+ "', 'A', 1, '"+ALLTRIM(c_mailid)+"', "+;
	"'Z', '', 0, '"+DTOC(convrtDate(d_today))+ "', '"+Pc_userid+"', 1, 0, ''"
nr=OMED.sqlexecute(lcSQLLine)

*// TXN 1
c_SQL="Update tblrequest set status='R',hstatus='' where "+;
	"id_tblrequests='"+ALLTRIM(viewRequest.id_tblrequests)+"'"

nr=OMED.sqlexecute(c_SQL)

lcIDTblTimeSheet=OMED.addtxnrec("I",d_today,;
	ALLTRIM(UPPER(fixquote(cdescript))), ALLTRIM(cclcode),1,;
	viewRequest.TAG,ALLTRIM(c_mailid), 0,0.0000, 0, "","","",0, ;
	"", "",'Scanning hold', viewRequest.id_tblrequests, "")

*// Add Admissn categories
DO CASE
CASE  c_provtype="P"
	lcStatment="'Records Produced by plaintiff counsel are attached.'"
CASE   c_provtype="D"
	lcStatment="'Records Produced by defense counsel are attached.'"
OTHERWISE
	lcStatment="'Records Produced by counsel are attached.'"
ENDCASE

lcSQLLine="exec dbo.insertAdmissnRecord '"+fixquote(ALLTRIM(cclcode))+"', "+;
	ALLTRIM(STR(viewRequest.TAG))+", '1', 'R', '!',"+;
	ALLTRIM(lcStatment)+", '"+Pc_userid+"'"
nr=OMED.sqlexecute(lcSQLLine)

*// Add Orders, distBill
DO SetOrdTg WITH viewRequest.TAG

*// Post jobs to DistToDo
DO postdsjob

*// Add Bates
DO addbates WITH viewRequest.TAG,MASTER.cl_code,MASTER.id_tblmaster,cdescript

*//make cover page
STORE .T. TO pl_autosc,pl_Softimg,pl_addcasetag
DO CovLet WITH .T.,"","P","",.T.
STORE .F. TO pl_autosc,pl_Softimg,pl_addcasetag

*// add soft copy job
DO additemjob WITH VAL(nrt),viewRequest.TAG, c_path


IF NOT EMPTY(ncurarea)
	SELECT (ncurarea)
ENDIF
RELEASE OMED

************************************************************************
PROCEDURE additemjob
PARAMETERS nlrsno, ntag, c_filepath
LOCAL ctype,c_SQL,nr,s_Now,o_tif,c_readyname,cfilename

c_readyname=""
cfilename=c_filepath

*--5/17/18: kdl - for PDF files, just get page count. They will be converted to TIFFs externally [56363]
LOCAL lPDFFile
lPDFFile = IIF(UPPER(JUSTEXT(cfilename))=="PDF",.T.,.F.)
IF lPDFFile = .T.
	LOCAL c_softbase, c_softfile
	n_pagecnt=GetPdfPgCnt(c_filepath)
*--get unique tiff file name
	c_softbase=ADDBS("\\imagesvr\rtdocs\RT-Auto\SC-Ready\")+ALLTRIM(STR(nlrsno))+"-"+ALLTRIM(STR(ntag))
	ncnt=1
	c_softfile=c_softbase+".tif"
	DO WHILE FILE(c_softfile)
		c_softfile=c_softbase+"rev"+ ALLTRIM(STR(ncnt))+".tif"
		ncnt = ncnt+1
	ENDDO
	c_readyname=c_softfile
ELSE
	o_tif=CREATEOBJECT("issued.frmautoimage",nlrsno,ntag,cfilename)
	n_pagecnt=o_tif.itotalpages
	c_readyname=o_tif.workfile
	RELEASE o_tif
	IF EMPTY(c_readyname)
		gfmessage("ERROR: soft copy file not saved!")
	ENDIF
ENDIF

*!* o_tif=CREATEOBJECT("issued.frmautoimage",nlrsno,ntag,cfilename)
*!*	n_pagecnt=o_tif.itotalpages
*!*	c_readyname=o_tif.workfile
*!*	RELEASE o_tif
*!*	IF EMPTY(c_readyname)
*!*		gfmessage("ERROR: soft copy file not saved!")
*!*	ENDIF

c_SQL = "Select top 1 nid From tblTagTrack  with (nolock) where lrs_no=" + ALLTRIM(STR(nlrsno)) + " ;
	And tag=" + ALLTRIM(STR(ntag)) + " And deleted is null and active=1"
nr=OMED.sqlexecute(c_SQL,'Tagtrack')

IF RECCOUNT('Tagtrack')<1
	IF NOT USED('viewrequest')
		c_SQL="exec dbo.getrequestbylrsno "+ALLTRIM(STR(nlrsno)) + "," +ALLTRIM(STR(ntag))
		nr=OMED.sqlexecute(c_SQL,'viewrequest')
	ENDIF

	c_SQL="Insert Into tblTagTrack " +;
		"(lrs_no,tag,req_date,mailid_no,litigation,rush,created,createdby,active) values (" +;
		ALLTRIM(STR(nlrsno)) + "," + ;
		ALLTRIM(STR(ntag)) + "," + ;
		IIF(EMPTY(NVL(viewRequest.req_date,{})),'null',"'"+DTOC(TTOD(viewRequest.req_date))+"'") + "," +;
		"'"+NVL(viewRequest.MailID_no,'')+"'" + "," +;
		"'"+NVL(MASTER.litigation,'')+"'"+ "," +;
		IIF(viewRequest.expedite,'1','0') + "," +;
		"getdate()" + "," +;
		"'"+Pc_userid+"'"+ "," +;
		"1)"
	nr=OMED.sqlexecute(c_SQL)

	c_SQL = "Select top 1 nid From tblTagTrack with (nolock) where lrs_no=" + ALLTRIM(STR(nlrsno)) + " ;
		And tag=" + ALLTRIM(STR(ntag)) + " And deleted is null and active=1"
	nr=OMED.sqlexecute(c_SQL,'Tagtrack')
ENDIF

s_Now=TTOC(DATETIME())

ctype='R'

c_SQL="Insert Into tblTagItem " + ;
	"(nid_tblTagTrack,lrs_no,tag,doc_type,rec_mode,created,createdby,preproc_done,preproc_user"+;
	",softcopy_assign,softcopy_user,active,softcopy_infolder,prov_client,softcopy_done) values (" + ;
	tagtrack.nid + "," + ;
	ALLTRIM(STR(nlrsno)) + "," + ;
	ALLTRIM(STR(ntag)) + "," + ;
	"'&cType.','A'," + ;
	"'"+s_Now+ "'," + ;
	"'"+Pc_userid+"'" + "," +;
	"'"+s_Now+ "'," +;
	"'"+Pc_userid+"'" + "," +;
	"getdate()" + "," +;
	"'"+Pc_userid+"'"+ "," +;
	"1," +;
	"'" + c_readyname + "'" +;
	",'" + '' + "'" + "," +;
	"getdate()" +;
	")"
nr=OMED.sqlexecute(c_SQL)

c_SQL="select *,doc_type as doctype from tbltagitem  with (nolock) where "+;
	"nid_tbltagtrack="+tagtrack.nid + " and " + ;
	"lrs_no="+ALLTRIM(STR(nlrsno)) + " and " + ;
	"tag="+ALLTRIM(STR(ntag)) + " and doc_type='&cType.' and " + ;
	"rec_mode='A' and created=cast('"+s_Now+"' as datetime)"
nr=OMED.sqlexecute(c_SQL,'viewjobS')

IF RECCOUNT('viewjobS')>0
	IF INLIST(ctype,'R','IR')
		c_SQL="update tblrequest set nid_tbltagitem=" + ALLTRIM(viewjobS.nid) + ;
			" ,pages=" + ALLTRIM(STR(n_pagecnt)) + ;
			" where cl_code=dbo.getclcodebylrs(" + ALLTRIM(STR(nlrsno)) + ")" + ;
			" And tag=" + ALLTRIM(STR(ntag)) + " And deleted is null and active=1"
		nr=OMED.sqlexecute(c_SQL)
	ENDIF
ENDIF

*--5/17/18: kdl - for PDF files, add to PDF2TIFF job queue. It will convert and add to tblrssjobs. [56363]
IF lPDFFile = .T.
	DO addtoPdf2Tiff WITH nlrsno,ntag,viewjobS.nid,cfilename,c_readyname, n_pagecnt
ELSE
	DO addtorss WITH nlrsno,ntag,viewjobS.nid,c_readyname, n_pagecnt
ENDIF
*--DO addtorss WITH nlrsno,ntag,viewjobS.nid,c_readyname, n_pagecnt

*************************************************************************
PROCEDURE addtorss
PARAMETERS nlrsno,ntag,nid,cthefile, n_pages
LOCAL cpath,cfile,ccovpath
cpath=JUSTPATH(cthefile)
cfile=JUSTFNAME(cthefile)
ccovpath=''
c_readyname=''
l_ocr=.F.
c_group='0'
c_priority='6'
l_needqa=.F.
c_rtpages=ALLTRIM(STR(n_pages))
crsstest="0"
crsstable="tblRssjobs"
c_SQL = "INSERT INTO " + crsstable + ;
	" (dtCreated, sRt, nTag, sPath, sFile, sCovPath, sDeletePages,npriority,suser" + ;
	",bneedqa,sqcqueue,nid_tbltagitem,NRTPAGES,brsstest)" + ;
	" Values " + ;
	"(" + ;
	"'"+TTOC(DATETIME())+"'"+;
	","+ALLTRIM(STR(nlrsno))+;
	","+ALLTRIM(STR(ntag))+;
	",'"+cpath+"'"+;
	",'"+cfile+"'"+;
	",'"+ccovpath+"'"+;
	",'"+''+"'"+;
	","+c_priority+;
	",'"+ALLTRIM(Pc_userid)+"'"+;
	","+IIF(l_needqa,"1","0")+;
	",'"+Pc_userid+"'"+;
	","+ALLTRIM(nid)+;
	","+c_rtpages+;
	","+crsstest+;
	")"

nr=OMED.sqlexecute(c_SQL)

*************************************************************************
*--5/17/18:kdl-add to the PDF2TIFF job queue. Background procesing will convert PDF to TIFF, and add job to tblrssjobs. [56363]
PROCEDURE addtoPdf2Tiff
PARAMETERS nlrsno,ntag,nidref,cfilenameIn,cFilenameOut, npagecnt
LOCAL l_ocr,c_group,c_priority,l_needqa,crsstest,c_PdfCopy,c_softbase,l_add2rss

WAIT WINDOW "Preparing PDF conversion job" NOWAIT

l_ocr=.F.
l_add2rss = .T.
c_group='0'
c_priority='100'
l_needqa=.F.

*--copy user's PDf file to a holding area for processing by external system
c_softbase=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","PDFCONVERTQUEUE", "\"))) + JUSTSTEM(cFilenameOut)
ncnt=1
c_PdfCopy=c_softbase+".pdf"
DO WHILE FILE(c_PdfCopy)
	c_PdfCopy=c_softbase+"rev"+ ALLTRIM(STR(ncnt))+".pdf"
	ncnt = ncnt+1
ENDDO
COPY FILE (cfilenameIn) TO (c_PdfCopy)

c_SQL = "INSERT INTO tbljobPdf2Tiff " + ;
	" (sjobtype,iRt, iTag, irefid, sinputfile, soutputfile, ipagecntin,ipriority,badd2rss,bneedqa,createdby,suserid)" + ;
	" Values " + ;
	"(" + ;
	"'QCQUICK'"+;
	","+ALLTRIM(STR(nlrsno))+;
	","+ALLTRIM(STR(ntag))+;
	","+ALLTRIM(nidref)+;
	",'"+c_PdfCopy+"'"+;
	",'"+cFilenameOut+"'"+;
	","+ALLTRIM(STR(npagecnt))+;
	","+c_priority+;
	","+IIF(l_add2rss,"1","0")+;
	","+IIF(l_needqa,"1","0")+;
	",'"+ALLTRIM(Pc_userid)+"'"+;
	",'"+ALLTRIM(Pc_userid)+"'"+;
	")"

nr=OMED.sqlexecute(c_SQL)


WAIT CLEAR


***************************************************************************
PROCEDURE addbates
LPARAMETERS lnTag,cclcode,idtblmaster,cdesc
LOCAL lnCurArea
lnCurArea=SELECT()
nr=OMED.sqlexecute("SELECT bates FROM tblinstruct WITH (nolock) "+;
	"WHERE cl_code='"+cclcode+"' AND active=1",'viewInstruct')
SELECT viewInstruct
IF RECCOUNT()>0 AND NVL(viewInstruct.bates,.F.)=.T.
	goApp.OpenForm("case.frmbateslist", "M",NULL,idtblmaster, ;
		cclcode, .T., lnTag, ALLTRIM(UPPER(cdesc)), .T., c_provtype)
ENDIF
USE IN viewInstruct
SELECT (lnCurArea)

***************************************************************************
PROCEDURE postdsjob
LOCAL n_curarea,c_shiptype,sDonotocr,n_dsid
n_curarea=SELECT()
SELECT 0
**10/01/18 SL #109598
*c_SQL="select * from tblorder WITH (nolock,index (ix_tblorder_1)) where "+
c_SQL="select * from tblorder WITH (nolock) where "+;
	"cl_code='&pc_clcode.' and tag="+STR(pn_tag)+;
	"AND date_order is not null AND date_decln IS null AND date_cancl is null "+;
	"AND active=1 and deleted is null"
OMED.sqlexecute(c_SQL,'actorders')
l_ocr=.F.
IF RECCOUNT('actorders')>0
	SELECT actorders
	DIMENSION a_types[6]
	a_types[1]="P"
	a_types[2]="D"
	a_types[3]="V"
	a_types[4]="C"
	a_types[5]="F"
	a_types[6]="W"
	n_Alen=ALEN(a_types, 1)
	sDonotocr=IIF(l_ocr,"0","1")
	SCAN
		c_Ordtypes = IIF( actorders.NumCopy > 0 AND ;
			INLIST(actorders.shiptype, " ", "P"), "P", actorders.shiptype)

		lcSQLLine="Exec dbo.call_dsordertype '"+pc_clcode+"', "+ALLTRIM(STR(pn_tag))+","+ ;
			"'"+fixquote(actorders.At_Code)+"', '"+""+"', '"+actorders.shiptype+"', '1', "+;
			"'"+actorders.id_tblOrders+"', '', '&c_Ordtypes.',2"
		OMED.sqlexecute(lcSQLLine,"viewShipTypes")
		SELECT viewShipTypes
		IF RECCOUNT()>0
			GO TOP IN viewShipTypes
			c_Ordtypes=ALLTRIM(NVL(viewShipTypes.ordtypes,''))
		ENDIF
		USE IN viewShipTypes
		lcshiptype=IIF(EMPTY(c_Ordtypes),"P",c_Ordtypes)
		FOR EACH c_shiptype IN a_types
			IF c_shiptype $ lcshiptype
				IF c_shiptype<>"P"
					IF gfsendds(actorders.At_Code)
						n_dsid=gfdsjobid()
						c_SQL= "EXEC dbo.dspost '&pc_clcode.',"+STR(pn_tag)+",'"+;
							fixquote(actorders.At_Code)+"','"+fixquote(pc_Area)+"',0,'"+;
							c_shiptype+"','',1,1,NULL,'&n_dsid.',&sDonotocr."
						OMED.sqlexecute(c_SQL)
					ENDIF
				ENDIF
			ENDIF
		ENDFOR

*!*			IF NOT l_ocr
*!*				lcSQLLine="update tbldisttodo set not_ocr=1 where lrs_no='"+ALLTRIM(STR(pn_lrsno))+"'"+;
*!*					"and tag="+ALLTRIM(STR(pn_tag))+" and at_code='"+ALLTRIM(fixquote(actorders.At_Code))+"'"+;
*!*					" and rem_Date is null and enter_date>='"+DTOC(DATE())+"'"
*!*				omed.sqlexecute(lcSQLLine)

*!*				lcSQLLine="update pdf_ocr..tbljob set bocr=0 where srt='"+ALLTRIM(STR(pn_lrsno))+"'"+;
*!*					"and ntag="+ALLTRIM(STR(pn_tag))+" and dtdeleted is null and dtcreated>='"+DTOC(DATE())+"'"
*!*				omed.sqlexecute(lcSQLLine)
*!*			ENDIF
		SELECT actorders
	ENDSCAN
ENDIF
IF USED('actorders')
	USE IN actorders
ENDIF
SELECT (n_curarea)

