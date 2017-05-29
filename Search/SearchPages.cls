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
       	set count=0
       	set ResultJSON = { "sources": [], "totalCount":[]}
    	set totalCountJSON = {"total":(count)}
 	    do ResultJSON.totalCount.%Push(totalCountJSON)
 	    write ResultJSON.%ToJSON()  
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
		if words="" {
			set wordText=phrase
		}
		else {
			set wordText=wordText_" "_phrase
		}	
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
	} else {
		set listAny = $Listfromstring("")
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
	
	// Пагинация
	// Получим количество всех элементов
	set myquery = "SELECT COUNT(*) AS CountText FROM DocBook.block WHERE %ID %FIND search_index(contentInd,?,0)"
	set tStatement = ##class(%SQL.Statement).%New()
  	set qStatus = tStatement.%Prepare(.myquery)
    IF qStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(qStatus) QUIT}
    set rset = tStatement.%Execute(text)
    while rset.%Next() {
    	set count=rset.CountText
    }
    
    // Обработка случая если нечего не нашли
     if count=0{
     	set ResultJSON = { "sources": [], "totalCount":[]}
    	set totalCountJSON = {"total":(count)}
 	    do ResultJSON.totalCount.%Push(totalCountJSON)
 	    write ResultJSON.%ToJSON()
 	    quit 0 
 	}

	set commonCount = count
	if commonCount<startRecord set startRecord=0
	set offset=recordCount+startRecord-1	
	if (offset>commonCount) set recordCount=recordCount-(offset-commonCount)
  	// Запрос к таблице с данными
  	// TODO частота через ifind Работает недостаточно быстро из-за того что в БД храняться абзацы текста, а не текст всей страницы целиком
  	//set resultQuery = "select * from (select TOP "_recordCount_" * from (select TOP "_offset_" * from(select count(*) as cnt,* from(select *, sum(RankOne) as Rank from (select component->blockid AS docKey, component->title AS title,book->blockid AS bookKey, book->title AS bookTitle, DocBook.block_contentIndRank(%ID, ?, '0') RankOne FROM DocBook.block WHERE %ID %FIND search_index(contentInd,?,0)) group by title))order by RANK DESC) order by RANK ASC) order by RANK DESC"  	
  	set resultQuery = "select * from (select TOP "_recordCount_" * from (select TOP "_offset_" * from(select count(*) as cnt,* from(select *, count(*) as Rank from (select component->blockid AS docKey, component->title AS title,book->blockid AS bookKey, book->title AS bookTitle FROM DocBook.block WHERE %ID %FIND search_index(contentInd,?,0)) group by title))order by RANK DESC) order by RANK ASC) order by RANK DESC"  	
	set Statement = ##class(%SQL.Statement).%New()
  	set Status = Statement.%Prepare(resultQuery)
   	if Status'=1 {write "%Prepare failed 1:" do $System.Status.DisplayError(Status) quit}
  	set result = Statement.%Execute(text)
   	// Формируем динамический обьект
    set ResultJSON = { "sources": [], "totalCount":[]}
    while result.%Next() {
    	// Заполняем массив данными
    	set tJSON = {"textInfo":[], "docKey": (result.docKey) ,"title": (##class(Search.Parser).ParseTitle(result.title)),   "bookKey": (result.bookKey) ,"bookTitle": (result.bookTitle) }
		// Создаем запрос для получения текста для каждой страницы
		set subresultQuery = "select DocBook.block_contentIndHighlight(%ID, ?, '0', '<span class=""Illumination"">', 0) text,blockid AS textKey,component->blockid AS docKey from DocBook.block where %ID %FIND search_index(contentInd,?,0) and component->blockid=?"
	  	set subStatement = ##class(%SQL.Statement).%New()
	  	set subStatus = subStatement.%Prepare(subresultQuery)
	   	if subStatus'=1 {write "%Prepare failed 2:" do $System.Status.DisplayError(subStatus) quit}
	  	set subresult = subStatement.%Execute(text,text,result.docKey)
	  	while subresult.%Next() {
	  		if subresult.text'="" {
		  		set subtextKey = result.docKey_"#"_subresult.textKey
		  		set textInfoJSON = {"text":(subresult.text), "textKey":(subtextKey)}
		  		do tJSON.textInfo.%Push(textInfoJSON)
		  	}
	  	}
	  	set totalCount=result.cnt
		do ResultJSON.sources.%Push(tJSON)		
    }
    // Вывод в JSON общего количества найденных результатов
    set totalCountJSON = {"total":(totalCount)}
    do ResultJSON.totalCount.%Push(totalCountJSON)
	set st=$$$OK
	
	// Метод преобразующий динамический обьект в JSON
	write ResultJSON.%ToJSON()
	quit st
}



}