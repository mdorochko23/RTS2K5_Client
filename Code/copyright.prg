LOCAL slnCurArea,slcText,slcCurYear,slcStartYear,slnAreaHeight,slnAreaTop,;
  slnGap

* Display the product name.
IF TYPE('_SCREEN.lblProduct') <> 'O'
  _SCREEN.ADDOBJECT('lblProduct','label')
ENDIF
_SCREEN.lblProduct.BACKSTYLE = 0
_SCREEN.lblProduct.FONTBOLD = .T.
_SCREEN.lblProduct.FONTNAME = 'Arial'
_SCREEN.lblProduct.FONTSIZE = 9
IF TYPE('g_oapp') = 'O'
  lccaption = g_oapp.ra_cappname
ELSE
  lccaption ="Record Tracking System (RTS)"

ENDIF
_SCREEN.lblProduct.CAPTION = ALLT(lccaption)
=LabelWidth(_SCREEN.lblProduct)
_SCREEN.lblProduct.LEFT = (_SCREEN.WIDTH-_SCREEN.lblProduct.WIDTH)/2

**01/25/2010 EF - use slcCurYear to display an end year of a copy right

IF TYPE('g_oapp') = 'O' AND !EMPTY(g_oapp.ra_cbuilddate)
  slcCurYear = ALLTRIM(STR(YEAR(CTOD(g_oapp.ra_cbuilddate))))
ELSE
  slcCurYear = ALLTRIM(STR(YEAR(DATE())))
ENDIF
slcText = slcCurYear
slcText="1988-" + slcCurYear
IF TYPE('_SCREEN.lblCopyright') <> 'O'
  _SCREEN.ADDOBJECT('lblCopyright','label')
ENDIF
_SCREEN.lblCopyright.BACKSTYLE = 0
_SCREEN.lblCopyright.FONTBOLD = .T.
_SCREEN.lblCopyright.FONTNAME = 'Arial'
_SCREEN.lblCopyright.FONTSIZE = 9
IF TYPE('g_oapp') = 'O'
  lccaption = g_oapp.ra_cCopyRight1
ELSE
  lccaption = 'RecordTrak, Inc.'
ENDIF
*_SCREEN.lblCopyright.CAPTION = 'Copyright © '+ slcText + ' by ' + ALLT(lccaption)
_SCREEN.lblCopyright.CAPTION = 'Copyright © '+ slcText + ' ' + ALLT(lccaption)
= LabelWidth(_SCREEN.lblCopyright)
_SCREEN.lblCopyright.LEFT = (_SCREEN.WIDTH-_SCREEN.lblCopyright.WIDTH)/2

* Display the company name.
IF TYPE('_SCREEN.lblCompany') <> 'O'
  _SCREEN.ADDOBJECT('lblCompany','label')
ENDIF
_SCREEN.lblCompany.BACKSTYLE = 0
_SCREEN.lblCompany.FONTBOLD = .T.
_SCREEN.lblCompany.FONTNAME = 'Arial'
_SCREEN.lblCompany.FONTSIZE = 9
IF TYPE('g_oapp') = 'O'
  lccaption = g_oapp.ra_cCopyRight2
ELSE
  lccaption = 'All rights reserved.'
ENDIF

_SCREEN.lblCompany.CAPTION = ALLT(lccaption)
= LabelWidth(_SCREEN.lblCompany)
_SCREEN.lblCompany.LEFT = (_SCREEN.WIDTH-_SCREEN.lblCompany.WIDTH)/2

* Position the labels vertically.  They will be displayed halfway between
* the bottom of the logo object and the bottom of the application window.
* If there is no logo object, the labels will be displayed in the center
* of the bottom half of the application window.
IF TYPE('_SCREEN.imgLogo') = 'O'
   slnAreaTop = _SCREEN.imgLogo.Top+_SCREEN.imgLogo.Height
ELSE
***************************1.2
slnAreaTop = INT(_SCREEN.HEIGHT/1.5)
ENDIF
slnAreaHeight = _SCREEN.HEIGHT-(slnAreaTop+15)
slnGap = INT(_SCREEN.lblProduct.HEIGHT/12)
_SCREEN.lblProduct.TOP = slnAreaTop+INT((slnAreaHeight-;
_SCREEN.lblProduct.HEIGHT -_SCREEN.lblCopyright.HEIGHT-;
  slnGap*2)/2)
_SCREEN.lblCopyright.TOP = _SCREEN.lblProduct.TOP+_SCREEN.lblProduct.HEIGHT+;
  slnGap
_SCREEN.lblCompany.TOP = _SCREEN.lblProduct.TOP+_SCREEN.lblProduct.HEIGHT+;
  _SCREEN.lblCopyright.HEIGHT+slnGap*2
_SCREEN.lblProduct.VISIBLE = .T.
_SCREEN.lblCopyright.VISIBLE = .T.
_SCREEN.lblCompany.VISIBLE = .T.


*******************
FUNCTION LabelWidth
  *******************
  * Change the width of the label control based on the current value in the
  * Caption property.

  LPARAM stoLabel

  LOCAL slcFontStyle

  slcFontStyle = ''
  IF stoLabel.FONTBOLD
    slcFontStyle = slcFontStyle+'B'
  ENDIF
  IF stoLabel.FONTITALIC
    slcFontStyle = slcFontStyle+'I'
  ENDIF
  IF stoLabel.FONTOUTLINE
    slcFontStyle = slcFontStyle+'O'
  ENDIF
  IF stoLabel.FONTSHADOW
    slcFontStyle = slcFontStyle+'S'
  ENDIF
  IF stoLabel.FONTSTRIKETHRU
    slcFontStyle = slcFontStyle+'-'
  ENDIF
  IF stoLabel.FONTUNDERLINE
    slcFontStyle = slcFontStyle+'U'
  ENDIF
  IF stoLabel.BACKSTYLE = 1
    slcFontStyle = slcFontStyle+'Q'
  ELSE
    slcFontStyle = slcFontStyle+'T'
  ENDIF

  stoLabel.WIDTH = ROUND(TXTWIDTH(RTRIM(stoLabel.CAPTION),;
    stoLabel.FONTNAME,stoLabel.FONTSIZE,slcFontStyle)*;
    FONTMETRIC(6,stoLabel.FONTNAME,stoLabel.FONTSIZE,slcFontStyle)+.49,0)
