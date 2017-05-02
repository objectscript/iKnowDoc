Class Search.SearchPages {

/// POST метод поиска по документации
// Пример запроса {"words":"iknow","phrase":"rest api","anyWords":"json, sql","without":"class, you, ifind, Enhancements"}
ClassMethod Search(obj) As %Status
{
	/*try {
	 		set %request.Content.Attributes("CharEncoding")="UTF8"
	  	 	set str = $ZCVT(%request.Content.Read(),"I","UTF8")
	  		$$$THROWONERROR(st,##class(%ZEN.Auxiliary.jsonProvider).%ConvertJSONToObject(str,,.obj,1))
	  		do ##class(Utils.DataQuery).FormQuery(obj,tableName, className)
	  	} catch ex {
	  	   set err = "Ошибка разбора JSON запроса"_$system.Status.GetErrorText(ex.AsStatus(),"ru")
	  	   set error1 = ##class(%DynamicObject).%New()
	  	   set error1.ErrorCode = err  		
	  	write "Ошибка: "_error1.%ToJSON()
	   } 
	
	q $$$OK
	*/

	try {
		set %request.Content.Attributes("CharEncoding")="UTF8"
		set str = $ZCVT(%request.Content.Read(),"I","UTF8")
		$$$THROWONERROR(st,##class(%ZEN.Auxiliary.jsonProvider).%ConvertJSONToObject(str,,.obj,1))
		do ##class(Search.SearchPages).FormQuery(obj)
    } catch ex {
       	set err = "Ошибка разбора JSON запроса"_$system.Status.GetErrorText(ex.AsStatus(),"ru")
       	set error1 = ##class(%DynamicObject).%New()
       	set error1.ErrorCode = err    
       	write " ошибка: "_error1.%ToJSON()    
    } 
 quit $$$OK
}
// Метод формирования запроса к БД
ClassMethod FormQuery(obj) As %Status
{
	// Со словами:
	set words=obj.words
	// со словосочетанием: 
	set phrase=obj.phrase
	// с любым из этих слов:
	set anyWords=obj.anyWords
	// без слов:
	set without=obj.without
    set startRecord=obj.startRecord	
	set recordCount=obj.recordCount
	
	/*
	//Тестовые значения переменных
	set words = "iknow"
	set phrase= "rest api"
	set anyWords = "json, sql"
	set without = "class, you, ifind, Enhancements"
	*/	
	set text=""
	if words'="" {
		set text = text_words
	}

	if phrase'="" {
		set text = text_" ("_phrase_")"
	}
 
	if anyWords'="" {
		//Удаляем пробелы
		set anyWords = $REPLACE(anyWords," ","")  
		//Извлекаем до ,
		set listAny=$LISTFROMSTRING(anyWords,",")
		set strAny=" OR ("_$LIST(listAny,1)
		for i=2:1:$LISTLENGTH(listAny) {
			set strAny = strAny_" OR "_$LIST(listAny,i) 
			}
		set text = text_strAny_")"
	}

	// без слов:
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
	
	//write "text: ",text
	
	////////////////////////////
	

	set createquery = "CREATE TABLE temptable (idSQL INT,content VARCHAR(30000),link VARCHAR(10000),	frequency FLOAT,title VARCHAR(10000))"
  	set createStatement = ##class(%SQL.Statement).%New()
  	set createStatus = createStatement.%Prepare(createquery)
   	if createStatus'=1 {write "%Prepare failed:" do $System.Status.DisplayError(createStatus) quit}
  	set createRset = createStatement.%Execute()
	znspace "DOCBOOK"
	
	// Выполняем поиск слова с помощью iFind в DocBook.block
	set tempArray = ##class(%ArrayOfDataTypes).%New()
	set count = 0	
	set myquery = "SELECT id,content, component->blockid As link,book->title As title FROM DocBook.block WHERE %ID %FIND search_index(contentInd,'"_text_"',0)"
  	set tStatement = ##class(%SQL.Statement).%New()
  	set qStatus = tStatement.%Prepare(myquery)
   	if qStatus'=1 {write "%Prepare failed:" do $System.Status.DisplayError(qStatus) quit}
  	set rset = tStatement.%Execute()
  	WHILE rset.%Next() {
	  	znspace "DOCSEARCH"
	  	set tempArray(count,0)= rset.id
	  	set tempArray(count,1) = ##class(Search.Parser).Parse(rset.content)
    	set tempArray(count,2) = rset.link
    	set tempArray(count,3) = ##class(Search.Parser).Frequency(tempArray(count,1),text)
    	set tempArray(count,4) = rset.title
    	set newquery ="insert into SQLUser.temptable(idSQL,content,link,frequency,title) VALUES(?,?,?,?,?)"
  		set rset2 = ##class(%SQL.Statement).%ExecDirect(,.newquery,tempArray(count,0),tempArray(count,1),tempArray(count,2),tempArray(count,3),tempArray(count,4))
    	if rset2.%SQLCODE'=0 {write !,"1st ExecDirect SQLCODE=",rset2.%SQLCODE,!,rset2.%Message  quit}
  		set count = count + 1
    	znspace "DOCBOOK"
       } 
       
    // Получаем данные с временной таблицы отсортированные по частоте
    znspace "DOCSEARCH"
   	
	set count = count - 1
	
	//write count
	//
	// Пагинация
	//set startRecord =1
	//set recordCount=20
	set commonCount = count
	if commonCount<startRecord set startRecord=1
	set offset=recordCount+startRecord-1	
	if (offset>commonCount) set recordCount=recordCount-(offset-commonCount)
	
	//
	
	//set resultQuery = "SELECT JSON_OBJECT('idSQL':idSQL, 'content':content, 'link':link, 'frequency':frequency, 'title':title) FROM SQLUser.temptable ORDER BY frequency DESC"
  	//set resultQuery = "SELECT JSON_OBJECT('idSQL':idSQL, 'content':{fn CONCAT(content,' ')}, 'link':link, 'frequency':frequency, 'title':title) FROM SQLUser.temptable ORDER BY frequency DESC"
  	
  	//set resultQuery = "select TOP "_recordCount_" * from (SELECT TOP "_offset_" id,JSON_OBJECT('idSQL':id, 'content': {fn CONCAT(content,' ')},'link':link, 'frequency':frequency, 'title':title) FROM SQLUser.temptable ORDER BY frequency DESC) ORDER BY id DESC ORDER BY id ASC"
  	//set resultQuery = " (select TOP "_recordCount_" * from (SELECT TOP "_offset_" id,content, link, frequency,title FROM SQLUser.temptable ORDER BY frequency DESC) ORDER BY frequency ASC)ORDER BY frequency DESC"
  	set resultQuery = "select * from (select TOP "_recordCount_" * from (select TOP "_offset_" * from SQLUser.temptable order by frequency DESC) order by frequency ASC) order by frequency DESC"
  	//write count,!
  	//write resultQuery,!
  	//write resultQuery
  	set Statement = ##class(%SQL.Statement).%New()
  	set Status = Statement.%Prepare(resultQuery)
   	if Status'=1 {write "%Prepare failed:" do $System.Status.DisplayError(Status) quit}
  	set result = Statement.%Execute()
   	//WHILE result.%Next() {do result.%Print(" ^ ")}

  	//set countZap=0
  	//set count = 99

  	//write "{""sources"":["
    /*WHILE result.%Next() {
     do result.%Print(" ^ ")
     if ((countZap'=(recordCount-1))) {
      write ","
      set countZap=countZap+1 
     }
    }*/
    set ResultJSON = { "sources": [] }
    
    WHILE result.%Next() {
    	set tJSON = { "content":(result.content), "link":(result.link), "frequency": (result.frequency), "title": (result.title) }
		do ResultJSON.sources.%Push(tJSON)
    }
	//Удалим временную таблицу
    set dropquery = "drop table SQLUser.temptable"
  	set dropStatement = ##class(%SQL.Statement).%New()
  	set dropStatus = dropStatement.%Prepare(dropquery)
   	if dropStatus'=1 {write "%Prepare failed:" do $System.Status.DisplayError(dropStatus) quit}
  	set dropRset = dropStatement.%Execute()
	set st=$$$OK
	//quit st

	quit ..%ProcessResult(st, $g(ResultJSON))
	/////////////////////////////////////////
	/*
	
		
	//write finalquery
	//выполняем новый запрос	
	set result=##class(%ResultSet).%New("%DynamicQuery:SQL")
 	set sc=result.Prepare(finalquery)
	if $$$ISERR(sc) do DisplayError^%apiOBJ(sc) q
	set sc=result.Execute(10000) if $$$ISERR(sc) do DisplayError^%apiOBJ(sc) q	
	set $Namespace = oldn	
	set i = 1		
	WHILE result.Next(.sc) {
			if $$$ISERR(sc) q	
			try {	    				
				do body.InsertAt($CLASSMETHOD(className,"getArrById",result.Data("ID")),i)	
				set i = i+1
			} catch ex {
				do $SYSTEM.Status.DisplayError($SYSTEM.Status.Error(ex.Code,ex.Data))
				do ##class(Utils.GetServiceResponse).FormJSON("500","Ошибка при работе с объектом: "_$system.Status.GetErrorText(ex.AsStatus(),"ru")) q	  
			} 		
	}
	
	
	 
			
	set i = ""
	do resultArr.SetAt(body,"data")		
 	do resultArr.SetAt("200","errorCode")
	do resultArr.SetAt("Получены все объекты","errorMessage")		
	do ##class(Utils.CacheJSON).EncodeLarge(resultArr)

	set IDs="",resultArr="",body="",list="", obj="",result="",sc=""
	*/
	
}

ClassMethod %ProcessResult(pSC As %Status, pResult As %DynamicObject = "") As %Status [ Internal ]
{
	set tSC = $$$OK
	if $$$ISERR(pSC) {
		//set tSC = ..StatusToJSON(pSC, .tJSON)
		if $isobject(tJSON) {
			set pResult = tJSON
		} else {
			set pResult = { "errors": [ { "error": "Unknown error parsing status code" } ] }
		}
	} elseif '$isobject(pResult) {
		set pResult = {}
	}
	if $g(%debug)'="" {
		//$$$IKRESTSTOPTIMER(total)
		set tIterator = %debug.timerStart.%GetIterator()
		while tIterator.%GetNext(.n,.s) {
			do %debug.timer.%Set(n, ($zh-s)_" (unfinished)")
		}
		do %debug.%Remove("timerStart")
		set pResult.debug = %debug
	}
	write pResult.%ToJSON()
	quit tSC
}

}