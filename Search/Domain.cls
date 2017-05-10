Class Search.Domain extends %Persistent {
// Неоходимо запустить следующей командой на выполнение(сильно грузит комьютер, рекомендуется закрыть остальные программы)
// do ##class(Search.Domain).%Build()
// Выполняется минут 5-10
// После создания домена, проверить командой и найти название домена в выведенном списке
// do $system.iKnow.ListDomains()
/// Метод создания домена, построения структуры домена и заполнения его данными

ClassMethod %Build() As %Status
{
	#Include %IKPublic
	znspace "DOCBOOK"
	// Создание домена или открытие
	set dname="DocSearch"  
   	if (##class(%iKnow.Domain).Exists(dname)){
	   	set domoref=##class(%iKnow.Domain).Open(dname)
    }
  	else {	 
  		write "The ",dname," domain does not exist",!
       	set domoref=##class(%iKnow.Domain).%New(dname)
       	do domoref.%Save()
    }	
   	//Иницилизация листера и лоадера
   	set domId=domoref.Id
  	set flister=##class(%iKnow.Source.SQL.Lister).%New(domId)
  	set myloader=##class(%iKnow.Source.Loader).%New(domId)
  	// Построение запроса
	set myquery="SELECT id,content, blockid, component->blockid As component_blockid, component->title As component_title, book->blockid As book_blockid, book->title As book_title FROM DocBook.block"
 	set idfld="id"
 	set grpfld="id" // TODO: Посмотреть как лучше
  	set dataflds=$LB("content")
  	set metaflds=$LB("id","blockid","component_blockid","component_title","book_blockid","book_title")
  	//Метаданные
	set val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"id",$LB("="),$$$MDDTNUMBER)
	set val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"blockid",$LB("="),$$$MDDTSTRING)
	set val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"component_blockid",$LB("="),$$$MDDTSTRING)
	set val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"component_title",$LB("="),$$$MDDTSTRING)
	set val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"book_blockid",$LB("="),$$$MDDTSTRING)
	set val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"book_title",$LB("="),$$$MDDTSTRING)
  	// Запуск листера
  	set stat=flister.AddListToBatch(myquery,idfld,grpfld,dataflds,metaflds)
      if stat '= 1 {write "The lister failed: ",$System.Status.DisplayError(stat) quit }
    // Запуск загрузчика
    set stat=myloader.ProcessBatch()
      if stat '= 1 {
	      quit 
	       }
   //Функционал
    set numSrcD=##class(%iKnow.Queries.SourceQAPI).GetCountByDomain(domId)
  	write "The domain contains ",numSrcD," sources",!
  	set numSentD=##class(%iKnow.Queries.SentenceQAPI).GetCountByDomain(domId)
  	write "These sources contain ",numSentD," sentences",!!
    znspace "DOCSEARCH" 
  	set st = $$$OK
  	quit st
}
//
/// Метод поиска подобных сущностей. Возвращает строку слов, разделенных запятой.
ClassMethod GetSimilar(SearchString) As %Status
{
	znspace "DOCBOOK"
	set dname="DocSearch" 
	set domoref=##class(%iKnow.Domain).Open(dname)
	set domId=domoref.Id
	set resultArray = ##class(%DynamicArray).%New()
	set resultArray={}
	set SC = ##class(%iKnow.Queries.EntityAPI).GetSimilar(.Result, domId, SearchString)
	znspace "DOCSEARCH"
	quit:$$$ISERR(SC) ""

	set ResultJSON = { "entities": [] }
    for i=1:1:10 {
    	set оrd = $order(Result(i),1,Data)
    	set tJSON = { "value":(##class(Search.Parser).Parse($li(Data,2))) }
		do ResultJSON.entities.%Push(tJSON)
    }
    set st=$$$OK
    
	quit ##class(Search.SearchPages).%ProcessResult(st, $g(ResultJSON))
}
/*
Вставить следующие строки в область DOCBOOK, в класс DocBook.block перед компиляцией
/// Создание базового индекса iFind
Index contentInd On (content) As %iFind.Index.Basic(INDEXOPTION = 0, LOWER = 1, RANKERCLASS = 1);
*/
/// Получение информации и ссылки по тексту для поиска
ClassMethod SearchByText(text) As %Status
{
	//Создадим временную таблицу для хранения результатов поиска
	set createquery = "CREATE TABLE temptable (idSQL INT,content VARCHAR(30000),link VARCHAR(10000),	frequency FLOAT,title VARCHAR(10000))"
  	set createStatement = ##class(%SQL.Statement).%New()
  	set createStatus = createStatement.%Prepare(createquery)
   	if createStatus'=1 {write "%Prepare failed:" do $System.Status.DisplayError(createStatus) quit}
  	set createRset = createStatement.%Execute()
	znspace "DOCBOOK"
	// Выполняем поиск слова с помощью iFind в DocBook.block
	set tempArray = ##class(%ArrayOfDataTypes).%New()
	set count = 0
	set myquery = "SELECT id,content, component->blockid As link,book->title As title FROM DocBook.block WHERE %ID %FIND search_index(contentInd,?,0)"	
	//set myquery = "SELECT id,content, component->blockid As link,book->title As title FROM DocBook.block WHERE %ID %FIND search_index(contentInd,'"_text_"',0)"
  	/*
  	set tStatement = ##class(%SQL.Statement).%New()
  	set qStatus = tStatement.%Prepare(myquery)
   	if qStatus'=1 {write "%Prepare failed:" do $System.Status.DisplayError(qStatus) quit}
  	set rset = tStatement.%Execute()
  	while rset.%Next() {*/
  	set tStatement = ##class(%SQL.Statement).%New()
  	SET qStatus = tStatement.%Prepare(.myquery)
    IF qStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(qStatus) QUIT}
    SET rset = tStatement.%Execute(text)
  	//w myquery
  	
  	while rset.%Next() {
	  	znspace "DOCSEARCH"
	  	set tempArray(count,0)= rset.id
	  	set tempArray(count,1) = ##class(Search.Parser).Parse(rset.content)
    	set tempArray(count,2) = rset.link
    	set tempArray(count,3) = ##class(Search.Parser).Frequency(tempArray(count,1),text)
    	set tempArray(count,4) = ##class(Search.Parser).ParseTitle(rset.title)
    	set newquery ="insert into SQLUser.temptable(idSQL,content,link,frequency,title) VALUES(?,?,?,?,?)"
  		set rset2 = ##class(%SQL.Statement).%ExecDirect(,.newquery,tempArray(count,0),tempArray(count,1),tempArray(count,2),tempArray(count,3),tempArray(count,4))
    	if rset2.%SQLCODE'=0 {write !,"1st ExecDirect SQLCODE=",rset2.%SQLCODE,!,rset2.%Message  quit}
  		set count = count + 1
    	znspace "DOCBOOK"
       } 
    // Получаем данные с временной таблицы отсортированные по частоте
    znspace "DOCSEARCH"
	set count = count - 1
	//в портале - SELECT TOP 500 JSON_OBJECT('idSQL':id, 'content': {fn CONCAT(content,' ')}) FROM docbook.block WHERE %ID %FIND search_index(contentInd,'lower',0) 
	set resultQuery = "SELECT TOP 100 JSON_OBJECT('idSQL':idSQL, 'content': {fn CONCAT(content,' ')}, 'link':link, 'frequency':frequency, 'title':title) FROM SQLUser.temptable ORDER BY frequency DESC"
	//set resultQuery = "SELECT TOP 500 JSON_OBJECT('idSQL':idSQL, 'content':content, 'link':link, 'frequency':frequency, 'title':title) FROM SQLUser.temptable ORDER BY frequency DESC"
  	set Statement = ##class(%SQL.Statement).%New()
  	set Status = Statement.%Prepare(resultQuery)
   	if Status'=1 {write "%Prepare failed:" do $System.Status.DisplayError(Status) quit}
  	set result = Statement.%Execute()
   	//while result.%Next() {do result.%Print(" ^ ")}
  	set countZap=1
  	write "{""sources"":["
    while result.%Next() {
     do result.%Print(" ^ ")
     if ((countZap'=count)) {
     if (countZap=100) {quit}
      write ","
      set countZap=countZap+1 
     }
    }
    write "]}"
	//Удалим временную таблицу
    set dropquery = "drop table SQLUser.temptable"
  	set dropStatement = ##class(%SQL.Statement).%New()
  	set dropStatus = dropStatement.%Prepare(dropquery)
   	if dropStatus'=1 {write "%Prepare failed:" do $System.Status.DisplayError(dropStatus) quit}
  	set dropRset = dropStatement.%Execute()
	set st=$$$OK
	quit st
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

