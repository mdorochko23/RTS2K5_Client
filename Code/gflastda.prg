** gfLastDay  - Returns the last day of the month

parameters ldDate

private nextmth,firstmth

nextmth = gomonth(ldDate,1)
Firstmth = ctod(tran(month(nextmth),"99")+"/01/"+tran(year(nextmth),"9999"))
return Firstmth - 1
