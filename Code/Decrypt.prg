*** Decrypt.PRG provides the security for a
*** password for the System Admin Menu.  This encryption will currently
*** be a very simple for explained in the following:
***
*** Decrypt.PRG will be called as follows: Decrypt(retstring)
*** It will return the decrypted password string.  The decrypted
*** password string will be the same length as the string passed.
*** The encryption algorithm is downright simple.(since the
*** password facility is only meant to keep casual users of the 
*** system from being able to access the System Admin functions)
***
*** The decryption algorithm is as follows:
***
***	For each character in the string do
***		temp = asc(upper(retstring[i]))		&& get the ascii value (only uppercase)
***		temp = temp - 20 - i				&& add 20 + i to the value
***		password[i] = chr(temp)				&& the return string = the chr value of the temp variable
*** LOOP until done
***
*****************************************************************************************************

lParameter RetString
Local i, Password, Width

Password= ""
i = 1
Do While (i < len(RetString)) .and. ASC(SubStr(RetString, i, 1)) != 32
	i = i + 1
EndDo
Width = i - 1

For i=1 to Width
	Password = Password + CHR(ASC(SubStr(RetString, i, 1)) - 20 - i)
EndFor

Return Password