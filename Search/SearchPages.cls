Class Search.SearchPages {

/// POST метод поиска по документации
// Пример POST запроса {"words":"iknow","phrase":"rest api","anyWords":"json, sql","without":"class, you, ifind, Enhancements", startRecord:1, recordCount:20}
ClassMethod Search(obj) As %Status
{ 
	try {
		set %request.Content.Attributes("CharEncoding")="UTF8"
		set str = $ZCVT(%request.Content.Read(),"I","UTF8")
		$$$THROWONERROR(st,##class(%ZEN.Auxiliary.jsonProvider).%ConvertJSONToObject(str,,.obj,1))
		do ##class(Search.SearchPages).FormQueryNew(obj)
    } catch ex {
       	set err = "Ошибка разбора JSON запроса "_$system.Status.GetErrorText(ex.AsStatus(),"ru")
       	set error = ##class(%DynamicObject).%New()
       	set error.ErrorCode = err    
       	write " Ошибка: "_error.%ToJSON()    
    } 
 quit $$$OK
}
/// Метод формирования запроса к БД
ClassMethod FormQuery(obj) As %Status
{
	// Получаем параметры поиска:
	// Поиск со словами:
	set words=obj.words
	// Поиск с словосочетанием: 
	set phrase=obj.phrase
	// Поиск с любым из этих слов:
	set anyWords=obj.anyWords
	// Поиск без следующих слов:
	set without=obj.without
	
	// Параметры нужные для пагинации
	// Начальная запись
    set startRecord=obj.startRecord
    // Число записей на странице	
	set recordCount=obj.recordCount
	
	// Переменная содержащая текст для запроса iFind в соответствии с форматированием нужным iFind
	set text=""
	// Переменная содержащая текст запроса без форматирования. Нужна для получения id слов, используемых iKnow
	set wordText=""
	
	// Заполняем переменнные в зависимости от тех данных что ввели на фронте
	if words'="" {
		set text = text_words
		set wordText=wordText_words
	}
	if phrase'="" {
		set text = text_" ("_phrase_")"
		set wordText=wordText_" "_phrase
	}
	if anyWords'="" {
		//Удаляем пробелы
		set anyWords = $REPLACE(anyWords," ","") 
		//Извлекаем до ,
		set listAny=$LISTFROMSTRING(anyWords,",")
		set strAny=" OR ("_$LIST(listAny,1)
		set strAnyWord=$LIST(listAny,1)
		for i=2:1:$LISTLENGTH(listAny) {
			set strAny = strAny_" OR "_$LIST(listAny,i)
			}
		set text = text_strAny_")"
	}
	if without'="" {
		set text = text_")"
		//Удаляем пробелы
		set without = $REPLACE(without," ","")  
		//Извлекаем до ,
		set listOut=$LISTFROMSTRING(without,",")
		set strOut=" NOT ("_$LIST(listOut,1)
		for i=2:1:$LISTLENGTH(listOut) {
			set strOut = strOut_" OR "_$LIST(listOut,i) 
			}
		set text = "("_text
		set text = text_strOut_")"
	}
	// Список содержащий слова запроса
	set wordList=$LISTFROMSTRING(wordText, " ")
	
	// Формируем список содержащий id слов запроса из списка слов запроса
	set currPoint=0
	set currWord=0
	set textId=""
	set cntList=0
	zn "DOCBOOK"
	// Получение id домена
	set dname="DocSearch" 
	set domoref=##class(%iKnow.Domain).Open(dname)
	set domId=domoref.Id
	// Получение id первого слова запроса
	set id = ##class(%iKnow.Queries.EntityAPI).GetId(domId,$LISTGET(wordList,1))
	zn "DOCSEARCH"
	set textId=textId_id
	// Получение id остальных слов запроса
	while $LISTNEXT(wordList,currPoint,currWord) {
		if cntList>0{
			zn "DOCBOOK"
			set id = ##class(%iKnow.Queries.EntityAPI).GetId(domId,currWord)
			zn "DOCSEARCH"
			set textId=textId_" "_id
		}
		set cntList = cntList+1
	}
	// Список содержащий id слов запроса
	set wordIdList=$LISTFROMSTRING(textId, " ")
	
	// Создаем временную таблицу в которую будем заносить то что нашли по запросу пользователя,
	// высчитывать отношение искомых слов к всем словам на найденной странице и в зависимости от этого отношения сортировать результат запроса
	set createquery = "CREATE TABLE temptable (idSQL INT,content VARCHAR(30000),link VARCHAR(10000),	frequency FLOAT,title VARCHAR(10000))"
  	set createStatement = ##class(%SQL.Statement).%New()
  	set createStatus = createStatement.%Prepare(createquery)
   	if createStatus'=1 {write "%Prepare failed:" do $System.Status.DisplayError(createStatus) quit}
  	set createRset = createStatement.%Execute()
	
	// Выполняем поиск слова с помощью iFind в DocBook.block
	znspace "DOCBOOK"
	set tempArray = ##class(%ArrayOfDataTypes).%New()
	set count = 0	
	set myquery = "SELECT id,content, component->blockid As link,book->title As title FROM DocBook.block WHERE %ID %FIND search_index(contentInd,?,0)"
  	set tStatement = ##class(%SQL.Statement).%New()
  	set qStatus = tStatement.%Prepare(.myquery)
    IF qStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(qStatus) QUIT}
    set rset = tStatement.%Execute(text)
    // Заполняем массив найденными данными
  	while rset.%Next() {
	  	znspace "DOCSEARCH"
	  	set tempArray(count,0)= rset.id
	  	set tempArray(count,1) = ##class(Search.Parser).Parse(rset.content)
    	set tempArray(count,2) = rset.link
    	set tempArray(count,3) = 0 //##class(Search.Parser).Frequency(tempArray(count,1),text)
    	set tempArray(count,4) = ##class(Search.Parser).ParseTitle(rset.title)
    	set count = count + 1
    	znspace "DOCBOOK"
       } 
    znspace "DOCSEARCH"
    // Всего получили строк в запросе
	set count = count - 1
	
	// Проходим по всем разным страницам и получаем в список id источников составляющих страницу. Нужно для iKnow 
    set textLink=tempArray(0,2)
	for i=0:1:count-1 {
		if (tempArray(i,2)'=tempArray(i+1,2)) && (tempArray(i+1,2)'=""){
			set textLink = textLink_", "_tempArray(i+1,2)
		}
		}
		set listLink = $LISTFROMSTRING(textLink, ", ")
		set currPoint=0
		set currLink=0
		set countSourses=0
		while $LISTNEXT(listLink,currPoint,currLink) {
			set tempId = ""
			znspace "DOCBOOK"
			set queryLink = "SELECT id, component->blockid As link FROM DocBook.block WHERE component->blockid='"_currLink_"'"
		  	set tStatement = ##class(%SQL.Statement).%New()
		  	set qStatus = tStatement.%Prepare(queryLink)
		   	if qStatus'=1 {write "%Prepare failed:" do $System.Status.DisplayError(qStatus) quit}
		  	set rLink = tStatement.%Execute()
		  	while rLink.%Next() {
			  	znspace "DOCSEARCH"
			  	set tempId = tempId_rLink.id_" "
		    	znspace "DOCBOOK"
		       }
		zn "docbook"
		// Получаем id источников содержащие слова из запроса
		set tSC = ##class(%iKnow.Queries.SourceAPI).GetByEntities(.tResult,domId, wordList,1,500)
		zn "docsearch" 
		set array = ##class(%Library.ArrayOfObjects).%New()
		set i = ""
		set cntArray=0
		// Через SQL получили ID источников, но ID SQL записей источников. Для iKnow требуются ID записей источников домена. Для этого мы получаем соотношения ID SQL и ID Домена и заменяем ID
	    for {
		    set i = $order(tResult(i),1,tSrcData)
		    quit:i=""	
			set string=$lg(tSrcData,2)
			set nul=$FIND(string,":",1)-1 
			set from=$FIND(string,":",nul+1)-1
			set to=$FIND(string,":",from+1)-1
			set substr=$EXTRACT(string,from+1,to-1)
			set first = $lg(tSrcData,1)
			set array(i,0)=substr
			set array(i,1)=first
			set cntArray=cntArray+1
		}
		set tempIdNew=""
		   for i=1:1:cntArray {
		   		set tempId=$Replace(tempId, array(i,0),array(i,1))   
		   } 
	    // Массив с ИД источников 
	    set idArr(currLink) =$LISTFROMSTRING(tempId, " ")
	    set countSourses=countSourses+1
		}
		
		znspace "DOCSEARCH"
		set countSourses=countSourses-1
		// Высчитываем отношение искомых слов к всем словам на найденной странице
		set currPoint=0
		set currLink=0
		while $LISTNEXT(listLink,currPoint,currLink) {
			set frequency(currLink)= ##class(Search.Rank).Frequency(domId,idArr(currLink),wordIdList)
		}
		for i=0:1:count {
			if tempArray(i,2)'="" {
				set tempArray(i,3) = frequency(tempArray(i,2))
	    	}
	}
	 
	// Запись построчно в временную таблицу
	for i=0:1:count {
		set newquery ="insert into SQLUser.temptable(idSQL,content,link,frequency,title) VALUES(?,?,?,?,?)"
  		set rset2 = ##class(%SQL.Statement).%ExecDirect(,.newquery,tempArray(i,0),tempArray(i,1),tempArray(i,2),tempArray(i,3),tempArray(i,4))
    	if rset2.%SQLCODE'=0 {write !,"1st ExecDirect SQLCODE=",rset2.%SQLCODE,!,rset2.%Message  quit}
	}
	
	// Пагинация
	set commonCount = count
	if commonCount<startRecord set startRecord=1
	set offset=recordCount+startRecord-1	
	if (offset>commonCount) set recordCount=recordCount-(offset-commonCount)
	// Запрос к временной таблице отсортированной по частоте с учетом пагинации 
   	set resultQuery = "select * from (select TOP "_recordCount_" * from (select TOP "_offset_" * from SQLUser.temptable order by frequency DESC) order by frequency ASC) order by frequency DESC"
  	set Statement = ##class(%SQL.Statement).%New()
  	set Status = Statement.%Prepare(resultQuery)
   	if Status'=1 {write "%Prepare failed:" do $System.Status.DisplayError(Status) quit}
  	set result = Statement.%Execute()
   	// Формируем динамический обьект
    set ResultJSON = { "sources": [] }
    while result.%Next() {
    	// Заполняем массив данными
    	set tJSON = { "content":(result.content), "link":(result.link), "frequency": (result.frequency), "title": (result.title) }
		do ResultJSON.sources.%Push(tJSON)
    }
    // Вывод в JSON общего количества найденных результатов
    set totalCountJ = {"totalCount":(+count)}
    do ResultJSON.sources.%Push(totalCountJ)
    
	//Удалем временную таблицу
    set dropquery = "drop table SQLUser.temptable"
  	set dropStatement = ##class(%SQL.Statement).%New()
  	set dropStatus = dropStatement.%Prepare(dropquery)
   	if dropStatus'=1 {write "%Prepare failed:" do $System.Status.DisplayError(dropStatus) quit}
  	set dropRset = dropStatement.%Execute()
	set st=$$$OK
	
	// Метод преобразующий динамический обьект в JSON
	write ResultJSON.%ToJSON()
	
	quit st
}

/// Метод формирования запроса к БД
ClassMethod FormQueryNew(obj) As %Status
{
	// Получаем параметры поиска:
	// Поиск со словами:
	set words=obj.words
	// Поиск с словосочетанием: 
	set phrase=obj.phrase
	// Поиск с любым из этих слов:
	set anyWords=obj.anyWords
	// Поиск без следующих слов:
	set without=obj.without
	
	// Параметры нужные для пагинации
	// Начальная запись
    set startRecord=obj.startRecord
    // Число записей на странице	
	set recordCount=obj.recordCount
	
	// Переменная содержащая текст для запроса iFind в соответствии с форматированием нужным iFind
	set text=""
	// Переменная содержащая текст запроса без форматирования. Нужна для получения id слов, используемых iKnow
	set wordText=""
	
	// Заполняем переменнные в зависимости от тех данных что ввели на фронте
	if words'="" {
		set text = text_words
		set wordText=wordText_words
	}
	if phrase'="" {
		set text = text_" ("_phrase_")"
		set wordText=wordText_" "_phrase
	}
	if anyWords'="" {
		//Удаляем пробелы
		set anyWords = $REPLACE(anyWords," ","") 
		//Извлекаем до ,
		set listAny=$LISTFROMSTRING(anyWords,",")
		set strAny=" OR ("_$LIST(listAny,1)
		set strAnyWord=$LIST(listAny,1)
		for i=2:1:$LISTLENGTH(listAny) {
			set strAny = strAny_" OR "_$LIST(listAny,i)
			}
		set text = text_strAny_")"
	}
	if without'="" {
		set text = text_")"
		//Удаляем пробелы
		set without = $REPLACE(without," ","")  
		//Извлекаем до ,
		set listOut=$LISTFROMSTRING(without,",")
		set strOut=" NOT ("_$LIST(listOut,1)
		for i=2:1:$LISTLENGTH(listOut) {
			set strOut = strOut_" OR "_$LIST(listOut,i) 
			}
		set text = "("_text
		set text = text_strOut_")"
	}
	// Список содержащий слова запроса
	set wordList=$LISTFROMSTRING(wordText, " ")
	
	// Формируем список содержащий id слов запроса из списка слов запроса
	set currPoint=0
	set currWord=0
	set textId=""
	set cntList=0
	zn "DOCBOOK"
	// Получение id домена
	set dname="DocSearch" 
	set domoref=##class(%iKnow.Domain).Open(dname)
	set domId=domoref.Id
	// Получение id первого слова запроса
	set id = ##class(%iKnow.Queries.EntityAPI).GetId(domId,$LISTGET(wordList,1))
	zn "DOCSEARCH"
	set textId=textId_id
	// Получение id остальных слов запроса
	while $LISTNEXT(wordList,currPoint,currWord) {
		if cntList>0{
			zn "DOCBOOK"
			set id = ##class(%iKnow.Queries.EntityAPI).GetId(domId,currWord)
			zn "DOCSEARCH"
			set textId=textId_" "_id
		}
		set cntList = cntList+1
	}
	// Список содержащий id слов запроса
	set wordIdList=$LISTFROMSTRING(textId, " ")
	
	// Создаем временную таблицу в которую будем заносить то что нашли по запросу пользователя,
	// высчитывать отношение искомых слов к всем словам на найденной странице и в зависимости от этого отношения сортировать результат запроса
	set createquery = "CREATE TABLE temptable (idSQL INT,text VARCHAR(30000),textKey VARCHAR(10000),frequency FLOAT,docKey VARCHAR(10000),title VARCHAR(10000),bookKey VARCHAR(10000),bookTitle VARCHAR(10000))"
  	set createStatement = ##class(%SQL.Statement).%New()
  	set createStatus = createStatement.%Prepare(createquery)
   	if createStatus'=1 {write "%Prepare failed:" do $System.Status.DisplayError(createStatus) quit}
  	set createRset = createStatement.%Execute()
	
	// Выполняем поиск слова с помощью iFind в DocBook.block
	znspace "DOCBOOK"
	set tempArray = ##class(%ArrayOfDataTypes).%New()
	set count = 0	
	set myquery = "SELECT  id, content AS text, blockid AS textKey, component->blockid AS docKey, component->title AS title,book->blockid AS bookKey, book->title AS bookTitle FROM DocBook.block WHERE %ID %FIND search_index(contentInd,?,0)"
	set tStatement = ##class(%SQL.Statement).%New()
  	set qStatus = tStatement.%Prepare(.myquery)
    IF qStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(qStatus) QUIT}
    set rset = tStatement.%Execute(text)
    // Заполняем массив найденными данными
  	while rset.%Next() {
	  	znspace "DOCSEARCH"
	  	set tempArray(count,0)= rset.id
	  	set tempArray(count,1) = ##class(Search.Parser).Parse(rset.text)
    	set tempArray(count,2) = rset.textKey
    	set tempArray(count,3) = 0
    	set tempArray(count,4) = rset.docKey
    	set tempArray(count,5) = rset.title
    	set tempArray(count,6) = rset.bookKey
    	set tempArray(count,7) = rset.bookTitle
    	set count = count + 1
    	znspace "DOCBOOK"
       } 
     
    znspace "DOCSEARCH"
    // Всего получили строк в запросе
	set count = count - 1
	
	// Проходим по всем разным страницам и получаем в список id источников составляющих страницу. Нужно для iKnow 
    set textLink=tempArray(0,4)
	for i=0:1:count-1 {
		if (tempArray(i,4)'=tempArray(i+1,4)) && (tempArray(i+1,4)'=""){
			set textLink = textLink_", "_tempArray(i+1,4)
			}
		}
		set listLink = $LISTFROMSTRING(textLink, ", ")
		set currPoint=0
		set currLink=0
		set countSourses=0
		while $LISTNEXT(listLink,currPoint,currLink) {
			set tempId = ""
			znspace "DOCBOOK"
			set queryLink = "SELECT id, component->blockid As link FROM DocBook.block WHERE component->blockid='"_currLink_"'"
		  	set tStatement = ##class(%SQL.Statement).%New()
		  	set qStatus = tStatement.%Prepare(queryLink)
		   	if qStatus'=1 {write "%Prepare failed:" do $System.Status.DisplayError(qStatus) quit}
		  	set rLink = tStatement.%Execute()
		  	while rLink.%Next() {
			  	znspace "DOCSEARCH"
			  	set tempId = tempId_rLink.id_" "
		    	znspace "DOCBOOK"
		       }
		zn "docbook"
		// Получаем id источников содержащие слова из запроса
		set tSC = ##class(%iKnow.Queries.SourceAPI).GetByEntities(.tResult,domId, wordList,1,500)
		zn "docsearch" 
		set array = ##class(%Library.ArrayOfObjects).%New()
		set i = ""
		set cntArray=0
		// Через SQL получили ID источников, но ID SQL записей источников. Для iKnow требуются ID записей источников домена. Для этого мы получаем соотношения ID SQL и ID Домена и заменяем ID
	    for {
		    set i = $order(tResult(i),1,tSrcData)
		    quit:i=""	
			set string=$lg(tSrcData,2)
			set nul=$FIND(string,":",1)-1 
			set from=$FIND(string,":",nul+1)-1
			set to=$FIND(string,":",from+1)-1
			set substr=$EXTRACT(string,from+1,to-1)
			set first = $lg(tSrcData,1)
			set array(i,0)=substr
			set array(i,1)=first
			set cntArray=cntArray+1
		}
		set tempIdNew=""
		   for i=1:1:cntArray {
		   		set tempId=$Replace(tempId, array(i,0),array(i,1))   
		   } 
	    // Массив с ИД источников 
	    set idArr(currLink) =$LISTFROMSTRING(tempId, " ")
	    set countSourses=countSourses+1
		}
		
		znspace "DOCSEARCH"
		set countSourses=countSourses-1
		// Высчитываем отношение искомых слов к всем словам на найденной странице
		set currPoint=0
		set currLink=0
		
		while $LISTNEXT(listLink,currPoint,currLink) {
			set frequency(currLink)= ##class(Search.Rank).Frequency(domId,idArr(currLink),wordIdList)
		}
		
		
		for i=0:1:count {
			if tempArray(i,4)'="" {
				set tempArray(i,3) = frequency(tempArray(i,4))
	    	}
	    }
	 
	// Запись построчно в временную таблицу
	
	for i=0:1:count {
		set newquery ="insert into SQLUser.temptable(idSQL,text,textKey,frequency,docKey,title,bookKey,bookTitle) VALUES(?,?,?,?,?,?,?,?)"
  		set rset2 = ##class(%SQL.Statement).%ExecDirect(,.newquery,tempArray(i,0),tempArray(i,1),tempArray(i,2),tempArray(i,3),tempArray(i,4),tempArray(i,5),tempArray(i,6),tempArray(i,7))
    	if rset2.%SQLCODE'=0 {write !,"2st ExecDirect SQLCODE=",rset2.%SQLCODE,!,rset2.%Message  quit}
	}
	
	// Пагинация
	set commonCount = count
	if commonCount<startRecord set startRecord=1
	set offset=recordCount+startRecord-1	
	if (offset>commonCount) set recordCount=recordCount-(offset-commonCount)
	// Запрос к временной таблице отсортированной по частоте с учетом пагинации 
   	//set resultQuery = "select * from (select TOP "_recordCount_" * from (select TOP "_offset_" * from SQLUser.temptable order by frequency DESC) order by frequency ASC) order by frequency DESC"
  	//Пока что без пагинации
  	set resultQuery = "select * from SQLUser.temptable order by docKey"
  	set Statement = ##class(%SQL.Statement).%New()
  	set Status = Statement.%Prepare(resultQuery)
   	if Status'=1 {write "%Prepare failed:" do $System.Status.DisplayError(Status) quit}
  	set result = Statement.%Execute()
   	// Формируем динамический обьект
    //set ResultJSON = { "sources": [] }
    set ResultJSON = { "sources": [] }
    
    while result.%Next() {
    	// Заполняем массив данными
    	//set tJSON = { "text":(result.text), "textKey":(result.textKey), "frequency": (result.frequency), "docKey": (result.docKey) ,"title": (result.title),   "bookKey": (result.bookKey) ,"bookTitle": (result.bookTitle) }
		set tJSON = {"textInfo":[{"text":(result.text), "textKey":(result.textKey)}], "frequency": (result.frequency), "docKey": (result.docKey) ,"title": (result.title),   "bookKey": (result.bookKey) ,"bookTitle": (result.bookTitle) }
		do ResultJSON.sources.%Push(tJSON)
		
    }
    // Вывод в JSON общего количества найденных результатов
    set totalCountJ = {"totalCount":(+count)}
    do ResultJSON.sources.%Push(totalCountJ)
    
	//Удалем временную таблицу
    set dropquery = "drop table SQLUser.temptable"
  	set dropStatement = ##class(%SQL.Statement).%New()
  	set dropStatus = dropStatement.%Prepare(dropquery)
   	if dropStatus'=1 {write "%Prepare failed:" do $System.Status.DisplayError(dropStatus) quit}
  	set dropRset = dropStatement.%Execute()
	set st=$$$OK
	
	// Метод преобразующий динамический обьект в JSON
	write ResultJSON.%ToJSON()
	
	quit st
}

}