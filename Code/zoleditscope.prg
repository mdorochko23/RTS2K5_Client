*FUNCTION  zolEditScope
PARAMETERS  c_blurbId,  c_BLURB, n_lrsno
LOCAL c_newBlurb  , c_sql
LOCAL  lo_MED AS OBJECT ln_CurArea AS STRING, d_from AS STRING, d_to AS STRING, n_editscope AS INTEGER
n_editscope=0

ln_CurArea=ALIAS()
_SCREEN.MOUSEPOINTER=11
lo_MED =CREATEOBJECT("generic.medgeneric")


IF TYPE('pd_SSCDate ')<>"C"
	d_from=DTOC(pd_SSCDate)
ELSE
	d_from=ALLTRIM(pd_SSCDate)
ENDIF


IF TYPE('pd_MTADate ')<>"C"
	d_to=DTOC(pd_MTADate)
ELSE

	d_to=ALLTRIM(pd_MTADate)
ENDIF





IF pc_litcode <>"ZOL"  
	c_newBlurb =c_BLURB  && not zoloft case
ELSE

	IF MRCType(n_lrsno)<>'MO'
		c_newBlurb =c_BLURB && not Mother case
	ELSE
	
	
&& get the rules :4/21/14
		lo_MED.closealias('LitRule')
		c_sql ="select  dbo.MrctEditScopeRule( '" + pc_litcode + "', '" + pc_area + "')"
		lo_MED.SQLEXECUTE(c_sql, 'LitRule')
		IF USED('LitRule')
			SELECT LitRule
			n_editscope=NVL(LitRule.EXP,0)
		ENDIF


		IF  n_editscope=0
			c_newBlurb =c_BLURB && not MDL-non trial area
		ELSE
**good one
**IF NO DATEFROM AND DATETO - USE BLURB AS IS 12/19/14 -PER ALEC

IF EMPTY(d_to) AND EMPTY(d_from)   OR  (d_to="/  /" AND d_from="/  /" ) &&12/19/14
	c_newBlurb =c_BLURB
ELSE  &&12/19/14

**IF NO DATEFROM AND DATETO - USE BLURB AS IS 12/19/14 -PER ALEC


			c_sql =""
			DO CASE
			CASE    LEFT(c_blurbId ,1) ='F'  && all pharmacy's requests   get 'Present , but pl_ZOLRuleF13
				d_topass=IIF(c_blurbId  ='F013' and pl_ZOLRuleF13 , d_to, 'PRESENT' )			
			
			OTHERWISE
				d_topass= d_to
			ENDCASE

			c_sql ="select [dbo].[FillScopeMRCMom] ( '" +  d_from+ "','" +  d_topass + "','" + fixquote(ALLTRIM(c_BLURB))  + "',1 )"
			lo_MED.SQLEXECUTE(c_sql, 'NewBlurb')
			IF USED('NewBlurb')
				SELECT NewBlurb
				c_newBlurb= NVL(NewBlurb.EXP,'')
			ENDIF
			
	ENDIF 		&&12/19/14

		ENDIF

	ENDIF
ENDIF

IF NOT EMPTY(ln_CurArea)
	SELECT (ln_CurArea)
ENDIF
RELEASE  lo_MED
_SCREEN.MOUSEPOINTER=0

RETURN c_newBlurb
