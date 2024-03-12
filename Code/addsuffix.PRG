
**FUNCTION  addSuffix
**11/16/2017: Added  EXACT so 13 and 133 treated as not the same!! ##73524
Local c_add As String, c_dist As String
c_add =""
c_Exact = SET( "EXACT")
SET EXACT ON

c_dist=Allt( Nvl(pc_distrct,''))

*IF INLIST(c_dist,"11","12","13")
IF INLIST(right(c_dist,2),"11","12","13")	&& 1/5/2024, ZD #346577, JH
	c_add ='th'
else
	Do Case
	Case Right(c_dist,1)='1'
		c_add ='st'
	Case Right(c_dist,1)='2'
		c_add ='nd'
	Case Right(c_dist,1)='3'
		c_add ='rd'
	Otherwise
		c_add ='th'

	Endcase
endif


   SET EXACT &c_Exact

Return c_add
