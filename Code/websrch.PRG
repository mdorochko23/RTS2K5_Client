* tnLeft is the horizontal position where I want the 
* menu to appear, relative to the outer window.
* tnTop is the equivalent vertical position. Both
* are in pixels.

PARAMETERS OREF
tnLeft=250
tnTop=250

* Convert pixels to foxels.
lnFoxLeft = tnLeft / (_screen.Width / WCOLS())
lnFoxTop = tnTop /  (_screen.Height / WROWS())
* Display the menu
DEFINE POPUP shortcut SHORTCUT FROM lnFoxTop, lnFoxLeft 
*DEFINE POPUP shortcut SHORTCUT RELATIVE FROM MROW(),MCOL()
DEFINE BAR 1 OF shortcut PROMPT "Search Google"
DEFINE BAR 2 OF shortcut PROMPT "Search 411"
DEFINE BAR 3 OF shortcut PROMPT "Search NPPES"
DEFINE BAR 4 OF shortcut PROMPT "\-"
DEFINE BAR 5 OF shortcut PROMPT "Cancel"
ON SELECTION BAR 1 OF shortcut oref.rolosrch="G"
ON SELECTION BAR 2 OF shortcut oref.rolosrch="R"
ON SELECTION BAR 3 OF shortcut oref.rolosrch="N"
ON SELECTION BAR 5 OF shortcut oref.rolosrch=""

ACTIVATE POPUP shortcut


