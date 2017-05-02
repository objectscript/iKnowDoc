Class Search.SearchPages {

/// POST метод поиска по документации
// Пример запроса {"words":"iknow","phrase":"rest api","anyWords":"json, sql","without":"class, you, ifind, Enhancements"}
ClassMethod Search(obj) As %Status
{
	/*try {
	 		s %request.Content.Attributes("CharEncoding")="UTF8"
	  	 	s str = $ZCVT(%request.Content.Read(),"I","UTF8")
	  		$$$THROWONERROR(st,##class(%ZEN.Auxiliary.jsonProvider).%ConvertJSONToObject(str,,.obj,1))
	  		d ##class(Utils.DataQuery).FormQuery(obj,tableName, className)
	  	} catch ex {
	  	   set err = "Ошибка разбора JSON запроса"_$system.Status.GetErrorText(ex.AsStatus(),"ru")
	  	   set error1 = ##class(%DynamicObject).%New()
	  	   set error1.ErrorCode = err  		
	  	write "Ошибка: "_error1.%ToJSON()
	   } 
	
	q $$$OK
	*/

	try {
		s %request.Content.Attributes("CharEncoding")="UTF8"
		s str = $ZCVT(%request.Content.Read(),"I","UTF8")
		$$$THROWONERROR(st,##class(%ZEN.Auxiliary.jsonProvider).%ConvertJSONToObject(str,,.obj,1))
		d ##class(Search.SearchPages).FormQuery(obj)
    } catch ex {
       	set err = "Ошибка разбора JSON запроса"_$system.Status.GetErrorText(ex.AsStatus(),"ru")
       	set error1 = ##class(%DynamicObject).%New()
       	set error1.ErrorCode = err    
       	write " ошибка: "_error1.%ToJSON()    
    } 
 q $$$OK
}

// Метод формирования запроса к БД
ClassMethod FormQuery(obj) As %Status
{
	
	// Со словами:
	s words=obj.words
	// со словосочетанием: 
	s phrase=obj.phrase
	// с любым из этих слов:
	s anyWords=obj.anyWords
	// без слов:
	s without=obj.without
	
	
    s startRecord=obj.startRecord	
	s recordCount=obj.recordCount
	
	
	/*
	//Тестовые значения переменных
	s words = "iknow"
	s phrase= "rest api"
	s anyWords = "json, sql"
	s without = "class, you, ifind, Enhancements"
	*/	
	s text=""
	if words'="" {
		s text = text_words
	}

	if phrase'="" {
		s text = text_" ("_phrase_")"
	}
 
	if anyWords'="" {
		//Удаляем пробелы
		set anyWords = $REPLACE(anyWords," ","")  
		//Извлекаем до ,
		s listAny=$LISTFROMSTRING(anyWords,",")
		s strAny=" OR ("_$LIST(listAny,1)
		for i=2:1:$LISTLENGTH(listAny) {
			s strAny = strAny_" OR "_$LIST(listAny,i) 
			}
		s text = text_strAny_")"
	}

	// без слов:
	if without'="" {
		s text = text_")"
		//Удаляем пробелы
		set without = $REPLACE(without," ","")  
		//Извлекаем до ,
		s listOut=$LISTFROMSTRING(without,",")
		s strOut=" NOT ("_$LIST(listOut,1)
		for i=2:1:$LISTLENGTH(listOut) {
			s strOut = strOut_" OR "_$LIST(listOut,i) 
			}
		s text = "("_text
		s text = text_strOut_")"
	}
	
	//w "text: ",text
	
	////////////////////////////
	

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
	
	//w count
	//
	// Пагинация
	//s startRecord =1
	//s recordCount=20
	set commonCount = count
	if commonCount<startRecord s startRecord=1
	s offset=recordCount+startRecord-1	
	if (offset>commonCount) s recordCount=recordCount-(offset-commonCount)
	
	//
	
	//SET resultQuery = "SELECT JSON_OBJECT('idSQL':idSQL, 'content':content, 'link':link, 'frequency':frequency, 'title':title) FROM SQLUser.temptable ORDER BY frequency DESC"
  	//SET resultQuery = "SELECT JSON_OBJECT('idSQL':idSQL, 'content':{fn CONCAT(content,' ')}, 'link':link, 'frequency':frequency, 'title':title) FROM SQLUser.temptable ORDER BY frequency DESC"
  	
  	//SET resultQuery = "select TOP "_recordCount_" * from (SELECT TOP "_offset_" id,JSON_OBJECT('idSQL':id, 'content': {fn CONCAT(content,' ')},'link':link, 'frequency':frequency, 'title':title) FROM SQLUser.temptable ORDER BY frequency DESC) ORDER BY id DESC ORDER BY id ASC"
  	//SET resultQuery = " (select TOP "_recordCount_" * from (SELECT TOP "_offset_" id,content, link, frequency,title FROM SQLUser.temptable ORDER BY frequency DESC) ORDER BY frequency ASC)ORDER BY frequency DESC"
  	SET resultQuery = "select * from (select TOP "_recordCount_" * from (select TOP "_offset_" * from SQLUser.temptable order by frequency DESC) order by frequency ASC) order by frequency DESC"
  	//w count,!
  	//w resultQuery,!
  	//w resultQuery
  	SET Statement = ##class(%SQL.Statement).%New()
  	SET Status = Statement.%Prepare(resultQuery)
   	IF Status'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(Status) QUIT}
  	SET result = Statement.%Execute()
   	//WHILE result.%Next() {DO result.%Print(" ^ ")}

  	//set countZap=0
  	//s count = 99

  	//w "{""sources"":["
    /*WHILE result.%Next() {
     DO result.%Print(" ^ ")
     if ((countZap'=(recordCount-1))) {
      w ","
      s countZap=countZap+1 
     }
    }*/
    set ResultJSON = { "sources": [] }
    
    WHILE result.%Next() {
    	set tJSON = { "content":(result.content), "link":(result.link), "frequency": (result.frequency), "title": (result.title) }
		do ResultJSON.sources.%Push(tJSON)
    }

    
    
    
	//Удалим временную таблицу
    SET dropquery = "drop table SQLUser.temptable"
  	SET dropStatement = ##class(%SQL.Statement).%New()
  	SET dropStatus = dropStatement.%Prepare(dropquery)
   	IF dropStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(dropStatus) QUIT}
  	SET dropRset = dropStatement.%Execute()
	s st=$$$OK
	//q st

	quit ..%ProcessResult(st, $g(ResultJSON))
	/////////////////////////////////////////
	/*
	
		
	//w finalquery
	//выполняем новый запрос	
	s result=##class(%ResultSet).%New("%DynamicQuery:SQL")
 	s sc=result.Prepare(finalquery)
	If $$$ISERR(sc) d DisplayError^%apiOBJ(sc) q
	s sc=result.Execute(10000) If $$$ISERR(sc) d DisplayError^%apiOBJ(sc) q	
	s $Namespace = oldn	
	s i = 1		
	WHILE result.Next(.sc) {
			If $$$ISERR(sc) q	
			try {	    				
				d body.InsertAt($CLASSMETHOD(className,"getArrById",result.Data("ID")),i)	
				s i = i+1
			} catch ex {
				DO $SYSTEM.Status.DisplayError($SYSTEM.Status.Error(ex.Code,ex.Data))
				d ##class(Utils.GetServiceResponse).FormJSON("500","Ошибка при работе с объектом: "_$system.Status.GetErrorText(ex.AsStatus(),"ru")) q	  
			} 		
	}
	
	
	 
			
	s i = ""
	d resultArr.SetAt(body,"data")		
 	d resultArr.SetAt("200","errorCode")
	d resultArr.SetAt("Получены все объекты","errorMessage")		
	d ##class(Utils.CacheJSON).EncodeLarge(resultArr)

	s IDs="",resultArr="",body="",list="", obj="",result="",sc=""
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