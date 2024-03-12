FUNCTION gfGetDat
************************************************************
* Returns Path for Datadir.dbf depending on office parameter
* Called by : RTS, Public, FilePath, Capsnot, Caupdtag,
*             Updtype, Printcov, Flook_pa, gfGetDir
* Also used by RTS Utility, gSynch, Spec1, Access, and CAUtils projects
* 06/08/04 EF Use new Datadir
* 12/17/03 IZ initial release
*************************************************************


RETURN "H:\release\rts\datadir\"
**MEI exe on 12/02/04(Ellen) RETURN "C:\release\datadir\"