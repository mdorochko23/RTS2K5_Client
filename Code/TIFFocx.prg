**PROCEDURE TIFFocx
LOCAL fso_qc AS OBJECT
fso_qc = CREATEOBJECT("Scripting.FileSystemObject")

IF NOT fso_qc.FileExists("C:\rts\TIFFMergeSplit.ocx")
	fso_qc.copyFile ("T:\release\vfp\rts\dlls\TIFFMergeSplit.ocx","C:\rts\TIFFMergeSplit.ocx" )
ENDIF

RELEASE fso_qc