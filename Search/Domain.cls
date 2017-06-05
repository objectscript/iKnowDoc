Include %IKInclude
Class Search.Domain extends %Persistent {

/// Метод поиска подобных сущностей. Возвращает JSON содержащий 10 сущностей подобных входной строке.
ClassMethod GetSimilar(SearchString) As %Status
{
	try {
		// Открываем домен и получаем его Id
		set domId= ##class(Search.Domain).GetIdDomain()
		// Используя %iKnow получаем 10 сущностей подобных входной строке.
		set SC = ##class(%iKnow.Queries.EntityAPI).GetSimilar(.Result, domId, SearchString,,11)
		// Формируем динамический обьект
		set ResultJSON = { "entities": [] }
		// Получаем данные из Result и заполняем динамический обьект 
	    //zw Result
  	 	set Result(12) = $lb(999999," ",0,0)
	    for i=1:1:10 {
	    	set оrd = $order(Result(i),1,Data)
	    	//w "до ",$li(Data,2),!
	    	set string = ##class(Search.Parser).ParseHints($li(Data,2))
	    	//w "string ",string,!
	    	//set string =$li(Data,2)
	    	if $EXTRACT(string,$LENGTH(string))=";"{
	    		set string=$EXTRACT(string,1,($LENGTH(string)-1))
	    	}
	    	set tJSON = { "value":(string) }
			do ResultJSON.entities.%Push(tJSON)
	    }    
	    // Преобразуем динамический обьект в JSON
	    write ResultJSON.%ToJSON()	
	} catch ex {
		set ResultJSON = { "entities": [] }
		write ResultJSON.%ToJSON()
	} 
	quit $$$OK
}

// Метод получения id Домена
ClassMethod GetIdDomain() As %Integer
{
	
	// Получение id домена
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
<DataLocation>^Search.DomainD</DataLocation>
<DefaultData>DomainDefaultData</DefaultData>
<IdLocation>^Search.DomainD</IdLocation>
<IndexLocation>^Search.DomainI</IndexLocation>
<StreamLocation>^Search.DomainS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

