Class iKnowDoc.Search.SearchPages
{

// POST request example  {"words":"iknow","phrase":"rest api","anyWords":"json, sql","without":"class, you, ifind, Enhancements", startRecord:1, recordCount:20}
/// POST-type method for documentation search
ClassMethod Search(obj) As %Status
{
 
	try {
		set %request.Content.Attributes("CharEncoding")="UTF8"
		set str = $ZCVT(%request.Content.Read(),"I","UTF8")
		$$$THROWONERROR(st,##class(%ZEN.Auxiliary.jsonProvider).%ConvertJSONToObject(str,,.obj,1))
		do ##class(iKnowDoc.Search.SearchPages).FormQuery(obj)
    } catch ex {
       	set count=0
       	set ResultJSON = { "sources": [], "totalCount":[]}
    	set totalCountJSON = {"total":(count)}
 	    do ResultJSON.totalCount.%Push(totalCountJSON)
 	    write ResultJSON.%ToJSON()  
    } 
 quit $$$OK
}

/// Method of forming a database request
ClassMethod FormQuery(obj) As %Status
{
	// Getting the search options:
	// all these words:
	//set words=obj.words
	set words= $ZCONVERT(obj.words,"O","HTML")
	set words = $REPLACE(words,"é","&eacute;")
	set words = $REPLACE(words,"ñ","&ntilde;")
	// this exact word or phrase:
	set phrase=obj.phrase
	// any of these words:
	set anyWords=obj.anyWords
	// none of these words:
	set without=obj.without
	// Parameters required for pagination
	// Record start
    set startRecord=obj.startRecord	
    // Number of records per page
	set recordCount=obj.recordCount
	// Fuzzy Search
	set fuzzy = obj.fuzzy
	if obj.fuzzy=1{
		set fuzzy="3:1"
	} else {
		set fuzzy="0"
	}
	// Use TFIDF Rank algorithm
	set rank = obj.rank
	// Variable containing text for iFind query according to formatting required for iFind
	set text=""
	// Variable containing query text without formatting. Required for getting Id of words, used by iKnow
	set wordText=""
	// Assigning variables depending on data that was received by front-end
	if words'="" {
		if $LENGTH(words," ")>1 {
			set listW=$LISTFROMSTRING(words," ")
			for i=1:1:$LISTLENGTH(listW) {
				if $LIST(listW,i)="not" || $LIST(listW,i)'="and" || $LIST(listW,i)'="or" {
					set text=text_" \"_$LIST(listW,i)
				} else {
					set text=text_" "_$LIST(listW,i)
				}
			}
		} else {
			set text = text_words
		}
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
		// removing spaces
		set anyWords = $REPLACE(anyWords," ","") 
		// Extracting up to ,
		set listAny=$LISTFROMSTRING(anyWords,",")
		set strAny=" AND ("_$LIST(listAny,1)
		set strAnyWord=$LIST(listAny,1)
		for i=2:1:$LISTLENGTH(listAny) {
			set strAny = strAny_" OR "_$LIST(listAny,i)
			}
		set text = text_strAny_")"
	} else {
		set listAny = $Listfromstring("")
	}
	
	if without'="" {
		if anyWords'="" {
			set text = text_")"
			// Removing spaces
			//set without = $REPLACE(without," ","")  
			// Extracting up to ,
			set listOut=$LISTFROMSTRING(without,",")
			set strOut=" NOT ("_$LIST(listOut,1)
			set strOrOut=$LIST(listOut,1)
			for i=2:1:$LISTLENGTH(listOut) {
				set strOut = strOut_" OR "_$LIST(listOut,i) 
				set strOrOut=strOrOut_" OR "_$LIST(listOut,i)
				}
			set text = "("_text
			set text = text_strOut_")"
		} else {
			// Removing spaces
			//set without = $REPLACE(without," ","")  
			// Extracting up to ,
			set listOut=$LISTFROMSTRING(without,",")
			set strOut=" NOT ("_$LIST(listOut,1)
			set strOrOut=$LIST(listOut,1)
			for i=2:1:$LISTLENGTH(listOut) {
				set strOut = strOut_" OR "_$LIST(listOut,i) 
				set strOrOut=strOrOut_" OR "_$LIST(listOut,i)
				}
			set text = text_strOut_")"
		}
	}
	// List of words in query
	set wordList=$LISTFROMSTRING(wordText, " ")
	
	// Pagination
	// Getting number of all elements
	set myquery = "select count(*) as CountText from (select * from (select component->blockid AS docKey, component->title AS title,book->blockid AS bookKey, book->title AS bookTitle FROM DocBook.block WHERE %ID %FIND search_index(contentInd,?,?))group by title)"
	set tStatement = ##class(%SQL.Statement).%New()
  	set qStatus = tStatement.%Prepare(.myquery)
    IF qStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(qStatus) QUIT}
    set rset = tStatement.%Execute(text,fuzzy)
    while rset.%Next() {
    	set count=rset.CountText
    }

    // "No results found" exception handler
     if count=0{
     	set ResultJSON = { "sources": [], "totalCount":[]}
    	set totalCountJSON = {"total":(count)}
 	    do ResultJSON.totalCount.%Push(totalCountJSON)
 	    write ResultJSON.%ToJSON()
 	    quit 0 
 	}

	set commonCount = count
	if commonCount<startRecord set startRecord=1
	set offset=recordCount+startRecord-1	
	if (offset>commonCount) set recordCount=recordCount-(offset-commonCount)

  	// Data table query
  	// TODO frequency sorting in iFind doesn't work fast enough due to DB containg text paragraphs, not text of a whole page.
  	if rank = 1 {
  		set resultQuery = "select * from (select TOP ? * from (select TOP ? * from(select count(*) as cnt,* from(select *, sum(RankOne) as Rank from (select component->blockid AS docKey, component->title AS title,book->blockid AS bookKey, book->title AS bookTitle, DocBook.block_contentIndRank(%ID, ?, ?) RankOne FROM DocBook.block WHERE %ID %FIND search_index(contentInd,?,?)) group by title)) order by RANK DESC,title DESC) order by RANK ASC,title ASC) order by RANK DESC,title DESC"  	
  	} else {
  		set resultQuery = "select * from (select TOP ? * from (select TOP ? * from(select count(*) as cnt,* from(select *, count(*) as Rank from (select component->blockid AS docKey, component->title AS title,book->blockid AS bookKey, book->title AS bookTitle FROM DocBook.block WHERE %ID %FIND search_index(contentInd,?,?)) group by title))order by RANK DESC,title DESC) order by RANK ASC,title ASC) order by RANK DESC,title DESC"  	
  	}
  	//set resultQuery = "select * from (select TOP "_recordCount_" * from (select TOP "_offset_" * from(select count(*) as cnt,* from(select *, sum(RankOne) as Rank from (select component->blockid AS docKey, component->title AS title,book->blockid AS bookKey, book->title AS bookTitle, DocBook.block_contentIndRank(%ID, ?, '0') RankOne FROM DocBook.block WHERE %ID %FIND search_index(contentInd,?,?))order by RANK DESC,title DESC) order by RANK ASC,title ASC) order by RANK DESC,title DESC"  	
	//set resultQuery = "select * from (select TOP "_recordCount_" * from (select TOP "_offset_" * from(select count(*) as cnt,* from(select *, count(*) as Rank from (select component->blockid AS docKey, component->title AS title,book->blockid AS bookKey, book->title AS bookTitle FROM DocBook.block WHERE %ID %FIND search_index(contentInd,?,?)) group by title))order by RANK DESC,title DESC) order by RANK ASC,title ASC) order by RANK DESC,title DESC"  	
	
	set Statement = ##class(%SQL.Statement).%New()
  	set Status = Statement.%Prepare(resultQuery)
   	if Status'=1 {write "%Prepare failed 1:" do $System.Status.DisplayError(Status) quit}
  	if rank = 1{
  		set result = Statement.%Execute(recordCount,offset,text,fuzzy,text,fuzzy)
  	} else {
  		set result = Statement.%Execute(recordCount,offset,text,fuzzy)
  	}
   	// Forming a dynamic object 
    set ResultJSON = { "sources": [], "totalCount":[]}
    while result.%Next() {
    	// Assigning array with data
    	set tJSON = {"textInfo":[], "docKey": (result.docKey) ,"title": (##class(iKnowDoc.Search.Parser).ParseTitle(result.title)),   "bookKey": (result.bookKey) ,"bookTitle": (result.bookTitle) }
		// Forming a query for receiving text for every page
	  	set subresultQuery = "select DocBook.block_contentIndHighlight(%ID, ?, '0', '<span class=""Illumination"">', 0) text,blockid AS textKey,component->blockid AS docKey from DocBook.block where %ID %FIND search_index(contentInd,?,?) and component->blockid=?"
	  	set subStatement = ##class(%SQL.Statement).%New()
	  	set subStatus = subStatement.%Prepare(subresultQuery)
	   	if subStatus'=1 {write "%Prepare failed 2:" do $System.Status.DisplayError(subStatus) quit}
	  	set subresult = subStatement.%Execute(text,text,fuzzy,result.docKey)
	  	while subresult.%Next() {
	  		if subresult.text'="" {
		  		set subtextKey = result.docKey_"#"_subresult.textKey
		  		//set textInfoJSON = {"text":(subresult.text), "textKey":(subtextKey)}
		  		set textInfoJSON = {"text":($ZCONVERT(subresult.text,"I","HTML")), "textKey":(subtextKey)}
		  		do tJSON.textInfo.%Push(textInfoJSON)
		  	}
	  	}
	  	set totalCount=result.cnt
		do ResultJSON.sources.%Push(tJSON)		
    }
    // Setting JSON with total number of found results
    set totalCountJSON = {"total":(totalCount)}
    do ResultJSON.totalCount.%Push(totalCountJSON)
	set st=$$$OK
	// Converting dynamic object into JSON
	write ResultJSON.%ToJSON()
	quit st
}

}
