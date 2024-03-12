** Getcount.prg - Function prompts user with a count and allows user to
**                change the count.

** 9/16/2003 HN Initial release

parameters LnCount

define window GetCount from 1,1 size 6,35 title "Label Count" double;
	footer " 0 = No label "
move window GetCount Center

activate window GetCount

@ 2,3 say "Enter Label Count: " get lnCount picture "99"
read

release window GetCount
return lnCount
