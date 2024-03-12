*--Eservice order/ds job processing

LPARAMETERS c_atcode,n_lrsno,n_tag,c_action
LOCAL omedES AS Object
*--no orders/shipment row added for ES non-ordering attorney so just post viewing job
omedES=CREATEOBJECT('medgeneric')

c_sql="exec dbo.esjob "+ALLTRIM(STR(n_lrsno))+","+ALLTRIM(STR(n_tag))+;
	",'&C_atcode.','&pc_userid.','&c_action.'"
omedES.sqlexecute(c_sql)
RELEASE omedES

