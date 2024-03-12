********************************************************
* Enabled
********************************************************
*-- Access
This.Enabled = F_InputEnabledAccess(This) 

RETURN THIS.Enabled


*-- Assign
LPARAMETERS tbEnabled

WITH This
	.Enabled = F_InputEnabledAssign (tbEnabled, .ObjectId) 
EndWith


********************************************************
* Visible
********************************************************
*-- Access
This.Visible = F_InputVisibleAccess(This) 

RETURN THIS.Visible


*-- Assign
LPARAMETERS tbVisible

WITH This
	.Visible = F_InputVisibleAssign (tbVisible, .ObjectId) 
EndWith


********************************************************
* ReadOnly
********************************************************
*-- Access
This.ReadOnly = F_InputReadOnlyAccess(This) 

RETURN THIS.ReadOnly


*-- Assign
LPARAMETERS tbReadOnly

WITH This
	.ReadOnly = F_InputReadOnlyAssign (tbReadOnly, .ObjectId) 
EndWith


