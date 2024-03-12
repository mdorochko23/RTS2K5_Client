*FUNCTION  MRCEditScope
PARAMETERS  c_blurbId,  c_BLURB, n_lrsno
LOCAL c_newBlurb  , c_sql
LOCAL  lo_MED AS OBJECT ln_CurArea AS STRING, d_from AS STRING, d_to AS STRING, n_editscope as Integer
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
		n_editscope=NVL(litrule.exp,0)
	ENDIF
	
	
		IF  n_editscope=0
			c_newBlurb =c_BLURB && not MDL-non trial area
		ELSE
**good one

			c_sql =""
**c_sql ="select [dbo].[FillScopeMRCMom] ( '" +  d_from+ "','" + IIF( c_blurbId  ='F',  'PRESENT' , d_to) + "','" + fixquote(ALLTRIM(c_BLURB)) + "', " +   IIF( c_blurbId  ='F',STR(0),STR(1)) + "  )"
			c_sql ="select [dbo].[FillScopeMRCMom] ( '" +  d_from+ "','" + IIF( c_blurbId  ='F',  'PRESENT' , d_to) + "','" + fixquote(ALLTRIM(c_BLURB))  + "',1 )"
			lo_MED.SQLEXECUTE(c_sql, 'NewBlurb')
			IF USED('NewBlurb')
				SELECT NewBlurb
				c_newBlurb= NVL(NewBlurb.EXP,'')
			ENDIF

		ENDIF

	ENDIF
ENDIF

IF NOT EMPTY(ln_CurArea)
	SELECT (ln_CurArea)
ENDIF
RELEASE  lo_MED
_SCREEN.MOUSEPOINTER=0

RETURN c_newBlurb
