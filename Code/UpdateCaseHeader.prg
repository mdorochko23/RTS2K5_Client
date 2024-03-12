PROCEDURE UpdateCaseHeader
*
* When a change is made to a case's open/closed status,
* its ASB #, or any part of its plaintiff name, this routine is called to
* update all instances of forms and objects which display this information

LPARAMETERS c_CaseNumber
* c_CaseNumber contains the RT # of the case being updated

LOCAL c_class

FOR EACH o_Form IN _SCREEN.Forms

	* Processing for specific form classes
	IF TYPE( 'o_Form.Class') = 'C'
		c_Class = UPPER( o_Form.Class)
		
		DO CASE

			*-- If this is a Case Header form,
			*-- update the caption (which contains ASB #, open/closed status)
			CASE c_Class == "FRMCASE"
				IF o_Form.MedMaster.CaseNumber = c_CaseNumber THEN
					o_Form.UpdateCaption()
				ENDIF

			*-- If this is a Case Search & Selection form,
			*-- force a Refresh so that the case's grid row 
			*-- (which has ASB #, plaintiff name) is updated
			CASE c_Class == "FRMMASTERSEARCH"
				o_Form.cmdRefresh.Click()

		ENDCASE
	ENDIF
	
	* -- For all forms, including those which are not descended from
	* -- base/app classes, look for a CaseHeader object and update it.
	FOR EACH o_Control IN o_Form.Controls
		IF TYPE( 'o_Control.Class') = 'C'
			IF UPPER( o_Control.Class) == "CASEHEADER"
				* This IS a Case Header object. Is it for THIS case?
				IF o_Control.medMaster.CaseNumber = c_CaseNumber THEN
					* Yes, it's a full match. Update it and
					* get out of inner FOR loop completely
					o_Control.Refresh()
					EXIT
				ENDIF
			ENDIF
		ENDIF
	ENDFOR
ENDFOR
