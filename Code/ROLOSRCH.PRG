* tnLeft is the horizontal position where I want the 
* menu to appear, relative to the outer window.
* tnTop is the equivalent vertical position. Both
* are in pixels.

**8/07/2018, SL, Zendesk #98746
**Removed the internet search options as they did not actually do anything anymore

PARAMETERS OREF
tnLeft=250
tnTop=250

* Convert pixels to foxels.
lnFoxLeft = tnLeft / (_screen.Width / WCOLS())
lnFoxTop = tnTop /  (_screen.Height / WROWS())
* Display the menu
DEFINE POPUP shortcut SHORTCUT FROM lnFoxTop, lnFoxLeft 

DEFINE BAR 1 OF shortcut PROMPT "Search Tags by Name and Blurb"
DEFINE BAR 2 OF shortcut PROMPT "Search Tags by Address"
DEFINE BAR 3 OF shortcut PROMPT "--------------------------------------"
DEFINE BAR 4 OF shortcut PROMPT "Search Rolodex Name"
DEFINE BAR 5 OF shortcut PROMPT "Search Rolodex Address"
DEFINE BAR 6 OF shortcut PROMPT "Search Rolodex City"
*DEFINE BAR 7 OF shortcut PROMPT "--------------------------------------"
*DEFINE BAR 8 OF shortcut PROMPT "Search Google"
*DEFINE BAR 9 OF shortcut PROMPT "Search 411"
*DEFINE BAR 10 OF shortcut PROMPT "Search NPPES"
*DEFINE BAR 11 OF shortcut PROMPT "\-"
*DEFINE BAR 12 OF shortcut PROMPT "Cancel"
DEFINE BAR 7 OF shortcut PROMPT "\-"
DEFINE BAR 8 OF shortcut PROMPT "Cancel"

ON SELECTION BAR 1 OF shortcut oref.rolosrch="B"
ON SELECTION BAR 2 OF shortcut oref.rolosrch="A"
ON SELECTION BAR 4 OF shortcut oref.rolosrch="D"
ON SELECTION BAR 5 OF shortcut oref.rolosrch="L"
ON SELECTION BAR 6 OF shortcut oref.rolosrch="C"
*ON SELECTION BAR 8 OF shortcut oref.rolosrch="G"
*ON SELECTION BAR 9 OF shortcut oref.rolosrch="R"
*ON SELECTION BAR 10 OF shortcut oref.rolosrch="N"
*ON SELECTION BAR 12 OF shortcut oref.rolosrch=""
ON SELECTION BAR 8 OF shortcut oref.rolosrch=""

ACTIVATE POPUP shortcut
