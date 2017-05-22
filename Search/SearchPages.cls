Class Search.SearchPages {

/// POST метод поиска по документации
// Пример POST запроса {"words":"iknow","phrase":"rest api","anyWords":"json, sql","without":"class, you, ifind, Enhancements", startRecord:1, recordCount:20}
ClassMethod Search(obj) As %Status
{ 
	try {
		set %request.Content.Attributes("CharEncoding")="UTF8"
		set str = $ZCVT(%request.Content.Read(),"I","UTF8")
		$$$THROWONERROR(st,##class(%ZEN.Auxiliary.jsonProvider).%ConvertJSONToObject(str,,.obj,1))
		do ##class(Search.SearchPages).FormQuery(obj)
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
	
	
	zn "DOCBOOK"
	// Получение id домена
	set dname="DocSearch" 
	set domoref=##class(%iKnow.Domain).Open(dname)
	set domId=domoref.Id
	zn "DOCSEARCH"
	
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
	  	if rset.title'="" {
		  	set tempArray(count,0)= rset.id
		  	set tempArray(count,1) = rset.text // ##class(Search.Parser).Parse(rset.text)
	    	set tempArray(count,2) = rset.textKey
	    	set tempArray(count,3) = 0
	    	set tempArray(count,4) = rset.docKey
	    	set tempArray(count,5) = rset.title // ##class(Search.Parser).ParseTitle(rset.title)
	    	set tempArray(count,6) = rset.bookKey
	    	set tempArray(count,7) = rset.bookTitle // ##class(Search.Parser).ParseTitle(rset.bookTitle)
	    	set count = count + 1
	    }
    	znspace "DOCBOOK"
       } 
    // Обработка случая если нечего не нашли
    if count=0{
        set ResultJSON = { "sources": [], "totalCount":[]}
	    set totalCountJSON = {"total":(count)}
	    do ResultJSON.totalCount.%Push(totalCountJSON)
        write ResultJSON.%ToJSON()
        quit 0   
    }
    
    znspace "DOCSEARCH"
    // Всего получили строк в запросе
	set count = count - 1
	
	// Высчитываем частоту с помощью iknow
	// Получаем в массив страницы документации
	znspace "DOCBOOK"
	set docKeyArray = ##class(%ArrayOfDataTypes).%New()
	set countDocKey=0
	set myqueryDocKey = "SELECT component->blockid AS docKey FROM DocBook.block WHERE %ID %FIND search_index(contentInd,?,0) GROUP BY %EXACT(component->blockid)"
	set StatementDocKey = ##class(%SQL.Statement).%New()
  	set StatusDocKey = StatementDocKey.%Prepare(.myqueryDocKey)
    IF StatusDocKey'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(StatusDocKey) QUIT}
    set rsetDocKey = StatementDocKey.%Execute(text)
    // Заполняем массив найденными данными
  	while rsetDocKey.%Next() {
  		if rsetDocKey.docKey'="" {
  			set docKeyArray(countDocKey)=rsetDocKey.docKey
  			set countDocKey=countDocKey+1
  		}
  	}
  	
  	set frequencyArray=##class(%ArrayOfDataTypes).%New()
  	for i=0:1:countDocKey-1{
  		set frequencyArray(docKeyArray(i))=0
  	}
  	for i=0:1:countDocKey-1 {
  		// Создаем фильтр для iknow. Благодоря этому, считать будем по каждой странице докуменнтации
  		set filt=##class(%iKnow.Filters.SimpleMetadataFilter).%New(domId,"component_blockid","=",docKeyArray(i))      
  		set num = ##class(%iKnow.Queries.EntityAPI).GetTopTFIDF(.result,domId,1,100,filt)
  		set j=1
  		//Пока заполнен глобал
  		while $D(result(j))'=0 {
  			// Для всех слов запроса
  			for wordCount=1:1:$LISTLENGTH(wordList) {
  				set word = $LISTGET(wordList,wordCount)
  				if $FIND($ListGet(result(j),2),word)'=0 {
  					set frequencyArray(docKeyArray(i))=frequencyArray(docKeyArray(i))+$ListGet(result(j),3)
  				}
  					
  			}
  			set j=j+1	
  		}	
  	}
  	
	znspace "DOCSEARCH"
	// Запись построчно в временную таблицу
	for i=0:1:count {
		if tempArray(i,4)="" {
		 set frequencyArray(tempArray(i,4))=0
		}
		set newquery ="insert into SQLUser.temptable(idSQL,text,textKey,frequency,docKey,title,bookKey,bookTitle) VALUES(?,?,?,?,?,?,?,?)"
  		set rset2 = ##class(%SQL.Statement).%ExecDirect(,.newquery,tempArray(i,0),tempArray(i,1),tempArray(i,2), frequencyArray(tempArray(i,4)) ,tempArray(i,4),tempArray(i,5),tempArray(i,6),tempArray(i,7))
    	if rset2.%SQLCODE'=0 {write !,"2st ExecDirect SQLCODE=",rset2.%SQLCODE,!,rset2.%Message  quit}
	}
	
	// Пагинация
	set commonCount = count
	if commonCount<startRecord set startRecord=0
	set offset=recordCount+startRecord-1	
	if (offset>commonCount) set recordCount=recordCount-(offset-commonCount)
	// Запрос к временной таблице отсортированной по частоте с учетом пагинации 
   	set resultQuery = "select * from (select TOP "_recordCount_" * from (select TOP "_offset_" * from(select count(*) AS cnt, * from ( select * from SQLUser.temptable group by title)) order by frequency DESC) order by frequency ASC) order by frequency DESC"
  	set Statement = ##class(%SQL.Statement).%New()
  	set Status = Statement.%Prepare(resultQuery)
   	if Status'=1 {write "%Prepare failed:" do $System.Status.DisplayError(Status) quit}
  	set result = Statement.%Execute()
   	// Формируем динамический обьект
    set ResultJSON = { "sources": [], "totalCount":[]}
    
    while result.%Next() {
    	// Заполняем массив данными
    	set tJSON = {"textInfo":[], "docKey": (result.docKey) ,"title": (##class(Search.Parser).ParseTitle(result.title)),   "bookKey": (result.bookKey) ,"bookTitle": (##class(Search.Parser).ParseTitle(result.bookTitle)), "frequency": (result.frequency) }
		
		// Создаем запрос для получения текста для каждой страницы
		set subresultQuery = "select * from SQLUser.temptable where docKey=?"
	  	set subStatement = ##class(%SQL.Statement).%New()
	  	set subStatus = subStatement.%Prepare(subresultQuery)
	   	if subStatus'=1 {write "%Prepare failed:" do $System.Status.DisplayError(subStatus) quit}
	  	set subresult = subStatement.%Execute(result.docKey)
	  	while subresult.%Next() {
	  		set subtextKey = result.docKey_"#"_subresult.textKey
	  		set textInfoJSON = {"text":(##class(Search.Parser).Parse(subresult.text)), "textKey":(subtextKey)}
	  		do tJSON.textInfo.%Push(textInfoJSON)
	  	}
	  	set totalCount=result.cnt

		do ResultJSON.sources.%Push(tJSON)		
    }
    // Вывод в JSON общего количества найденных результатов
    set totalCountJSON = {"total":(totalCount)}
    do ResultJSON.totalCount.%Push(totalCountJSON)

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