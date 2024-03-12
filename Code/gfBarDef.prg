PROCEDURE gfBarDef
** 03/23/01 DMA
** Defines Code39 bar codes as HP PCL5 strings for printing
**   and stores them in public array pc_barchar
** Based on former library routines Def_Code and SetLaser
**  Called by Printbar, Barcode, Prntbar2

PARAMETERS n_narrow, n_barhi

* n_narrow: dimension for a narrow bar or space
* n_barhi: dimension for height of bar
* pc_dpl: PUBLIC constant -- number of dots/line

PRIVATE n_wide, nb, wb, ns, ws, c_wide, c_high

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
RETURN
