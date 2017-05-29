Include %IKInclude
Class Search.Domain extends %Persistent {
// Неоходимо запустить следующей командой на выполнение(сильно грузит комьютер, рекомендуется закрыть остальные программы)
// do ##class(Search.Domain).%Build()
// Выполняется минут 5-10
// После создания домена, проверить командой в области DOCBOOK и найти название домена в выведенном списке
// do $system.iKnow.ListDomains()
/// Метод создания домена, построения структуры домена и заполнения его данными
ClassMethod %Build() As %Status
{
	#Include %IKPublic
	// Создание домена или открытие если он существует
	set dname="DocSearch"  
   	if (##class(%iKnow.Domain).Exists(dname)){
	   	set domoref=##class(%iKnow.Domain).Open(dname)
    }
  	else {	 
  		write "The ",dname," domain does not exist",!
       	set domoref=##class(%iKnow.Domain).%New(dname)
       	do domoref.%Save()
    }	
   	set domId=domoref.Id
   	// Lister используется для поиска источников, соответствующих записям в результатах запроса
  	set flister=##class(%iKnow.Source.SQL.Lister).%New(domId)
  	//Loader координирует процесс загрузки.
  	set myloader=##class(%iKnow.Source.Loader).%New(domId)
  	// Построение запроса
	set myquery="SELECT id,content, blockid, component->blockid As component_blockid, component->title As component_title, book->blockid As book_blockid, book->title As book_title FROM DocBook.block"
 	set idfld="id"
 	set grpfld="id"
 	// Указываем поля данных и метаданных
  	set dataflds=$LB("content")
  	set metaflds=$LB("id","blockid","component_blockid","component_title","book_blockid","book_title")
  	//Метаданные
	set val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"id",$LB("="),$$$MDDTNUMBER)
	set val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"blockid",$LB("="),$$$MDDTSTRING)
	set val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"component_blockid",$LB("="),$$$MDDTSTRING)
	set val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"component_title",$LB("="),$$$MDDTSTRING)
	set val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"book_blockid",$LB("="),$$$MDDTSTRING)
	set val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"book_title",$LB("="),$$$MDDTSTRING)
  	//Занесем все данные в Lister
  	set stat=flister.AddListToBatch(myquery,idfld,grpfld,dataflds,metaflds)
      if stat '= 1 {write "The lister failed: ",$System.Status.DisplayError(stat) quit }
    //Запускаем процесс анализа
    set stat=myloader.ProcessBatch()
      if stat '= 1 {
	      quit 
	       }
   //Функционал
    set numSrcD=##class(%iKnow.Queries.SourceQAPI).GetCountByDomain(domId)
  	write "Домен создан",!
  	write "Домен содержит ",numSrcD," источников",! 
  	quit stat
}

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

