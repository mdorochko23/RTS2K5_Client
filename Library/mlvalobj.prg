*:****************************************************************************
*:
*: PROCEDURE - MLVALOBJ
*:
*: Description: validates a object variable
*:
*: Parameters : p_oObj - <expO> Reqd - object to validate
*:
*: Return Val : Returns .T. or .F. if object is not currently
*:              instantiated
*:
*: Example    :
*:              IF MLValObj(l_oObj)
*:                l_oObj.show
*:              ENDIF
*:
*:****************************************************************************
Lparameters tObject, tsName

Local lbIsValidObject
lbIsValidObject = .F.

If Vartype(tObject) = "O"

	If Vartype(tsName) = "C"

		If pemstatus(tObject, tsName, 5)
			lbIsValidObject = Type([tObject.] +  tsName) = "O"
		Endif

	Else
		lbIsValidObject = !IsNull(tObject)
	Endif

Endif

Return lbIsValidObject

