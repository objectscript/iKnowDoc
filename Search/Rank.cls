Class Search.Rank {

// Метод высчитывающий отношение искомых слов к всем словам на найденной странице
ClassMethod Frequency(domainid As %Integer, sourceidlist As %List, wordidlist As %List) As %Float
{
	//zn "docbook"
	// Получаем количество искомых слов(id искомых слов содержаться в wordidlist) в найденных страницах(которые состоят из источников, id источников содержаться в sourceidlist) 
	set numerator = ##class(Search.Domain).GetCountWordsBySource(domainid,sourceidlist,wordidlist)
	// Получаем количество всех слов в найденных страницах(которые состоят из источников, id источников содержаться в sourceidlist) 
	zn "docbook"
	set denominator = ##class(%iKnow.Queries.EntityAPI).GetOccurrenceCountBySource(domainid,sourceidlist)
	zn "docsearch"
	// Высчитываем и возвращаем отношение искомых слов к всем словам на найденной странице
	set frequency=numerator/denominator
	quit frequency
}

// Помоему не где не используется
ClassMethod Replace(domainid As %Integer, entitylist As %List, pagesize As %Integer) As %Library.ArrayOfObjects
{
	zn "docbook"
	set tSC = ##class(%iKnow.Queries.SourceAPI).GetByEntities(.tResult,domainid, entitylist,1,pagesize)
	zn "docsearch"  
	set array = ##class(%Library.ArrayOfObjects).%New()
	set i = ""
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
	}
	zw array
	quit array
}

}