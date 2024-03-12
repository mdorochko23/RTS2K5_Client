*** Encrypt (when used with Decrypt.PRG) provides the security for a
*** password for the System Admin Menu.  This encryption will currently
*** be a very simple for explained in the following:
***
*** Encrypt.PRG will be called as follows: Encrypt(password)
*** It will return the encrypted password string.  The encrypted
*** password string will be the same length as the string passed.
*** The encryption algorithm will be downright simple.(since the
*** password facility is only meant to keep casual users of the 
*** system from being able to access the System Admin functions)
***
*** The encryption algorithm is as follows:
***
***	For each character in the string do
***		temp = asc(upper(password[i]))		&& get the ascii value (only uppercase)
***		temp = temp + 20 + i				&& add 20 + i to the value
***		retstring[i] = chr(temp)			&& the return string = the chr value of the temp variable
*** LOOP until done
***
*****************************************************************************************************

lParameter Password
local i, RetString

RetString = ""

If len(PASSWORD) > 0
	For i = 1 to Len(Password)
		RetString = RetString + CHR(ASC(Upper(SubStr(Password, i, 1))) + 20 + i)
	EndFor
EndIf

Return RetString