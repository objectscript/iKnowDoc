Include %IKInclude
Class Search.Domain extends %Persistent {
// РќРµРѕС…РѕРґРёРјРѕ Р·Р°РїСѓСЃС‚РёС‚СЊ СЃР»РµРґСѓСЋС‰РµР№ РєРѕРјР°РЅРґРѕР№ РЅР° РІС‹РїРѕР»РЅРµРЅРёРµ(СЃРёР»СЊРЅРѕ РіСЂСѓР·РёС‚ РєРѕРјСЊСЋС‚РµСЂ, СЂРµРєРѕРјРµРЅРґСѓРµС‚СЃСЏ Р·Р°РєСЂС‹С‚СЊ РѕСЃС‚Р°Р»СЊРЅС‹Рµ РїСЂРѕРіСЂР°РјРјС‹)
// do ##class(Search.Domain).%Build()
// Р’С‹РїРѕР»РЅСЏРµС‚СЃСЏ РјРёРЅСѓС‚ 5-10
// РџРѕСЃР»Рµ СЃРѕР·РґР°РЅРёСЏ РґРѕРјРµРЅР°, РїСЂРѕРІРµСЂРёС‚СЊ РєРѕРјР°РЅРґРѕР№ РІ РѕР±Р»Р°СЃС‚Рё DOCBOOK Рё РЅР°Р№С‚Рё РЅР°Р·РІР°РЅРёРµ РґРѕРјРµРЅР° РІ РІС‹РІРµРґРµРЅРЅРѕРј СЃРїРёСЃРєРµ
// do $system.iKnow.ListDomains()
/// РњРµС‚РѕРґ СЃРѕР·РґР°РЅРёСЏ РґРѕРјРµРЅР°, РїРѕСЃС‚СЂРѕРµРЅРёСЏ СЃС‚СЂСѓРєС‚СѓСЂС‹ РґРѕРјРµРЅР° Рё Р·Р°РїРѕР»РЅРµРЅРёСЏ РµРіРѕ РґР°РЅРЅС‹РјРё
ClassMethod %Build() As %Status
{
	#Include %IKPublic
	znspace "DOCBOOK"
	// РЎРѕР·РґР°РЅРёРµ РґРѕРјРµРЅР° РёР»Рё РѕС‚РєСЂС‹С‚РёРµ РµСЃР»Рё РѕРЅ СЃСѓС‰РµСЃС‚РІСѓРµС‚
	set dname="DocSearch"  
   	if (##class(%iKnow.Domain).Exists(dname)){
	   	set domoref=##class(%iKnow.Domain).Open(dname)
    }
  	else {	 
  		write "The ",dname," domain does not exist",!
       	set domoref=##class(%iKnow.Domain).%New(dname)
       	do domoref.%Save()
    }	
   	set domId=domoref.Id
   	// Lister РёСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ РґР»СЏ РїРѕРёСЃРєР° РёСЃС‚РѕС‡РЅРёРєРѕРІ, СЃРѕРѕС‚РІРµС‚СЃС‚РІСѓСЋС‰РёС… Р·Р°РїРёСЃСЏРј РІ СЂРµР·СѓР»СЊС‚Р°С‚Р°С… Р·Р°РїСЂРѕСЃР°
  	set flister=##class(%iKnow.Source.SQL.Lister).%New(domId)
  	//Loader РєРѕРѕСЂРґРёРЅРёСЂСѓРµС‚ РїСЂРѕС†РµСЃСЃ Р·Р°РіСЂСѓР·РєРё.
  	set myloader=##class(%iKnow.Source.Loader).%New(domId)
  	// РџРѕСЃС‚СЂРѕРµРЅРёРµ Р·Р°РїСЂРѕСЃР°
	set myquery="SELECT id,content, blockid, component->blockid As component_blockid, component->title As component_title, book->blockid As book_blockid, book->title As book_title FROM DocBook.block"
 	set idfld="id"
 	set grpfld="id"
 	// РЈРєР°Р·С‹РІР°РµРј РїРѕР»СЏ РґР°РЅРЅС‹С… Рё РјРµС‚Р°РґР°РЅРЅС‹С…
  	set dataflds=$LB("content")
  	set metaflds=$LB("id","blockid","component_blockid","component_title","book_blockid","book_title")
  	//РњРµС‚Р°РґР°РЅРЅС‹Рµ
	set val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"id",$LB("="),$$$MDDTNUMBER)
	set val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"blockid",$LB("="),$$$MDDTSTRING)
	set val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"component_blockid",$LB("="),$$$MDDTSTRING)
	set val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"component_title",$LB("="),$$$MDDTSTRING)
	set val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"book_blockid",$LB("="),$$$MDDTSTRING)
	set val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"book_title",$LB("="),$$$MDDTSTRING)
  	//Р—Р°РЅРµСЃРµРј РІСЃРµ РґР°РЅРЅС‹Рµ РІ Lister
  	set stat=flister.AddListToBatch(myquery,idfld,grpfld,dataflds,metaflds)
      if stat '= 1 {write "The lister failed: ",$System.Status.DisplayError(stat) quit }
    //Р—Р°РїСѓСЃРєР°РµРј РїСЂРѕС†РµСЃСЃ Р°РЅР°Р»РёР·Р°
    set stat=myloader.ProcessBatch()
      if stat '= 1 {
	      quit 
	       }
   //Р¤СѓРЅРєС†РёРѕРЅР°Р»
    set numSrcD=##class(%iKnow.Queries.SourceQAPI).GetCountByDomain(domId)
  	write "Р”РѕРјРµРЅ СЃРѕР·РґР°РЅ",!
  	write "Р”РѕРјРµРЅ СЃРѕРґРµСЂР¶РёС‚ ",numSrcD," РёСЃС‚РѕС‡РЅРёРєРѕРІ",! 
    znspace "DOCSEARCH" 
  	quit stat
}

/// РњРµС‚РѕРґ РїРѕРёСЃРєР° РїРѕРґРѕР±РЅС‹С… СЃСѓС‰РЅРѕСЃС‚РµР№. Р’РѕР·РІСЂР°С‰Р°РµС‚ JSON СЃРѕРґРµСЂР¶Р°С‰РёР№ 10 СЃСѓС‰РЅРѕСЃС‚РµР№ РїРѕРґРѕР±РЅС‹С… РІС…РѕРґРЅРѕР№ СЃС‚СЂРѕРєРµ.
ClassMethod GetSimilar(SearchString) As %Status
{
	znspace "DOCBOOK"
	// РћС‚РєСЂС‹РІР°РµРј РґРѕРјРµРЅ Рё РїРѕР»СѓС‡Р°РµРј РµРіРѕ Id
	set dname="DocSearch" 
	set domoref=##class(%iKnow.Domain).Open(dname)
	set domId=domoref.Id
	// Р�СЃРїРѕР»СЊР·СѓСЏ %iKnow РїРѕР»СѓС‡Р°РµРј 10 СЃСѓС‰РЅРѕСЃС‚РµР№ РїРѕРґРѕР±РЅС‹С… РІС…РѕРґРЅРѕР№ СЃС‚СЂРѕРєРµ.
	set SC = ##class(%iKnow.Queries.EntityAPI).GetSimilar(.Result, domId, SearchString,,11)
	znspace "DOCSEARCH"
	quit:$$$ISERR(SC) ""
	// Р¤РѕСЂРјРёСЂСѓРµРј РґРёРЅР°РјРёС‡РµСЃРєРёР№ РѕР±СЊРµРєС‚
	set ResultJSON = { "entities": [] }
	// РџРѕР»СѓС‡Р°РµРј РґР°РЅРЅС‹Рµ РёР· Result Рё Р·Р°РїРѕР»РЅСЏРµРј РґРёРЅР°РјРёС‡РµСЃРєРёР№ РѕР±СЊРµРєС‚
    for i=1:1:10 {
    	set Рѕrd = $order(Result(i),1,Data)
    	set tJSON = { "value":(##class(Search.Parser).Parse($li(Data,2))) }
		do ResultJSON.entities.%Push(tJSON)
    }   
    // РџСЂРµРѕР±СЂР°Р·СѓРµРј РґРёРЅР°РјРёС‡РµСЃРєРёР№ РѕР±СЊРµРєС‚ РІ JSON
    write ResultJSON.%ToJSON()
    quit SC	
}

/* 
	iKnow РїРѕР·РІРѕР»СЏРµС‚ РїРѕРґСЃС‡РёС‚Р°С‚СЊ РєРѕР»РёС‡РµСЃС‚РІРѕ РІСЃРµС… СЃСѓС‰РЅРѕСЃС‚РµР№ РІ СЃРїРёСЃРєРµ РёСЃС‚РѕС‡РЅРёРєРѕРІ
	РќРѕ РЅРµ РїРѕР·РІРѕР»СЏРµС‚ РїРѕРґСЃС‡РёС‚Р°С‚СЊ РєРѕР»РёС‡РµСЃС‚РІРѕ РѕРїСЂРµРґРµР»РµРЅРЅС‹С… СЃСѓС‰РЅРѕСЃС‚РµР№ РІ СЃРїРёСЃРєРµ РёСЃС‚РѕС‡РЅРёРєРѕРІ. 
	Р”Р»СЏ СЌС‚РёС… С†РµР»РµР№ Р±С‹Р» РЅР°РїРёСЃР°РЅ РјРµС‚РѕРґ РЅР° РѕСЃРЅРѕРІРµ РјРµС‚РѕРґР° 
	%iKnow.Queries.EntityAPI.GetOccurrenceCountBySource(domainid,sourceidlist)
*/
/// РњРµС‚РѕРґ РІРѕР·РІСЂР°С‰Р°СЋС‰РёР№ РєРѕР»РёС‡РµСЃС‚РІРѕ РёСЃРєРѕРјС‹С… СЃР»РѕРІ(id РёСЃРєРѕРјС‹С… СЃР»РѕРІ СЃРѕРґРµСЂР¶Р°С‚СЊСЃСЏ РІ wordidlist) РІ РЅР°Р№РґРµРЅРЅС‹С… СЃС‚СЂР°РЅРёС†Р°С…(РєРѕС‚РѕСЂС‹Рµ СЃРѕСЃС‚РѕСЏС‚ РёР· РёСЃС‚РѕС‡РЅРёРєРѕРІ, id РёСЃС‚РѕС‡РЅРёРєРѕРІ СЃРѕРґРµСЂР¶Р°С‚СЊСЃСЏ РІ sourceidlist)
ClassMethod GetCountWordsBySource(domainid As %Integer, sourceidlist As %List, wordidlist As %List, Output sc As %Status = {$$$OK}, enttype As %Integer = {$$$ENTTYPEANY}) As %Integer
{
	zn "docbook"
	$$$IKQBEGINR("",sc,-1)
	if (domainid'=0) { $$$CHECKDOMAINEXISTSR(domainid,sc,-1) }
	quit:sourceidlist="" 0
	set tVersionTables = $$$IKVERSIONATLEAST(domainid,$$$IKVERSIONTABLES)
	// accepting single source IDs (non-list) as well
	$$$IKENSURELISTNUM(sourceidlist)
	set total = 0, ptr = 0
	while $listnext(sourceidlist, ptr, srcId) {
		continue:'+srcId
		$$$CHECKASRCIDEXISTSX(domainid,srcId,srcDetails,vSrcId,sc)
		if (enttype = $$$ENTTYPEANY) && 'tVersionTables {
			set total = total + $lg(srcDetails,4)
		} else {
			set gEntOccId = $$$IKVGLOBNAME(domainid,"EntOccId",vSrcId)
			set tFrom = $lg(srcDetails,3)+1, tTo = tFrom+$lg(srcDetails,4)-1
			for tPartId = tFrom:1:tTo {
				// tEntOcc СЃРѕРґРµСЂР¶РёС‚ id СЃСѓС‰РЅРѕСЃС‚РµР№ РёСЃС‚РѕС‡РЅРёРєР°.
				set tEntOcc = @gEntOccId@(tPartId)
				set pointer = 0
				set value = 0
				// РЎ РїРѕРјРѕС‰СЊСЋ $listnext РїСЂРѕС…РѕРґРёРј РїРѕ СЃРїРёСЃРєСѓ id С‚РµС… СЃСѓС‰РЅРѕСЃС‚РµР№ С‡С‚Рѕ РёС‰РµРј Рё СЃСЂР°РІРЅРёРІР°РµРј РёС… СЃ С‚РµРјРё С‡С‚Рѕ РІ РёСЃС‚РѕС‡РЅРёРєРµ
				while $listnext(wordidlist, pointer, value)
				{
					if value=$lg(tEntOcc,1)
					{
						s x = $i(total)
					}	
				}
			}
		}
	}
	zn "docsearch"
	quit:$$$ISERR(sc) -1
	
	quit total
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

