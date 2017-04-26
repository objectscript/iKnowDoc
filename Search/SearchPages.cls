Class Search.SearchPages {

/// POST метод поиска по документации
ClassMethod Search(text) As %Status
{
	try {
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
}

// Метод формирования запроса к БД
ClassMethod FormQuery(obj)
{
    s startRecord=obj.startRecord	
	s recordCount=obj.recordCount
	
	
	s condition=""	
	for i=1:1:obj.filters.Count() {	
		s field=obj.filters.GetAt(i).field
	 	s val=obj.filters.GetAt(i).value
	 	s comp=obj.filters.GetAt(i).comparsion
	 	s type=obj.filters.GetAt(i).type		 	
		s str=..FormFiltersCondition(field,val,comp,type, withHistory, tableName)		 	  
		if str'="" {									
				s condition=condition_str_" AND "								
			}
	}
	s oldn = "RMIS"
	s security = ""
	if (tableName [ "Security.Roles") {
		s security = " Name NOT LIKE '\%%' ESCAPE '\'  AND Name!='MPRL_Master'   AND Name!='MPRL_Operator'"	
	}
		
	if condition '= "" {		
		s condition=$extract(condition,1,$length(condition)-4)				
		if security '= "" s condition = " where "_condition_" AND "_security
		else  s condition = " where "_condition  				
	} else {
		if security '= "" {s condition = " where "_security}
		elseif onlyEtalon = 1 {s condition = " where etalon = 1 "} 			
	}
		
	s query="select count(ID) as rowcount from "_tableName_condition
	s resultArr = ##class(%ArrayOfDataTypes).%New()	
	s body = ##class(%ListOfDataTypes).%New()
	
	//Считаем количество отфильтрованных записей
	
	//w query	
	if (tableName [ "Security") {		
		s $Namespace = "%SYS"		
	}	
	s result=##class(%ResultSet).%New("%DynamicQuery:SQL")
 	s sc=result.Prepare(query)
	If $$$ISERR(sc) d DisplayError^%apiOBJ(sc) q
	s sc=result.Execute(10000) If $$$ISERR(sc) d DisplayError^%apiOBJ(sc) q	
	
	//Помещаем в ответ их количество	
	WHILE result.Next(.sc) {
		If $$$ISERR(sc) q		
		s totalCount=result.Data("rowcount")
		d resultArr.SetAt(totalCount,"totalCount")
	}	
	s $Namespace = oldn
	s finalquery=..FormSortConditions(sortField,direction,condition,startRecord,recordCount,withHistory,totalCount, tableName)
	if (tableName [ "Security") {		
		s $Namespace = "%SYS"		
	}	
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
	q
}



}