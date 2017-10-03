Include %IKInclude

Class iKnowDoc.Search.Domain Extends %Persistent
{

/// Similar entity search method. Returns JSON-object containing 10 entities similar to input string.
// Old version
/*ClassMethod GetSimilar(SearchString) As %Status
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
		    for i=1:1:10 {
		    	set оrd = $order(Result(i),1,Data)
		    	if $li(Result(i),2)>2 {
		    		if ($FIND($li(Data,2),"--")'=0) {
		    			set string =" "
		    		} elseif ($FIND($li(Data,2),"|")'=0) {
		    			set string =" "
		    		} elseif ($FIND($li(Data,2),"**")'=0) {
		    			set string =" "
		    		} elseif ($FIND($li(Data,2),"==")'=0) {
		    			set string =" "
		    		} else {
		    			set string =$li(Data,2)
		    		}
		    	} else {
		    		set string =" "
		    	}
		    	set string = ##class(iKnowDoc.Search.Parser).ParseHints(string)
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
}*/

ClassMethod GetSimilar(SearchString) As %Status
{
	try {
		set ResultJSON = { "entities": [] }
		if $Extract(SearchString,1)="$" {
			set myquery = "SELECT TOP 10 title as Word FROM COS where title Like '"_SearchString_"%'"  
			set tStatement = ##class(%SQL.Statement).%New()
		  	set qStatus = tStatement.%Prepare(.myquery)
		    IF qStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(qStatus) QUIT}
		    set rset = tStatement.%Execute()
		    while rset.%Next() {
		    	set word=rset.Word
		    	set tJSON = { "value":(rset.Word) }
				do ResultJSON.entities.%Push(tJSON)
				}
			} elseif ($length(SearchString)>1) {
				// Forming a dynamic object
				set ResultJSON = { "entities": [] }
				// Getting data from Result array and pushing to the dynamic object
			    //set myquery = "SELECT TOP 10 e.Word as Word, s.Spread FROM %iFind.FindWords('"_SearchString_"*') e JOIN User_DocBook.DocBook_contentInd_WordSpread s ON e.WordId= s.WordId ORDER BY Spread DESC"
			    set myquery = "SELECT TOP 10 e.Entity as Word, s.Spread FROM %iFind.FindEntities('"_SearchString_"*') e JOIN User_DocBook.DocBook_contentInd_EntSpread s ON e.EntityId = s.EntityId where s.Spread > 2 ORDER BY Spread DESC"
			    set tStatement = ##class(%SQL.Statement).%New()
			  	set qStatus = tStatement.%Prepare(.myquery)
			    IF qStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(qStatus) QUIT}
			    set rset = tStatement.%Execute() 
			    while rset.%Next() {
			    	set word=rset.Word
			    	//w rset.Word
			    	/*set string = ##class(iKnowDoc.Search.Parser).ParseHints(word)
		    	set tJSON = { "value":($ZCONVERT(string,"I","HTML")) }*/
			    	//set tJSON = { "value":($ZCONVERT(rset.Word,"I","HTML")) }
			    	set tJSON = { "value":(rset.Word) }
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

ClassMethod CreateTableCOS() As %Status
{
	set myquery = "CREATE TABLE COS (title VARCHAR(32000))"
	set tStatement = ##class(%SQL.Statement).%New()
  	set qStatus = tStatement.%Prepare(myquery)
    IF qStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(qStatus) QUIT}
    set rset = tStatement.%Execute()
    q $$$OK
}

// Дополняем функциями COS
ClassMethod AddFunctions() As %Status
{
	set myquery = "SELECT docKey, title FROM SQLUser.DocBook where docKey Like 'RCOS_f%' and docKey<>'RCOS_FUNCTIONS' group by title"
	set tStatement = ##class(%SQL.Statement).%New()
  	set qStatus = tStatement.%Prepare(myquery)
    IF qStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(qStatus) QUIT}
    set rset = tStatement.%Execute() 
    s con= 0
    WHILE rset.%Next() {
    	s con= con +1
    	if $Find(rset.title," AND ") '=0 {
    		s list = $LISTFROMSTRING(rset.title, " AND ") 
    		s word = $LIST(list,1)
    		s word2 = $LIST(list,2)
    		set insertQuery = "INSERT INTO SQLUser.COS (title) VALUES (?)"
    		set insertStatement = ##class(%SQL.Statement).%New()
    		set insertStatus = insertStatement.%Prepare(insertQuery)     	
    		IF insertStatus'=1 {WRITE "%Prepare insert failed :" DO $System.Status.DisplayError(insertStatus) QUIT}
    		set insertSet = insertStatement.%Execute(word2)
    	} elseif $Find(rset.title,"(LEGACY FUNCTION)")'=0 {
    		s word = $P(rset.title,"(LEGACY FUNCTION)")
    	} else  {
    		s word = rset.title
    	}
    	set insertQuery = "INSERT INTO SQLUser.COS (title) VALUES (?)"
     	set insertStatement = ##class(%SQL.Statement).%New()
     	set insertStatus = insertStatement.%Prepare(insertQuery)     	
     	IF insertStatus'=1 {WRITE "%Prepare insert failed :" DO $System.Status.DisplayError(insertStatus) QUIT}
     	set insertSet = insertStatement.%Execute(word)
       	
   }
   q $$$OK
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
