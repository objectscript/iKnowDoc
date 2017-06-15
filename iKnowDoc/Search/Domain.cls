Include %IKInclude

Class iKnowDoc.Search.Domain Extends %Persistent
{

/// Similar entity search method. Returns JSON-object containing 10 entities similar to input string.
ClassMethod GetSimilar(SearchString) As %Status
{
	try {
		// Opening iKnow domain and getting his Id
		set domId= ##class(iKnowDoc.Search.Domain).GetIdDomain()
		// Using %iKnow we get 10 entities similar to input string
		set SC = ##class(%iKnow.Queries.EntityAPI).GetSimilar(.Result, domId, SearchString,,10)
		// Forming a dynamic object
		set ResultJSON = { "entities": [] }
		// Getting data from Result array and pushing to the dynamic object
	    //zw Result
  	 	set Result(12) = $lb(999999," ",0,0)
	    for i=0:1:10 {
	    	set оrd = $order(Result(i),1,Data)
	    	//w "before ",$li(Data,2),!
	    	set string = ##class(iKnowDoc.Search.Parser).ParseHints($li(Data,2))
	    	//w "string ",string,!
	    	//set string =$li(Data,2)
	    	if $EXTRACT(string,$LENGTH(string))=";"{
	    		set string=$EXTRACT(string,1,($LENGTH(string)-1))
	    	}
	    	//set tJSON = { "value":(string) }
	    	set tJSON = { "value":($ZCONVERT(string,"I","HTML")) }
			do ResultJSON.entities.%Push(tJSON)
	    }    
	    // Converting dynamic object into JSON
	    write ResultJSON.%ToJSON()	
	} catch ex {
		set ResultJSON = { "entities": [] }
		write ResultJSON.%ToJSON()
	} 
	quit $$$OK
}

/// Getting iKnow domain Id method
ClassMethod GetIdDomain() As %Integer
{
	// Getting domain Id
	set dname="DocSearch" 
	set domoref=##class(%iKnow.Domain).Open(dname)
    quit domoref.Id
}

Storage Default
{
<Data name="DomainDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^iKnowDoc.Search.DomainD</DataLocation>
<DefaultData>DomainDefaultData</DefaultData>
<IdLocation>^iKnowDoc.Search.DomainD</IdLocation>
<IndexLocation>^iKnowDoc.Search.DomainI</IndexLocation>
<StreamLocation>^iKnowDoc.Search.DomainS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}
