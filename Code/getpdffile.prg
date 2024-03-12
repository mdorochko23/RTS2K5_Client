**FUNCTION getpdffile
** finds and stores the info about the latest PDF stored for a rt/tag
** 11/23/09 we need to create a PDF (FAKE) when no other exists yet, added	pl_fakePdf 
** 11/20/2009 MD modified to always go to the last record and only store the last record in the array 
** as all programs check only first row

PARAMETERS nlrsnopdf, nTagPdf, cSortDate
LOCAL l_showform AS Boolean, N_RECNO as Integer, nCnt as Integer
			N_RECNO=0
			l_showform=.F.
			cSortDate = .T.		&& 10/13/2022, ZD #291575, JH
			*WAIT WINDOW 	"Searching for a Pdf file.. "  nowait
*			l_showform= getorigpdf ( nlrsnopdf, nTagPdf, .f.	)			&& 3/15/2021, ZD #230064, JH
			l_showform= getorigpdf ( nlrsnopdf, nTagPdf, .f., cSortDate)	&& 3/15
			
			
*!*				IF NOT USED ('templist')
*!*					USE (Pc_tempFile) IN 0
*!*				ENDIF
				
			IF USED ("templist")
			
				SELECT templist
				GO TOP
				IF NOT EOF()				
					*N_RECNO=RECCOUNT()					
					*PUBLIC ARRAY paTempList ((N_RECNO+1),5)
					PUBLIC ARRAY paTempList (1,5)
					SELECT templist					
						nCnt=1									
						*SCAN WHILE NOT EOF()
						&& always go to the last record and only store the last record in the array as all programs check only first row
						GO BOTTOM 	
						SCATTER MEMVAR						
						STORE m.lrs_no TO paTempList(nCnt,1)
						STORE m.tag TO paTempList(nCnt,2)
						STORE m.filepath TO paTempList(nCnt,3)
						STORE m.filename TO paTempList(nCnt,4)
						STORE m.Foldername TO paTempList(nCnt,5)								
						nCnt=nCnt+1
						*ENDSCAN					
					l_showform=.T.
					pl_fakePdf=.f.
				ELSE
				&&11/23/09 we need to create a PDF (FAKE) when no other exists yet
				pl_fakePdf =.t.
				ENDIF
			ENDIF
RELEASE Pc_tempFile			
RETURN l_showform
