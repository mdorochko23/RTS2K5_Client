
*PROCEDURE mapdrive
PARAMETERS c_path, n_mode
lcNetworkShare=c_path
ON ERROR Do errorhandlr WITH ERROR(),LINENO(),MESSAGE()

PRIVATE strDrive, strShare, WSHNetwork, strUser, strPwd, bUpdateProfile
WSHNetwork = CREATEOBJECT("WScript.Network")
colDrives = WSHNetwork.EnumNetworkDrives
strDrive ='Q:'
strShare = lcNetworkShare
strUser="access"
strPwd="recordtrak"
bUpdateProfile=.f.

IF n_mode=2
 WSHNetwork.RemoveNetworkDrive(strDrive,.t.,.t.)
endif
*!*	Note:  If drive letter is already mapped, or cannot find the path, it will throw first error
*WSHNetwork.MapNetworkDrive( strDrive, strShare)
WSHNetwork.MapNetworkDrive( strDrive, strShare,bUpdateProfile,strUser,strPwd)

RELEASE WSHNetwork
RETURN 

PROCEDURE errorhandlr
    LPARAMETERS nError, nLine, cmessage
    IF nError=1429  &&error mapping drive?
        DO CASE
            CASE "Network path was not found" $ cmessage  &&common error so handle it if you want
               * MESSAGEBOX( "Network path not found" )
               WSHNetwork.MapNetworkDrive( strDrive, strShare,bUpdateProfile,strUser,strPwd)
            CASE "Local device name is already in use" $ cmessage  &&common error so handle it if you want
              *  MESSAGEBOX( "Local device name is already in use - I am going to delete it!" )
                lforce = .T.  && force removal even if resource is in use
                lupdateprofile = .T.  && Update the profile
                WSHNetwork.RemoveNetworkDrive(strDrive,lforce,lupdateprofile)
            OTHERWISE
                MESSAGEBOX(MESSAGE())
        ENDCASE
    ENDIF
RETURN
    
	

