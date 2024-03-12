LPARAMETERS psOldClassLib AS String, psNewClassLib AS String

CLOSE all
COPY FILE (psOldClassLib + ".vc?") TO (psNewClassLib + ".vc?")

USE (psNewClassLib + ".vcx") IN 0 EXCLUSIVE


*UPDATE (psNewClassLib) SET 
Replace All objname 		With  STRTRAN(UPPER(objname), 		UPPER(psOldClassLib), 	UPPER(psNewClassLib))  	IN (psNewClassLib)
Replace All Properties 	With  STRTRAN(UPPER(properties), 	UPPER(psOldClassLib), 	UPPER(psNewClassLib))  	IN (psNewClassLib)
Replace All Methods 		With  STRTRAN(Methods, 						psOldClassLib, 					psNewClassLib)  				IN (psNewClassLib)
Replace All ClassLoc 		With  STRTRAN(UPPER(ClassLoc), 		UPPER(psOldClassLib), 	UPPER(psNewClassLib))  	IN (psNewClassLib)
Replace All Parent 			With  STRTRAN(UPPER(Parent), 		UPPER(psOldClassLib), 	UPPER(psNewClassLib))  	IN (psNewClassLib)
Replace All Class 			With  STRTRAN(UPPER(Class), 			UPPER(psOldClassLib), 	UPPER(psNewClassLib)) IN (psNewClassLib)

close all


COMPILE CLASSLIB (psNewClassLib + ".vcx")