*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴*
* Procedure...: Address
* Called by...: Employee Menu
*
* Abstract....: Called when changing address (35)
*
* Parameters..:
*
* Notes.......:
*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴*
procedure Address


private TYPE, SSNO, XCODE, GROUP, CATEGORY, EFFECTIVE, TERMINATED, FNAME, MI, LNAME, SUFFIX, ;
                DOB, POLICY, PERSONS, RELATION, SEX, M_STATUS, ADDRESS, ADDRESS1, CITY, STATE, ZIP, ;
                COB, STUDENT, FILLER, COB_EFFECT, COB_TERM, COB_POLICY, COB_FNAME, COB_MI, COB_LNAME, ;
                COB_C, COB_C_ADR1, COB_C_CITY, COB_C_ST, COB_C_ZIP, COB_GROUP, COB_CARIER, ;
                COMPANY, WAIVER, FILLER2, U_DATE, U_TIME, U_ID, NUMBER, FIRM_NO, DATE, SENT, REASON

private DependFlag, EMIS_ID, Action, Found

Action = 1
DependFlag = .F.
EMIS_ID    = .F.

Found = .F.

* - see if subscriber has any active GHI plans

wait window nowait "Searching for GHI plans..."
set order to Number in CARRIER
set order to Profile in PROFILE
set order to Key in PLANFILE
select PLAN
set order to Number
seek employee.Number
do while not eof()
        if plan.Number <> employee.Number
                exit
        endif
        if plan.Edate = {}
                =seek(plan.ClasCode, "CLASCODE")
                =seek(clascode.Key, "PLANFILE")
                =seek(planfile.Carrier, "CARRIER")
                if carrier.GHI = "Y"
                        m.Found = .T.
                        exit
                endif
                =seek(str(employee.Company,6)+str(plan.Clascode,6), "PROFILE")
        endif
        skip
enddo not eof()
select EMPLOYEE

* -

if !m.Found
        return
endif

if !opendbf("EMIS")
        return
endif


m.Type = 2
m.SSNO = left(employee.SSNO,3) + substr(employee.SSNO,5,2) + substr(employee.SSNO,8,4)
m.Xcode = 7
m.Group = group(plan.Clascode, plan.Sdate, employee.Prev_Cov, profile.GrpAnnDate)
m.Category = planfile.Cat_Med_NW
m.Waiver = CovCredit(employee.Effective, employee.Prev_Cov)
m.Effective     = max(employee.Effective, fixdate(date()))
m.Fname = upper(employee.Fname)
m.MI = upper(employee.MI)
m.Lname = upper(employee.Lname)
m.Suffix = upper(employee.Suffix)
m.DOB = employee.DOB
m.Policy = planfile.GHI_Policy
if m.Policy = 'A' and employee.Sex = 2
   m.Policy = 'B'
endif
m.Persons = employee.Persons
m.Relation = employee.Sex
m.Sex = employee.Sex
m.M_Status = employee.M_Status
m.Address = upper(employee.Address)
m.Address1 = upper(employee.Address1)
m.City = upper(employee.City)
m.State = employee.State
m.Zip = employee.Zip
m.Student = .F.
m.Disabled = .F.
m.CarrierName = " "
m.Carrier = planfile.Carrier
m.COB_Fname = upper(employee.COB_Fname)
m.COB_MI = upper(employee.COB_MI)
m.COB_Lname = upper(employee.COB_Lname)
m.COB = .F.
m.COB_Effect = employee.COB_Effect
m.COB_Term = employee.COB_Term
m.COB_C = employee.COB_C
m.COB_C_Adr1 = employee.COB_C_Adr1
m.COB_C_City = employee.COB_C_City
m.COB_C_St = employee.COB_C_St
m.COB_C_Zip = employee.COB_C_Zip
m.COB_Carier = employee.COB_Carier
m.COB_Group = employee.COB_Group
m.COB_Policy = employee.COB_Policy
*m.COB_Relat	= employee.COB_Relat
m.Ok = 0

do EMIS.spr

* - clean-up
select EMIS
use
select EMPLOYEE
set order to Key in PLANFILE
return

*EOP Address

*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴*
* Function....: V_Ok
*
* Called by...: Ok button
*
* Abstract....: Process transmittal
*
* Returns.....: .T.
*
* Parameters..:
*
* Notes.......:
*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴*
function V_Ok

if m.Action = 1

        select SYSDATA                                                                  && Get current EMIS transmittal
		locate for UPPER(ALLTRIM(File)) == "EMISXMIT"
        select EMIS
        append blank
        replace emis.Type               with "2", ;
                        emis.SSNO               with m.SSNO ;
                        emis.Xmittal    with sysdata.Key

        do case
                case m.Xcode = 1
                        replace emis.Xcode with '010'
                case m.Xcode = 2
                        replace emis.Xcode with '015'
                case m.Xcode = 3
                        replace emis.Xcode with '020'
                case m.Xcode = 4
                        replace emis.Xcode with '022'
                case m.Xcode = 5
                        replace emis.Xcode with '025'
                case m.Xcode = 6
                        replace emis.Xcode with '030'
                case m.Xcode = 7
                        replace emis.Xcode with '035'
                case m.Xcode = 8
                        replace emis.Xcode with '040'
                case m.Xcode = 9
                        replace emis.Xcode with '045'
                case m.Xcode = 10
                        replace emis.Xcode with '050'
                case m.Xcode = 11
                        replace emis.Xcode with '055'
                otherwise
                        replace emis.Xcode with '   '
        endcase

        replace emis.Group              with m.Group, ;
                        emis.Category   with m.Category, ;
                        emis.Effective  with m.Effective, ;
                        emis.Terminated with m.Terminated
        replace emis.Fname              with m.Fname, ;
                        emis.MI                 with m.MI, ;
                        emis.Lname              with m.Lname, ;
                        emis.Suffix             with m.Suffix, ;
                        emis.DOB                with m.DOB, ;
                        emis.Policy             with m.Policy, ;
                        emis.Persons    with m.Persons, ;
                        emis.Relation   with str(m.Relation,1)
        replace emis.Sex                with iif(m.Sex = 1, "M", "F")
        replace emis.M_Status   with GetMS()
        replace emis.Address    with m.Address, ;
                        emis.Address1   with m.Address1, ;
                        emis.City               with m.City, ;
                        emis.State              with m.State, ;
                        emis.Zip                with m.Zip
        replace emis.U_Date             with date(), ;
                        emis.U_Time             with time(), ;
                        emis.U_ID               with m.User, ;
                        emis.Company    with '000' + str(employee.Company, 6), ;
                        emis.Number             with employee.Number, ;
                        emis.Firm_NO    with employee.Company, ;
                        emis.Date               with date(), ;
                        emis.Waiver             with m.Waiver
        replace emis.Carrier    with m.Carrier
        replace emis.COB        with iif(m.COB, 'Y', 'N')

        if employee.COB
                replace emis.COB_Effect with m.COB_Effect, ;
                                emis.COB_Term   with m.COB_Term, ;
                                emis.COB_Policy with m.COB_Policy, ;
                                emis.COB_Fname  with m.COB_Fname, ;
                                emis.COB_MI     with m.COB_MI, ;
                                emis.COB_Lname  with m.COB_Lname, ;
                                emis.COB_C      with m.COB_C, ;
                                emis.COB_C_Adr1 with m.COB_C_Adr1, ;
                                emis.COB_C_City with m.COB_C_City, ;
                                emis.COB_C_St   with m.COB_C_St, ;
                                emis.COB_C_Zip  with m.COB_C_Zip, ;
                                emis.COB_Group  with m.COB_Group
                           

				do case
					case m.COB_Carier = 1
						replace emis.COB_Carier with 'M' 
					case m.COB_Carier = 2
						replace emis.COB_Carier with 'C'
				
					otherwise
						replace emis.COB_Carier with ' '
				endcase

        endif


        if m.Disabled
                replace emis.Student with "D"
        else
                if m.Student
                        replace emis.Student with "Y"
                endif
        endif


        * -
        replace emis.ID with val(AutoKey("EMIS"))
        if m.EMIS_ID
                replace daily.EMIS_ID with emis.ID
        endif


        select EMPLOYEE
        wait window nowait "Transmittal created..."
        clear read
        return .T.

else                                                                                    && update

        if emis.Sent = {}
                select EMIS
                if deleted()
                        recall
                endif

                do case
                        case m.Xcode = 1
                                replace emis.Xcode with '010'
                        case m.Xcode = 2
                                replace emis.Xcode with '015'
                        case m.Xcode = 3
                                replace emis.Xcode with '020'
                        case m.Xcode = 4
                                replace emis.Xcode with '022'
                        case m.Xcode = 5
                                replace emis.Xcode with '025'
                        case m.Xcode = 6
                                replace emis.Xcode with '030'
                        case m.Xcode = 7
                                replace emis.Xcode with '035'
                        case m.Xcode = 8
                                replace emis.Xcode with '040'
                        case m.Xcode = 9
                                replace emis.Xcode with '045'
                        case m.Xcode = 10
                                replace emis.Xcode with '050'
                        case m.Xcode = 11
                                replace emis.Xcode with '055'
                        otherwise
                                replace emis.Xcode with '   '
                endcase

                replace emis.Group              with m.Group, ;
                                emis.Category   with m.Category, ;
                                emis.Effective  with m.Effective, ;
                                emis.Terminated with m.Terminated
                replace emis.Fname              with m.Fname, ;
                                emis.MI                 with m.MI, ;
                                emis.Lname              with m.Lname, ;
                                emis.Suffix             with m.Suffix, ;
                                emis.DOB                with m.DOB, ;
                                emis.Policy             with m.Policy, ;
                                emis.Persons    with m.Persons, ;
                                emis.Relation   with str(m.Relation,1)
                replace emis.Sex                with iif(m.Sex = 1, "M", "F"), ;
                                emis.M_Status   with GetMS(), ;
                                emis.Address    with m.Address, ;
                                emis.Address1   with m.Address1, ;
                                emis.City               with m.City, ;
                                emis.State              with m.State, ;
                                emis.Zip                with m.Zip
                replace emis.U_Date             with date(), ;
                                emis.U_Time             with time(), ;
                                emis.U_ID               with m.User, ;
                                emis.Company    with '000' + str(employee.Company, 6), ;
                                emis.Number             with employee.Number, ;
                                emis.Firm_NO    with employee.Company, ;
                                emis.Date               with date(), ;
                                emis.Waiver             with m.Waiver
                replace emis.Carrier    with m.Carrier
                replace emis.COB                with iif(m.COB, 'Y', 'N')

                if employee.COB
                        replace emis.COB_Effect with m.COB_Effect, ;
                                        emis.COB_Term   with m.COB_Term, ;
                                        emis.COB_Policy with m.COB_Policy, ;
                                        emis.COB_Fname  with m.COB_Fname, ;
                                        emis.COB_MI             with m.COB_MI, ;
                                        emis.COB_Lname  with m.COB_Lname, ;
                                        emis.COB_C              with m.COB_C, ;
                                        emis.COB_C_Adr1 with m.COB_C_Adr1, ;
                                        emis.COB_C_City with m.COB_C_City, ;
                                        emis.COB_C_St   with m.COB_C_St, ;
                                        emis.COB_C_Zip  with m.COB_C_Zip, ;
                                        emis.COB_Group  with m.COB_Group

                        *replace emis.COB_Carier with iif(m.COB_Carier = 1, 'M', 'C')
						do case
							case m.COB_Carier = 1
								replace emis.COB_Carier with 'M'
							case m.COB_Carier = 2
								replace emis.COB_Carier with 'C'
		
							otherwise
								replace emis.COB_Carier with ""
						endcase

                endif

                if m.Disabled
                        replace emis.Student with "D"
                else
                        if m.Student
                                replace emis.Student with "Y"
                        endif
                endif

                if EMIS_ID
                        replace daily.No_Send with .F.
                endif
                select EMPLOYEE
                wait window nowait "EMIS Transmittal re-submitted..."
        endif
        clear read
        return .T.
endif


*EOF V_Ok
