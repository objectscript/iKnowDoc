Class Search.SearchPages {

/// POST метод поиска по документации
// Пример запроса {"words":"iknow","phrase":"rest api","anyWords":"json, sql","without":"class, you, ifind, Enhancements", startRecord:1, recordCount:20}
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
       	write " ошибка: "_error.%ToJSON()    
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

	set without=obj.without
	
	
    set startRecord=obj.startRecord	
	set recordCount=obj.recordCount
	
	set text=""
	set wordText=""
	
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
		//set wordText=wordText_" "_$REPLACE(anyWords,","," ")
		set anyWords = $REPLACE(anyWords," ","") 
		//Извлекаем до ,
		set listAny=$LISTFROMSTRING(anyWords,",")
		set strAny=" OR ("_$LIST(listAny,1)
		set strAnyWord=$LIST(listAny,1)
		for i=2:1:$LISTLENGTH(listAny) {
			set strAny = strAny_" OR "_$LIST(listAny,i)
			//set strAnyWord = strAnyWord_" "_$LIST(listAny,i)
			}
		set text = text_strAny_")"
	}
		
	s wordList=$LISTFROMSTRING(wordText, " ")
	
	s currPoint=0
	s currWord=0
	s textId=""
	s cntList=0
	zn "DOCBOOK"
	set id = ##class(%iKnow.Queries.EntityAPI).GetId(9,$LISTGET(wordList,1))
	zn "DOCSEARCH"
	s textId=textId_id
	while $LISTNEXT(wordList,currPoint,currWord) {
		if cntList>0{
			zn "DOCBOOK"
			set id = ##class(%iKnow.Queries.EntityAPI).GetId(9,currWord)
			zn "DOCSEARCH"
			s textId=textId_" "_id
		}
		set cntList = cntList+1
	}
	//w "textId ",textId,!
	s wordIdList=$LISTFROMSTRING(textId, " ")
	
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
	//w "List ", wordIdList,!
	//zw wordIdList
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
	set myquery = "SELECT id,content, component->blockid As link,book->title As title FROM DocBook.block WHERE %ID %FIND search_index(contentInd,?,0)"
  	
  	set tStatement = ##class(%SQL.Statement).%New()
  	SET qStatus = tStatement.%Prepare(.myquery)
    IF qStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(qStatus) QUIT}
    SET rset = tStatement.%Execute(text)
  	
  	
  	/*set tStatement = ##class(%SQL.Statement).%New()
  	set qStatus = tStatement.%Prepare(myquery)
   	if qStatus'=1 {write "%Prepare failed:" do $System.Status.DisplayError(qStatus) quit}
  	set rset = tStatement.%Execute()*/
  	while rset.%Next() {
	  	znspace "DOCSEARCH"
	  	set tempArray(count,0)= rset.id
	  	set tempArray(count,1) = ##class(Search.Parser).Parse(rset.content)
    	set tempArray(count,2) = rset.link
    	set tempArray(count,3) = 0 //##class(Search.Parser).Frequency(tempArray(count,1),text)
    	set tempArray(count,4) = rset.title
    	set count = count + 1
    	znspace "DOCBOOK"
       } 
    // Получаем данные с временной таблицы отсортированные по частоте
    znspace "DOCSEARCH"
	set count = count - 1
	
	//По всем разным set tempArray(count,2) т.е. линкам пройти и получить id
    s textLink=tempArray(0,2)
	for i=0:1:count-1{
		if (tempArray(i,2)'=tempArray(i+1,2)) && (tempArray(i+1,2)'=""){
		s textLink = textLink_", "_tempArray(i+1,2)
		}
	}
	s listLink = $LISTFROMSTRING(textLink, ", ")
	
	s currPoint=0
	s currLink=0
	s countSourses=0
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
	   
	   // Замена
	   //w "wordIdList ",wordIdList
	   
	   
	   
	zn "docbook"
	//set tSC = ##class(%iKnow.Queries.SourceAPI).GetByEntities(.tResult,9, $LB("iFind"),1,50)
	set tSC = ##class(%iKnow.Queries.SourceAPI).GetByEntities(.tResult,9, wordList,1,50)
	
	
	zn "docsearch" 
	
	
	set array = ##class(%Library.ArrayOfObjects).%New()
	
	set i = ""
	set cntArray=0
    for {
	    set i = $order(tResult(i),1,tSrcData)
	    quit:i=""	
		set string=$lg(tSrcData,2)
		
		
		set nul=$FIND(string,":",1)-1 
		set from=$FIND(string,":",nul+1)-1
		//w "from ",from,!
	 
		set to=$FIND(string,":",from+1)-1
		
		//w "to ",to,!
		
		// sql 
		set substr=$EXTRACT(string,from+1,to-1)
		// source
		set first = $lg(tSrcData,1)
		//w "first 	",first,!
		//w "substr 	",substr,!
		
		set array(i,0)=substr
		//w "array(i,0) ",array(i,0),!
		set array(i,1)=first
		//w "array(i,1) ", array(i,1),!
		set cntArray=cntArray+1
	}
	//w "cntArray ",cntArray
	set tempIdNew=""
	
	   for i=1:1:cntArray {
	   		//w !,array(i,0),"	",array(i,1),!
	   		set tempId=$Replace(tempId, array(i,0),array(i,1))   
	   } 
	 /*w !,"tempId ",tempId
	 w !,"tempIdNew ", tempIdNew*/
	   
	   // Массив с ИД источников 
	   set idArr(currLink) =$LISTFROMSTRING(tempId, " ")
	   s countSourses=countSourses+1
	}
	
	znspace "DOCSEARCH"
	//zw idArr
	s countSourses=countSourses-1
	s currPoint=0
	s currLink=0
	while $LISTNEXT(listLink,currPoint,currLink) {
		//w "currLink ", currLink,! 
		//w "wordIdList ",wordIdList,!
		s frequency(currLink)= ##class(Search.Rank).Frequency(9,idArr(currLink),wordIdList)
		
	}
	
	for i=0:1:count {
		if tempArray(i,2)'="" {
			set tempArray(i,3) = frequency(tempArray(i,2)) //##class(Search.Parser).Frequency(tempArray(count,1),text)
    	}
    	//w i, "    ",tempArray(i,3),!
	}
	 
	//Тут запись по строчно в ввременную таблицу
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

	set resultQuery = "select * from (select TOP "_recordCount_" * from (select TOP "_offset_" * from SQLUser.temptable order by frequency DESC) order by frequency ASC) order by frequency DESC"
  	set Statement = ##class(%SQL.Statement).%New()
  	set Status = Statement.%Prepare(resultQuery)
   	if Status'=1 {write "%Prepare failed:" do $System.Status.DisplayError(Status) quit}
  	set result = Statement.%Execute()
   	
   	set resultQuery = "select * from (select TOP "_recordCount_" * from (select TOP "_offset_" * from SQLUser.temptable order by frequency DESC) order by frequency ASC) order by frequency DESC"
  	set Statement = ##class(%SQL.Statement).%New()
  	set Status = Statement.%Prepare(resultQuery)
   	if Status'=1 {write "%Prepare failed:" do $System.Status.DisplayError(Status) quit}
  	set result = Statement.%Execute()
   	
    set ResultJSON = { "sources": [] }
    while result.%Next() {
    	set tJSON = { "content":(result.content), "link":(result.link), "frequency": (result.frequency), "title": (result.title) }
		do ResultJSON.sources.%Push(tJSON)
    }
    set totalCountJ = {"totalCount":(+count)}
    do ResultJSON.sources.%Push(totalCountJ)
    
	//Удалим временную таблицу
    
    set dropquery = "drop table SQLUser.temptable"
  	set dropStatement = ##class(%SQL.Statement).%New()
  	set dropStatus = dropStatement.%Prepare(dropquery)
   	if dropStatus'=1 {write "%Prepare failed:" do $System.Status.DisplayError(dropStatus) quit}
  	set dropRset = dropStatement.%Execute()
	set st=$$$OK
	//q st

	quit ..%ProcessResult(st, $g(ResultJSON))
	
	
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