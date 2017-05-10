Include %IKInclude
Class Search.Rank {

ClassMethod Frequency(domainid As %Integer, sourceidlist As %List, wordidlist As %List) As %Float
{
	/*w "wordidlistR ",wordidlist,!
	zw wordidlist*/
	zn "docbook"
	set numerator = ..GetCountOneBySource(domainid,sourceidlist,wordidlist)
	set denominator = ##class(%iKnow.Queries.EntityAPI).GetOccurrenceCountBySource(domainid,sourceidlist)
	zn "docsearch"
	//w numerator,!,denominator,!
	set frequency=numerator/denominator
	q frequency
}

ClassMethod GetCountOneBySource(domainid As %Integer, sourceidlist As %List, wordidlist As %List, Output sc As %Status = {$$$OK}, enttype As %Integer = {$$$ENTTYPEANY}) As %Integer
{
	$$$IKQBEGINR("",sc,-1)
	if (domainid'=0) { $$$CHECKDOMAINEXISTSR(domainid,sc,-1) }
	quit:sourceidlist="" 0
	
	set tVersionTables = $$$IKVERSIONATLEAST(domainid,$$$IKVERSIONTABLES)
	
	// accepting single source IDs (non-list) as well
	$$$IKENSURELISTNUM(sourceidlist)
	
	set total = 0, ptr = 0
	while $listnext(sourceidlist, ptr, srcId) {
		continue:'+srcId
		$$$CHECKASRCIDEXISTSX(domainid,srcId,srcDetails,vSrcId,sc)
		
		if (enttype = $$$ENTTYPEANY) && 'tVersionTables {
			set total = total + $lg(srcDetails,4)
		} else {
			
			set gEntOccId = $$$IKVGLOBNAME(domainid,"EntOccId",vSrcId)
			set tFrom = $lg(srcDetails,3)+1, tTo = tFrom+$lg(srcDetails,4)-1
			for tPartId = tFrom:1:tTo {
				set tEntOcc = @gEntOccId@(tPartId)
				set pointer = 0
				set value = 0
				while $listnext(wordidlist, pointer, value)
				{
					//w "value		", value,!
					//w "$lg(tEntOcc,1) 	",$lg(tEntOcc,1),!
					if value=$lg(tEntOcc,1)
					{
						s x = $i(total)
					}	
				}
				//set tEntType = $lg(tEntOcc,2)
				//continue:tEntType=$$$ENTTYPENONREL
				//set:(enttype=$$$ENTTYPEANY)||(enttype=tEntType) x = $i(total)
			}
		}
	}
	quit:$$$ISERR(sc) -1
	
	quit total
}

ClassMethod Replace(domainid As %Integer, entitylist As %List, pagesize As %Integer) As %Library.ArrayOfObjects
{
	zn "docbook"
	//set tSC = ##class(%iKnow.Queries.SourceAPI).GetByEntities(.tResult,9, $LB("iFind"),1,50)
	set tSC = ##class(%iKnow.Queries.SourceAPI).GetByEntities(.tResult,domainid, entitylist,1,pagesize)
	 /*
	 tResult(1)=$lb(167666,":SQL:170615:170615")
	 tResult(2)=$lb(166526,":SQL:169471:169471")
	 tResult(3)=$lb(166488,":SQL:169433:169433")
	 tResult(4)=$lb(166478,":SQL:169427:169427")
	 tResult(5)=$lb(166311,":SQL:169259:169259")
	 tResult(6)=$lb(166287,":SQL:169238:169238")
	 tResult(7)=$lb(166213,":SQL:169157:169157")
	 tResult(8)=$lb(166061,":SQL:169013:169013")
	 tResult(9)=$lb(166055,":SQL:169004:169004")
	 tResult(10)=$lb(114725,":SQL:117529:117529")
	 */
	zn "docsearch" 
	 
	set array = ##class(%Library.ArrayOfObjects).%New()
	
	set i = ""
    for {
	    set i = $order(tResult(i),1,tSrcData)
	    quit:i=""	
		set string=$lg(tSrcData,2)
		
		
		set nul=$FIND(string,":",1)-1 
		set from=$FIND(string,":",nul+1)-1
		//w "from ",from,!
	 
		set to=$FIND(string,":",from+1)-1
		
		//w "to ",to,!
		
		// sql 
		set substr=$EXTRACT(string,from+1,to-1)
		// source
		set first = $lg(tSrcData,1)
		//w "first 	",first,!
		//w "substr 	",substr,!
		
		set array(i,0)=substr
		set array(i,1)=first
	}
	zw array
	q array
}

}