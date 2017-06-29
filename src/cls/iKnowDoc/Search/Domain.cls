Include %IKInclude

Class iKnowDoc.Search.Domain Extends %Persistent
{

/// Similar entity search method. Returns JSON-object containing 10 entities similar to input string.
ClassMethod GetSimilar(SearchString) As %Status
{
	try {
		if ($length(SearchString)>1) {
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
		    	//set string = ##class(iKnowDoc.Search.Parser).ParseHints($li(Data,2))
		    	//w "string ",string,!
		    	set string =$li(Data,2)
		    	if $EXTRACT(string,$LENGTH(string))=";"{
		    		set string=$EXTRACT(string,1,($LENGTH(string)-1))
		    	}
		    	//set tJSON = { "value":(string) }
		    	set tJSON = { "value":($ZCONVERT(string,"I","HTML")) }
				do ResultJSON.entities.%Push(tJSON)
				}
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

// Метод заполнения таблицы без HTML кода из DocBook.block

ClassMethod SelectInsert() As %Status
{
	set myquery = "SELECT component->blockid AS docKey, component->title AS title,book->blockid AS bookKey, book->title AS bookTitle, content, blockid FROM DocBook.block"
	set tStatement = ##class(%SQL.Statement).%New()
  	set qStatus = tStatement.%Prepare(myquery)
    IF qStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(qStatus) QUIT}
    set rset = tStatement.%Execute() 
    WHILE rset.%Next() {
       	set insertQuery = "INSERT INTO SQLUser.DocBook (docKey, title, bookKey, bookTitle, content, textKey) VALUES (?,?,?,?,?,?)"
     	set insertStatement = ##class(%SQL.Statement).%New()
     	set insertStatus = insertStatement.%Prepare(insertQuery)     	
     	IF insertStatus'=1 {WRITE "%Prepare insert failed :" DO $System.Status.DisplayError(insertStatus) QUIT}
     	set insertSet = insertStatement.%Execute(rset.docKey, ##class(%iKnow.Source.Converter.Html).StripHTML(rset.title), rset.bookKey, ##class(%iKnow.Source.Converter.Html).StripHTML(rset.bookTitle),##class(%iKnow.Source.Converter.Html).StripHTML(rset.content), rset.blockid )	
    }
}

// Создаем таблицу. Будет содержать текст для поиска после преобразования HTML символов

ClassMethod CreateTable() As %Status
{
	set myquery = "CREATE TABLE DocBook ( docKey VARCHAR(32000), title VARCHAR(32000), bookKey VARCHAR(32000), bookTitle VARCHAR(32000), content VARCHAR(32000), textKey VARCHAR(32000))"
	set tStatement = ##class(%SQL.Statement).%New()
  	set qStatus = tStatement.%Prepare(myquery)
    IF qStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(qStatus) QUIT}
    set rset = tStatement.%Execute()
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
