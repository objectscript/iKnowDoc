Class Search.Rank {

ClassMethod Ranking(SearchString As %String) As %Float
{
	set rank=0
	set wordArray = ##class(%ArrayOfDataTypes).%New()
	//смотрит одно ли слово в запросе или несколько
	set multiplewords = 0
	for i=1:1:$length(SearchString)
    	{
    		set chara = $EXTRACT(SearchString,i)
    		if (chara = " ")
    		{
    			set multiplewords = 1
    			quit
    		}
    	}
    if (multiplewords = 0) 
    { 
    set wordArray(1) = SearchString
    set wordArray(2) = ""
    set wordArray(3) = ""
    set wordArray(4) = ""
    set wordquantity = 1
    }
    else {
	set wordArray(1) = $PIECE(SearchString," ",1)
	set wordArray(2) = $PIECE(SearchString," ",2)
	set wordArray(3) = $PIECE(SearchString," ",3)
	set wordArray(4) = $PIECE(SearchString," ",4)
	set wordquantity = 4
	}
	set spaceArray = ##class(%ArrayOfDataTypes).%New()
	set wordCountArray = ##class(%ArrayOfDataTypes).%New()
	znspace "DOCBOOK"
	set tempArray = ##class(%ArrayOfDataTypes).%New()
	set counter = 1
	set myquery = "SELECT count(*) As cnt,content,component->blockid AS link FROM DocBook.block WHERE component->blockid='BXJV_globals'"
  	set tStatement = ##class(%SQL.Statement).%New()
  	set qStatus = tStatement.%Prepare(myquery)
   	IF qStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(qStatus) QUIT}
  	set rset = tStatement.%Execute()
  	WHILE rset.%Next() {
	  	ZNSPACE "DOCSEARCH"
	  	set tempArray(counter) = ##class(Search.Parser).Parse(rset.content)
    	set counter=counter+1
    	set rowcount = rset.cnt
  	}
  	write tempArray(1)
  	write rowcount,!
    for k=1:1:wordquantity
    { 
	 set word = wordArray(k)
	 if (word="") {quit}
	 set spaceArray(k)=0
  	 set wordCountArray(k)=0
	 set Wordlength=$length(word)
     for j=1:1:rowcount
      {	
      	set text=tempArray(j)
      	write "text: "_text,!
      	write "textlength: "_$length(text), !
    	for i=1:1:$length(text)-Wordlength
    	{
    		write "wordlength: "_Wordlength,!
	    	set substr=$EXTRACT(text,i,i+Wordlength-1)
	    	write "substring: "_substr,!
			set char = $EXTRACT(text,i)
			if (char=" ")
			{
				set spaceArray(k)=spaceArray(k)+1
				write "space count: "_spaceArray(k),!
			}
			if (substr=word)
			{ 
				set wordCountArray(k)=1+wordCountArray(k)
			}
    	}
      }
    }
    set rank0=0
    set rank1=0
    set rank2=0
    set rank3=0
    set rank0 =wordCountArray(1)/spaceArray(1)
    if (wordArray(2)'="")
    	{set rank1 =wordCountArray(2)/spaceArray(2)}
    if (wordArray(3)'="")
    	{set rank2=wordCountArray(3)/spaceArray(3)}
    if (wordArray(4)'="")
    	{set rank3 =wordCountArray(4)/spaceArray(4)}
    set rank=rank0+rank1+rank2+rank3
    write "rank0: "_rank0,!
    write "rank1: "_rank1,!
    write "rank2: "_rank2,!
    write "rank3: "_rank3,!
    write "final rank: "_rank,!
	set st=$$$OK
	quit rank
}

ClassMethod GetOccurrenceCountBySource(domainid As %Integer, sourceidlist As %List, Output sc As %Status = {$$$OK}, enttype As %Integer = {$$$ENTTYPEANY}) As %Integer
{
 $$$IKQBEGINR("",sc,-1)
 if (domainid'=0) { $$$CHECKDOMAINEXISTSR(domainid,sc,-1) }  //проверка существования домена
 quit:sourceidlist="" 0			//
 
 set tVersionTables = $$$IKVERSIONATLEAST(domainid,$$$IKVERSIONTABLES)   //проверка версии iknow
 
 // accepting single source IDs (non-list) as well
 $$$IKENSURELISTNUM(sourceidlist)
 
 set total = 0, ptr = 0		//total - число entities, ptr -
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
    set tEntType = $lg(tEntOcc,2)
    continue:tEntType=$$$ENTTYPENONREL
    set:(enttype=$$$ENTTYPEANY)||(enttype=tEntType) x = $i(total)
   }
  }
 }
 quit:$$$ISERR(sc) -1
 
 quit total
}

}