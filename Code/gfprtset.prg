**************************************************************************************
* PROGRAM: GFPRTSET.PRG
* Programmer: kdl
* Date:
* Abstract: Clear or reset printer command variables
* Called by: printcov.prg, reprqcov.prg, print41.prg
* Calls:
* Modifications:
************************************************************************************
***********************************************************************
* PROCEDURE: lpRstprt
* ABSTRACT: reset printer variables
***********************************************************************
PROCEDURE lpRstprt
*   Used in Prntbar2, Barcode, Printbar
*
PUBLIC ARRAY pc_barchar [44]
PUBLIC pc_bchars, pc_xstart, pc_xend, pc_dpl, pc_narrow, pc_esc, pc_barchar
PRIVATE n_wide, nb, wb, ns, ws, c_wide, c_high
pc_esc = CHR(27)
pc_bchars = "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ-. *$/+%"
* pc_xstart and pc_xend adjust printer's cursor position to
* start at top of line and return to bottom of line
pc_xstart = pc_esc + "*p-50Y"
pc_xend = pc_esc + "*p+50Y"
&& Number of dots/line (300 dpi /6 lpi = 50 dpl)
pc_dpl = 50
pc_narrow = ""

pc_f10  = pc_esc + "(s0p10v0s0b4T"
pc_f10B = pc_esc + "(s0p10v0s3b4T"
pc_f12  = pc_esc + "(s0p12v0s0b4T"
pc_f12B = pc_esc + "(s0p12v0s3b4T"
pc_f14  = pc_esc + "(s1p14v0s0b4T"
pc_f14B = pc_esc + "(s1p14v0s3b4T"
pc_f18  = pc_esc + "(s1p18v0s0b4T"
pc_f18B = pc_esc + "(s1p18v0s3b4T"
_PBigBold = pc_esc + "&l0O" + pc_esc + "(1U" + pc_esc + "(s1p14v0s3b4T"
_PRegBold = pc_esc + "&l0O" + pc_esc + "(1U" + pc_esc + "(s0p10h12v0s3b3T"
_PReg = pc_esc + CHR( 40) + CHR( 115) + CHR( 48) + CHR( 66)
_PBold = pc_esc + CHR( 40) + CHR( 115) + CHR( 51) + CHR( 66)
_PPt6 = pc_esc + CHR( 40) + CHR( 115) + "#6#" + CHR( 72)
_PPt8 = pc_esc + CHR( 40) + CHR( 115) + "#8#" + CHR( 72)
_PPt9 = pc_esc + CHR( 40) + CHR( 115) + "#9#" + CHR( 72)
_PPt10 = pc_esc + CHR( 40) + CHR( 115) + "#10#" + CHR( 72)
_PPt11 = pc_esc + CHR( 40) + CHR( 115) + "#11#" + CHR( 72)
_PPt12 = pc_esc + CHR( 40) + CHR( 115) + "#12#" + CHR( 72)
_PPt14 = pc_esc + CHR( 40) + CHR( 115) + "#14#" + CHR( 72)
_PPt18 = pc_esc + CHR( 40) + CHR( 115) + "#18#" + CHR( 72)
_PPt24 = pc_esc + CHR( 40) + CHR( 115) + "#24#" + CHR( 72)
_PPt30 = pc_esc + CHR( 40) + CHR( 115) + "#30#" + CHR( 72)
_PPt36 = pc_esc + CHR( 40) + CHR( 115) + "#36#" + CHR( 72)
_PPt42 = pc_esc + CHR( 40) + CHR( 115) + "#42#" + CHR( 72)
_PPt48 = pc_esc + CHR( 40) + CHR( 115) + "#48#" + CHR( 72)
_PPt54 = pc_esc + CHR( 40) + CHR( 115) + "#54#" + CHR( 72)
_PPt60 = pc_esc + CHR( 40) + CHR( 115) + "#60#" + CHR( 72)
_PPt72 = pc_esc + CHR( 40) + CHR( 115) + "#72#" + CHR( 72)
_PNormal = pc_esc + CHR( 40) + CHR( 115) + CHR( 48) + CHR( 83)
_PItalic = pc_esc + CHR( 40) + CHR( 115) + CHR( 49) + CHR( 83)
_PCourier = pc_esc + CHR( 40) + CHR( 115) + CHR( 51) + CHR( 84)
_PUnivers = pc_esc + CHR( 40) + CHR( 115) + CHR( 52) + CHR( 49) + ;
   CHR( 52) + CHR( 56) + CHR( 84)
_PHelv = pc_esc + CHR( 40) + CHR( 115) + CHR( 52) + CHR( 84)
cpi8       = pc_esc + CHR( 40) + CHR( 115) + "8" + CHR( 72)
cpi10      = pc_esc + CHR( 38) + CHR( 107) + CHR( 48) + CHR( 83)
cpi12      = pc_esc + CHR( 40) + CHR( 115) + "12" + CHR( 72)
c_landscap = pc_esc + CHR( 38) + CHR( 108) + CHR( 49) + CHR( 79)
c_portrait = pc_esc + CHR( 38) + CHR( 108) + CHR( 48) + CHR( 79)
c_titlegr  = pc_esc + "&l1O" + pc_esc + "&l6D" + pc_esc + "(s12H"
c_endgr    = pc_esc + "E"
c_MakeSmal = pc_esc + "(s16.6H" + pc_esc + "(10U"
c_MakeBig  = pc_esc + "(s10H"  + pc_esc + "(10U"
c_title10  = pc_esc + CHR( 40) + CHR( 115) + "#10#" + CHR( 72)
c_title14  = pc_esc + CHR( 40) + CHR( 115) + "#14#" +CHR( 072)
c_title8   = pc_esc + "&l1O" + pc_esc + "&l8D" + pc_esc + "(s16.6H"
c_bigbold  = pc_esc + "&l0O" + pc_esc + "(1U" + pc_esc + "(s1p14v0s3b4T"
c_regbold  = pc_esc + "&l0O" + pc_esc + "(1U" + pc_esc + "(s0p10h12v0s3b3T"
c_reg      = pc_esc + "&l0O" + pc_esc + "(1U" + pc_esc + "(s0p10h12v0s0b3T"
n_narrow = 3.60
n_barhi = 3
n_wide = ROUND(n_narrow * 2.25, 0)                 && 2.25 x n_narrow
c_wide = TRANSFORM(n_wide, "99")
pc_narrow = TRANSFORM( n_narrow, "99")
c_high = ALLTRIM(STR( n_barhi * pc_dpl))

** nb = print string for narrow bar
** wb = print string for wide bar
** ns = print string for narrow space
** ws = print string for wide space

nb = pc_esc + "*c" + pc_narrow + "a" + c_high ;
   + "b0P" + pc_esc + "*p+" + pc_narrow + "X"
wb = pc_esc + "*c" + c_wide + "a" + c_high ;
   + "b0P" + pc_esc + "*p+" + c_wide + "X"
ns = pc_esc + "*p+" + pc_narrow + "X"
ws = pc_esc + "*p+" + c_wide + "X"
**
pc_barchar[01] = wb+ns+nb+ws+nb+ns+nb+ns+wb           && Character "1"
pc_barchar[02] = nb+ns+wb+ws+nb+ns+nb+ns+wb           && Character "2"
pc_barchar[03] = wb+ns+wb+ws+nb+ns+nb+ns+nb           && Character "3"
pc_barchar[04] = nb+ns+nb+ws+wb+ns+nb+ns+wb           && Character "4"
pc_barchar[05] = wb+ns+nb+ws+wb+ns+nb+ns+nb           && Character "5"
pc_barchar[06] = nb+ns+wb+ws+wb+ns+nb+ns+nb           && Character "6"
pc_barchar[07] = nb+ns+nb+ws+nb+ns+wb+ns+wb           && Character "7"
pc_barchar[08] = wb+ns+nb+ws+nb+ns+wb+ns+nb           && Character "8"
pc_barchar[09] = nb+ns+wb+ws+nb+ns+wb+ns+nb           && Character "9"
pc_barchar[10] = nb+ns+nb+ws+wb+ns+wb+ns+nb           && Character "0"
pc_barchar[11] = wb+ns+nb+ns+nb+ws+nb+ns+wb           && Character "A"
pc_barchar[12] = nb+ns+wb+ns+nb+ws+nb+ns+wb           && Character "B"
pc_barchar[13] = wb+ns+wb+ns+nb+ws+nb+ns+nb           && Character "C"
pc_barchar[14] = nb+ns+nb+ns+wb+ws+nb+ns+wb           && Character "D"
pc_barchar[15] = wb+ns+nb+ns+wb+ws+nb+ns+nb           && Character "E"
pc_barchar[16] = nb+ns+wb+ns+wb+ws+nb+ns+nb           && Character "F"
pc_barchar[17] = nb+ns+nb+ns+nb+ws+wb+ns+wb           && Character "G"
pc_barchar[18] = wb+ns+nb+ns+nb+ws+wb+ns+nb           && Character "H"
pc_barchar[19] = nb+ns+wb+ns+nb+ws+wb+ns+nb           && Character "I"
pc_barchar[20] = nb+ns+nb+ns+wb+ws+wb+ns+nb           && Character "J"
pc_barchar[21] = wb+ns+nb+ns+nb+ns+nb+ws+wb           && Character "K"
pc_barchar[22] = nb+ns+wb+ns+nb+ns+nb+ws+wb           && Character "L"
pc_barchar[23] = wb+ns+wb+ns+nb+ns+nb+ws+nb           && Character "M"
pc_barchar[24] = nb+ns+nb+ns+wb+ns+nb+ws+wb           && Character "N"
pc_barchar[25] = wb+ns+nb+ns+wb+ns+nb+ws+nb           && Character "O"
pc_barchar[26] = nb+ns+wb+ns+wb+ns+nb+ws+nb           && Character "P"
pc_barchar[27] = nb+ns+nb+ns+nb+ns+wb+ws+wb           && Character "Q"
pc_barchar[28] = wb+ns+nb+ns+nb+ns+wb+ws+nb           && Character "R"
pc_barchar[29] = nb+ns+wb+ns+nb+ns+wb+ws+nb           && Character "S"
pc_barchar[30] = nb+ns+nb+ns+wb+ns+wb+ws+nb           && Character "T"
pc_barchar[31] = wb+ws+nb+ns+nb+ns+nb+ns+wb           && Character "U"
pc_barchar[32] = nb+ws+wb+ns+nb+ns+nb+ns+wb           && Character "V"
pc_barchar[33] = wb+ws+wb+ns+nb+ns+nb+ns+nb           && Character "W"
pc_barchar[34] = nb+ws+nb+ns+wb+ns+nb+ns+wb           && Character "X"
pc_barchar[35] = wb+ws+nb+ns+wb+ns+nb+ns+nb           && Character "Y"
pc_barchar[36] = nb+ws+wb+ns+wb+ns+nb+ns+nb           && Character "Z"
pc_barchar[37] = nb+ws+nb+ns+nb+ns+wb+ns+wb           && Character "-"
pc_barchar[38] = wb+ws+nb+ns+nb+ns+wb+ns+nb           && Character "."
pc_barchar[39] = nb+ws+wb+ns+nb+ns+wb+ns+nb           && Character " "
pc_barchar[40] = nb+ws+nb+ns+wb+ns+wb+ns+nb           && Character "*"
pc_barchar[41] = nb+ws+nb+ws+nb+ws+nb+ns+nb           && Character "$"
pc_barchar[42] = nb+ws+nb+ws+nb+ns+nb+ws+nb           && Character "/"
pc_barchar[43] = nb+ws+nb+ns+nb+ws+nb+ws+nb           && Character "+"
pc_barchar[44] = nb+ns+nb+ws+nb+ws+nb+ws+nb           && Character "%"


***********************************************************************
* PROCEDURE: lpBlKprt
* ABSTRACT: blank out printer variables
***********************************************************************
PROCEDURE lpBlKprt

STORE "" TO pc_f10, pc_f10B,pc_f12,pc_f12B,pc_f14,pc_f14B,pc_f18,pc_f18B,;
	_PBigBold,_PRegBold,_PReg,_PBold,_PPt6,_PPt8,_PPt9,_PPt10,_PPt11,_PPt12,;
	_PPt14,_PPt18,_PPt24,_PPt30,_PPt36,_PPt42,_PPt48,_PPt54,_PPt60,_PPt72,;
	_PNormal,_PItalic,_PCourier,_PUnivers,_PHelv,cpi8,cpi10,cpi12,c_landscap,;
	c_portrait,c_titlegr,c_endgr,c_MakeSmal,c_MakeBig,c_title10,c_title14,;
	c_title8,c_bigbold,c_regbold,c_reg
