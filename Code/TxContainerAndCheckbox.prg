
*255675 12/15/2021 WY Support checkbox inside grid with rules between grids
#define DWQTYPE_NOTREQUIRED "!"
#define DATETYPE_WITHDWQ 20
#define DATETYPE_NODWQ 10
#define DATETYPE_FINANCIAL 24
#define DATETYPE_NODWQFIN 11 &&06/27/2022 MD #277503

*Supports functionality
*1)enforce selecting only 1 row at a time
*2)container class supports center alignment of the checkbox within the grid cell instead placing the checkbox on the upper left
*3)clicking on the container/cell runs checkbox click, user have a bigger target to check on instead of small checkbox
*4)set .HighlightStyle = 2 during first click, remove color before selection (reduce user confusion)
DEFINE CLASS OutsideContainer AS Container 
	BorderWidth = 0
	backcolor = RGB(255,255,255)
	TableSource = ""
	FieldSource = ""
	GridRef = null
	FormRef = null
	
	PROCEDURE init (tcAlias, tcFieldSource, toGrid, toForm)
		this.addObject("check1", "TxGridChkBox", tcAlias, tcFieldSource)
		this.check1.left =  8 && int(this.width/ 2) - 13
		this.TableSource = tcAlias
		this.FieldSource = tcFieldSource
		this.GridRef = toGrid
		this.FormRef = toForm
	ENDPROC

	PROCEDURE CLICK &&container click
		*support clicking on whole cell, with controls as so small, give the user some help
		IF this.check1.value = .f.
			this.check1.value = .t.
		ELSE
			this.check1.value = .f.	
		ENDIF 
		*honor click/select only 1 row at a time(acts like a combobox)
		this.check1.click()
	ENDPROC
ENDDEFINE


DEFINE CLASS TxGridChkBox as CheckBox 
	TableSource = ""
	FieldSource = ""
	Visible = .t.
	caption = ""
	backstyle = 0 && transparent
	backcolor = RGB(255,255,255)

	PROCEDURE init (tcAlias, tcFieldSource)
		this.TableSource = tcAlias
		this.FieldSource = tcFieldSource
		this.ControlSource = tcAlias + "." + tcFieldSource
	ENDPROC

	PROCEDURE CLICK
		THIS.ApplySmartCheckbox()
	ENDPROC

	*since controls are bound, we can access the data to determine the user's action and then apply rules 
	PROCEDURE ApplySmartCheckbox()
		*honor click/select only 1 row at a time (acts like a combobox)
		LOCAL lnCurrRecNo, lcCursorName, lcFieldName, llNewBoundValue

		lnCurrRecNo=RECNO(this.TableSource)
		lcCursorName=this.TableSource
		lcFieldName = this.FieldSource
		llNewBoundValue = evaluate(lcCursorName + "." + lcFieldName)
		*clear any old selection
		UPDATE &lcCursorName. SET &lcFieldName. = .f. WHERE RECNO(this.TableSource) <> lnCurrRecNo
		&&update is not suppose to move the reocord pointer (perhaps the grid moved it), not a big deal	
		GOTO lnCurrRecNo IN &lcCursorName. 	

		***************************************************
		*SUPPORT BUSINESS RULES/RELATIONSHIPS BETWEEN GRIDS
		*************************************************** 
		IF llNewBoundValue 
			*turn on persistent coloring on first click
			THIS.Parent.GridRef.HighlightStyle = 2	
			THIS.Parent.GridRef.HighlightBackColor = RGB(128,255,255)
			DO CASE 
				CASE lcCursorName = "txDqwCodes" 				
					IF txDqwCodes.code = DWQTYPE_NOTREQUIRED
						this.SelectDwqBox(llNewBoundValue, .F., this.Parent.FormRef,txSendOutDateType.code) &&06/27/2022 MD #277503 added 4t parameter
					ELSE
						this.SelectDwqBox(llNewBoundValue, .T., this.Parent.FormRef,txSendOutDateType.code) &&06/27/2022 MD #277503 added 4t parameter
					ENDIF 
				CASE lcCursorName = "txSendOutDateType"
					DO CASE 
						*CASE txSendOutDateType.code = DATETYPE_NODWQ	 &&06/27/2022 MD #277503	
						CASE INLIST(txSendOutDateType.code ,10,11)														
							*this.SelectSubpoenaDateTypeBox (.t., DATETYPE_NODWQ, this.Parent.FormRef) &&06/27/2022 MD #277503
							this.SelectSubpoenaDateTypeBox (.t., txSendOutDateType.code, this.Parent.FormRef)
						CASE txSendOutDateType.code = DATETYPE_WITHDWQ
							this.SelectSubpoenaDateTypeBox (.t., DATETYPE_WITHDWQ, this.Parent.FormRef)
					ENDCASE 
				CASE lcCursorName = "txCertOrAffType"
					this.SychGridToOldChk (.t., txCertOrAffType.code, this.Parent.FormRef)
						
			ENDCASE 
		ELSE
			*turn off persistent coloring on unselect
			THIS.Parent.GridRef.HighlightStyle = 0
			DO CASE 
				CASE lcCursorName = "txDqwCodes" 				
					IF txDqwCodes.code = DWQTYPE_NOTREQUIRED
						this.SelectDwqBox(llNewBoundValue, .F., this.Parent.FormRef,txSendOutDateType.code) &&06/27/2022 MD #277503 added 4t parameter
					ELSE
						this.SelectDwqBox(llNewBoundValue, .T., this.Parent.FormRef,txSendOutDateType.code) &&06/27/2022 MD #277503 added 4t parameter
					ENDIF 
				CASE lcCursorName = "txSendOutDateType"
					DO CASE 
						*CASE txSendOutDateType.code = DATETYPE_NODWQ &&06/27/2022 MD #277503
						CASE INLIST(txSendOutDateType.code,10,11)
							*this.SelectSubpoenaDateTypeBox (.f., DATETYPE_NODWQ, this.Parent.FormRef)		 &&06/27/2022 MD #277503
							this.SelectSubpoenaDateTypeBox (.f., txSendOutDateType.code, this.Parent.FormRef)							
						CASE txSendOutDateType.code = DATETYPE_WITHDWQ
							this.SelectSubpoenaDateTypeBox (.f., DATETYPE_WITHDWQ, this.Parent.FormRef)
					ENDCASE 
				CASE lcCursorName = "txCertOrAffType"
					this.SychGridToOldChk (.f., txCertOrAffType.code, this.Parent.FormRef)

			ENDCASE 

		ENDIF 

	ENDPROC 


	*******************************************************
	*SUPPORT BUSINESS RULES/RELATIONSHIPS BETWEEN GRIDS
	*******************************************************
	PROCEDURE SelectDwqBox (tlSelect, tlNormalDwq, toThisform,curValue)
		LOCAL lcAlias, lnRecno
		lcAlias = ALIAS()
		lnRecno = RECNO()
		
		DO CASE 
			CASE tlSelect AND tlNormalDwq 
				*USER CLICKED ON NORMAL
				SELECT txSendOutDateType
				GO TOP &&06/27/2022 MD #277503
				replace all pick WITH .f. 
				LOCATE FOR code = DATETYPE_WITHDWQ						
				IF found()
					replace pick WITH .t.
					*highlight row
					IF toThisform.PFrame.Page4.grdTxSubpoenaDate.columncount > 0
						toThisform.PFrame.Page4.grdTxSubpoenaDate.refresh()
						toThisform.PFrame.Page4.grdTxSubpoenaDate.column1.Container1.check1.click()
					ENDIF 
				ELSE
					GO TOP &&06/27/2022 MD #277503
				ENDIF 

			CASE tlSelect AND tlNormalDwq = .f. 
				*USER click on NOT REQUIRED	
				*selecting "Not Required = 10 days"	
				SELECT txSendOutDateType
				GO TOP  &&06/27/2022 MD #277503
				*LOCATE FOR code = DATETYPE_NODWQ AND pick = .f. &&06/27/2022 MD #277503
				LOCATE FOR code =curValue AND pick = .f.
				IF found()
					replace pick WITH .t.
					*highlight row
					IF toThisform.PFrame.Page4.grdTxSubpoenaDate.columncount > 0
						toThisform.PFrame.Page4.grdTxSubpoenaDate.refresh()
						toThisform.PFrame.Page4.grdTxSubpoenaDate.column1.Container1.check1.click()
					ENDIF 
				ELSE
					GO TOP &&06/27/2022 MD #277503
				ENDIF 

			CASE tlSelect = .f. AND tlNormalDwq = .f. 
				SELECT txSendOutDateType
				GO TOP &&06/27/2022 MD #277503
				*LOCATE FOR code = DATETYPE_NODWQ AND pick
				LOCATE FOR code = curvalue AND pick &&06/27/2022 MD #277503
				IF found()
					replace pick WITH .F.
					*highlight row
					IF toThisform.PFrame.Page4.grdTxSubpoenaDate.columncount > 0
						toThisform.PFrame.Page4.grdTxSubpoenaDate.refresh()
						toThisform.PFrame.Page4.grdTxSubpoenaDate.column1.Container1.check1.click()
					ENDIF
				ELSE
					GO TOP &&06/27/2022 MD #277503
				ENDIF 

		ENDCASE 

		IF LEN(lcAlias) > 0
			SELECT (lcAlias)
			GOTO lnRecNo
		ENDIF 
	ENDPROC 

	*******************************************************
	*SUPPORT BUSINESS RULES/RELATIONSHIPS BETWEEN GRIDS
	*******************************************************
	PROCEDURE SelectSubpoenaDateTypeBox (tlSelect, tnCode, toThisform)
		LOCAL lcAlias, lnRecno 
		lcAlias = ALIAS()
		lnRecno = RECNO()
		
		SELECT txDqwCodes
		GO TOP 
		DO case

			CASE tlSelect AND tnCode = DATETYPE_WITHDWQ
				LOCATE FOR code = DWQTYPE_NOTREQUIRED AND pick = .t.
				IF FOUND()
					replace pick WITH .f.
					IF toThisform.PFrame.Page4.grdTxDwq.columncount > 0
						toThisform.PFrame.Page4.grdTxDwq.refresh()
						toThisform.PFrame.Page4.grdTxDwq.column1.Container1.check1.click()		
					ENDIF 
				ELSE
					GO TOP 
				ENDIF 
			*CASE tlSelect AND tnCode = DATETYPE_NODWQ &&06/27/2022 MD #277503
			CASE tlSelect AND INLIST(tnCode ,10,11)
				LOCATE FOR code = DWQTYPE_NOTREQUIRED
				IF FOUND()
					replace pick WITH .t.
					IF toThisform.PFrame.Page4.grdTxDwq.columncount > 0
						toThisform.PFrame.Page4.grdTxDwq.refresh()
						toThisform.PFrame.Page4.grdTxDwq.column1.Container1.check1.click()		
					ENDIF 
				ELSE
					GO TOP 
				ENDIF 
			*CASE tlSelect = .f. AND tnCode = DATETYPE_NODWQ &&06/27/2022 MD #277503
			CASE tlSelect AND INLIST(tnCode,10,11)
				LOCATE FOR code = DWQTYPE_NOTREQUIRED AND pick
				IF FOUND()
					replace pick WITH .f.
					IF toThisform.PFrame.Page4.grdTxDwq.columncount > 0
						toThisform.PFrame.Page4.grdTxDwq.refresh()
						toThisform.PFrame.Page4.grdTxDwq.column1.Container1.check1.click()		
					ENDIF 
				ELSE
					GO TOP 
				ENDIF 

		ENDCASE 
		IF LEN(lcAlias) > 0
			SELECT (lcAlias)
			GOto lnRecno
		ENDIF 
	ENDPROC 


	*send to bottom grid section to the old checkboxes 
	PROCEDURE SychGridToOldChk (tlSelect, tcCode, toThisform)
		LOCAL lcAlias, lnRecno 
		lcAlias = ALIAS()
		lnRecno = RECNO()
		
		SELECT txCertOrAffType
		DO case
			CASE tlSelect AND tcCode = "SUBB" 
				toThisform.chkBill.Value = 1
				toThisform.chkCath.Value = 0
				toThisform.chkEcho.Value = 0
			CASE tlSelect AND tcCode = "SUBN"
				toThisform.chkBill.Value = 0
				toThisform.chkCath.Value = 1
				toThisform.chkEcho.Value = 0
			CASE tlSelect AND tcCode = "NOTR"
				toThisform.chkBill.Value = 0
				toThisform.chkCath.Value = 0
				toThisform.chkEcho.Value = 1

			CASE tlSelect = .f. AND tcCode = "SUBB" 
				toThisform.chkBill.Value = 0
			CASE tlSelect = .f. AND tcCode = "SUBN"
				toThisform.chkCath.Value = 0
			CASE tlSelect = .f. AND tcCode = "NOTR"
				toThisform.chkEcho.Value = 0

		ENDCASE 

		IF LEN(lcAlias) > 0
			SELECT (lcAlias)
			GOto lnRecno
		ENDIF 		
	ENDPROC 

ENDDEFINE



