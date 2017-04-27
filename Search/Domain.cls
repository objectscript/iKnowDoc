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
	
	ZNSPACE "DOCBOOK"
	
	// Создание домена или открытие
	SET dname="DocSearch"  
	 	
   	IF (##class(%iKnow.Domain).Exists(dname)){
	   	SET domoref=##class(%iKnow.Domain).Open(dname)
    }
  	ELSE {	 
  		WRITE "The ",dname," domain does not exist",!
       	SET domoref=##class(%iKnow.Domain).%New(dname)
       	DO domoref.%Save()
    }	
  
   	//Иницилизация листера и лоадера
   	SET domId=domoref.Id
  	SET flister=##class(%iKnow.Source.SQL.Lister).%New(domId)
  	SET myloader=##class(%iKnow.Source.Loader).%New(domId)
  	
  	// Построение запроса
	
   	SET myquery="SELECT id,content, blockid, component->blockid As component_blockid, component->title As component_title, book->blockid As book_blockid, book->title As book_title FROM DocBook.block"
  	 	
  	SET idfld="id"
  	SET grpfld="id" // TODO: Посмотреть как лучше
  	SET dataflds=$LB("content")
  	SET metaflds=$LB("id","blockid","component_blockid","component_title","book_blockid","book_title")
  	
  	//Метаданные
  	SET val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"id",$LB("="),$$$MDDTNUMBER)
  	SET val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"blockid",$LB("="),$$$MDDTSTRING)
  	SET val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"component_blockid",$LB("="),$$$MDDTSTRING)
  	SET val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"component_title",$LB("="),$$$MDDTSTRING)
  	SET val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"book_blockid",$LB("="),$$$MDDTSTRING)
  	SET val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"book_title",$LB("="),$$$MDDTSTRING)
  	
  	// Запуск листера
  	SET stat=flister.AddListToBatch(myquery,idfld,grpfld,dataflds,metaflds)
      IF stat '= 1 {WRITE "The lister failed: ",$System.Status.DisplayError(stat) QUIT }
    // Запуск загрузчика
    SET stat=myloader.ProcessBatch()
      IF stat '= 1 {
	      QUIT 
	       }
 
    //Функционал
    SET numSrcD=##class(%iKnow.Queries.SourceQAPI).GetCountByDomain(domId)
  	WRITE "The domain contains ",numSrcD," sources",!
  	SET numSentD=##class(%iKnow.Queries.SentenceQAPI).GetCountByDomain(domId)
  	WRITE "These sources contain ",numSentD," sentences",!!
  	
  	ZNSPACE "DOCSEARCH" 
  	 
  	s st = $$$OK
  	q st
}

/// Метод поиска подобных сущностей. Возвращает строку слов, разделенных запятой.
ClassMethod GetSimilar(SearchString) As %Status
{
	ZNSPACE "DOCBOOK"
	SET dname="DocSearch" 
	SET domoref=##class(%iKnow.Domain).Open(dname)
	SET domId=domoref.Id
	set resultArray = ##class(%DynamicArray).%New()
	set resultArray={}
	set SC = ##class(%iKnow.Queries.EntityAPI).GetSimilar(.Result, domId, SearchString)
	quit:$$$ISERR(SC) ""
	
	for i=0:1:10 {
		set оrd = $order(Result(i),1,Data)
		d resultArray.%Set(""_i,"similar")
		d resultArray.%Set(""_i,$li(Data,2))

	}
	
	w resultArray.%ToJSON()
	ZNSPACE "DOCSEARCH"
	q $$$OK
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
	SET createquery = "CREATE TABLE temptable (idSQL INT,content VARCHAR(30000),link VARCHAR(10000),	frequency FLOAT,title VARCHAR(10000))"
  	SET createStatement = ##class(%SQL.Statement).%New()
  	SET createStatus = createStatement.%Prepare(createquery)
   	IF createStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(createStatus) QUIT}
  	SET createRset = createStatement.%Execute()
	ZNSPACE "DOCBOOK"
	
	// Выполняем поиск слова с помощью iFind в DocBook.block
	set tempArray = ##class(%ArrayOfDataTypes).%New()
	set count = 0	
	SET myquery = "SELECT id,content, component->blockid As link,book->title As title FROM DocBook.block WHERE %ID %FIND search_index(contentInd,'"_text_"',0)"
  	SET tStatement = ##class(%SQL.Statement).%New()
  	SET qStatus = tStatement.%Prepare(myquery)
   	IF qStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(qStatus) QUIT}
  	SET rset = tStatement.%Execute()
  	WHILE rset.%Next() {
	  	ZNSPACE "DOCSEARCH"
	  	set tempArray(count,0)= rset.id
	  	set tempArray(count,1) = ##class(Search.Parser).Parse(rset.content)
    	set tempArray(count,2) = rset.link
    	set tempArray(count,3) = ##class(Search.Parser).Frequency(tempArray(count,1),text)
    	set tempArray(count,4) = rset.title
    	set newquery ="insert into SQLUser.temptable(idSQL,content,link,frequency,title) VALUES(?,?,?,?,?)"
  		SET rset2 = ##class(%SQL.Statement).%ExecDirect(,.newquery,tempArray(count,0),tempArray(count,1),tempArray(count,2),tempArray(count,3),tempArray(count,4))
    	IF rset2.%SQLCODE'=0 {WRITE !,"1st ExecDirect SQLCODE=",rset2.%SQLCODE,!,rset2.%Message  QUIT}
  		s count = count + 1
    	ZNSPACE "DOCBOOK"
       } 
       
    // Получаем данные с временной таблицы отсортированные по частоте
    ZNSPACE "DOCSEARCH"
   	
	s count = count - 1
	//в портале - SELECT TOP 500 JSON_OBJECT('idSQL':id, 'content': {fn CONCAT(content,' ')}) FROM docbook.block WHERE %ID %FIND search_index(contentInd,'lower',0) 
	SET resultQuery = "SELECT TOP 100 JSON_OBJECT('idSQL':idSQL, 'content': {fn CONCAT(content,' ')}, 'link':link, 'frequency':frequency, 'title':title) FROM SQLUser.temptable ORDER BY frequency DESC"
	//SET resultQuery = "SELECT TOP 500 JSON_OBJECT('idSQL':idSQL, 'content':content, 'link':link, 'frequency':frequency, 'title':title) FROM SQLUser.temptable ORDER BY frequency DESC"
  	SET Statement = ##class(%SQL.Statement).%New()
  	SET Status = Statement.%Prepare(resultQuery)
   	IF Status'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(Status) QUIT}
  	SET result = Statement.%Execute()
   	//WHILE result.%Next() {DO result.%Print(" ^ ")}

  	set countZap=1
  	w "{""sources"":["
    WHILE result.%Next() {
     DO result.%Print(" ^ ")
     if ((countZap'=count)) {
     if (countZap=100) {q}
      w ","
      s countZap=countZap+1 
     }
    }
    w "]}"
    
	//Удалим временную таблицу
    SET dropquery = "drop table SQLUser.temptable"
  	SET dropStatement = ##class(%SQL.Statement).%New()
  	SET dropStatus = dropStatement.%Prepare(dropquery)
   	IF dropStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(dropStatus) QUIT}
  	SET dropRset = dropStatement.%Execute()
	s st=$$$OK
	q st
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