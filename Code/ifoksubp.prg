**Function IfOkSubp
LOCAL l_oksub as Boolean
l_oksub=.t.
IF NOT pl_ofcOak
IF NOT EMPTY(pc_Court1) AND NOT EMPTY(pc_isstype)


IF nonotice( pc_area, pc_Litcode, pc_Court1, IIF(ALLTRIM(pc_isstype)="S","7","8"), .F.)
	GFMESSAGE( "Cannot issue as a subpoena. The Notices are not set for that litigation/area combination. Check with Business Development or IT dept." )	
	l_oksub=.f.	
		
ENDIF
ENDIF
endif
RETURN l_oksub
