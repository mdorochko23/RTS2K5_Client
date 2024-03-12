PROCEDURE UpdType
** EF 5/5/06 - Added to the VFP project.
**--------------------------------------------------------------------------
** 05/03/2005   DMA   Remove commented-out references to FilePath
** 06/08/2004   EF    Do not call Filepath ()
** 04/15/2004   EF    Upadte holdreq file when type of issues has been changed
** 12/30/2003   DMA   Catch error when invalid RT # is specified
** 12/17/2003   IZ    Call gfGetdat to determine Datadir depending on office parameter
** 03/16/2000   EF    Program updates Type field.
** 03/25/2002   DMA   Ensure correct datadir is picked per office.
** 06/13/2003  kdl  Assign initial value to sCl_Code
**  Called by AdmUtil
**  Calls Screen UpdType
**--------------------------------------------------------------------------

l_OK=goapp.OpenForm("generic.frmupdisstype", "M")
*do updtype.spr

if NOT l_OK
	return
ENDIF






