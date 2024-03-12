** Addbs.prg - Adds a backslash to a directory path.

parameters lcString

if right(alltrim(lcString),1) <> "\"
	lcString = alltrim(lcString) + "\"
endif

return lcString

