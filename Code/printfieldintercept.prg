*#255675 WY 12/19/2021 resolve field selection for TX
*PrintFieldIntercept
*return a string value for the stream
PARAMETERS tcMergeFieldName, tcValue 

tcMergeFieldName = UPPER(ALLTRIM(tcMergeFieldName))
DO case
	CASE tcMergeFieldName == "PLAINTIFF" && merge field name is CasePlaintiff
		IF PL_TXCOURT
			DO CASE 
				CASE INLIST(pcTxHeaderMode, 1, 2)  
					RETURN tcValue
				case pcTxHeaderMode = 3
					RETURN ""
			ENDCASE 
		ELSE
			*not TX 
			RETURN tcValue 	
		ENDIF 
	CASE tcMergeFieldName == "UCPLAINTIFF" OR tcMergeFieldName == "UNDERCASEPLAINTIFF" && only for TX
		DO CASE 
			CASE pcTxHeaderMode = 1
				RETURN "Plaintiff(s),"
			case INLIST(pcTxHeaderMode, 2,3)
				RETURN "" 	
		ENDCASE 
	CASE tcMergeFieldName == "VER" && only for TX
		DO CASE 
			CASE pcTxHeaderMode = 1
				RETURN "v."
			case pcTxHeaderMode = 2
				RETURN "" 	
			CASE pcTxHeaderMode = 3
				RETURN tcValue
		ENDCASE 
	CASE tcMergeFieldName == "DEFENDANT" &&CaseDefendant		
		IF PL_TXCOURT
			DO CASE 
				CASE pcTxHeaderMode = 1   
					RETURN tcValue
				case INLIST(pcTxHeaderMode, 2,3)
					RETURN "" 	
			ENDCASE 
		ELSE 
			*not TX
			RETURN tcValue 	
		ENDIF 			
	CASE tcMergeFieldName == "UCDEF" OR tcMergeFieldName == "UNDERCASEDEF" && only for TX
		DO CASE 
			CASE pcTxHeaderMode = 1
				RETURN "Defendant(s)."
			case INLIST(pcTxHeaderMode, 2,3)
				RETURN "" 	
		ENDCASE 
	OTHERWISE
		* SET STEP ON 	11/18/2022 MD
ENDCASE
