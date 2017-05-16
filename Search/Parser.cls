Class Search.Parser {

// Р”Р°РЅРЅС‹Рµ РґРѕРєСѓРјРµРЅС‚Р°С†РёРё РІ Р‘Р” С…СЂР°РЅСЏС‚СЊСЃСЏ СЃРѕ РІСЃРµРјРё С‚РµРіР°РјРё, РґР»СЏ РґР°Р»СЊРЅРµР№С€РµР№ РІСЃС‚Р°РІРєРё РЅР° СЃС‚СЂР°РЅРёС†Сѓ. РќР°Рј Р¶Рµ С‚РµРіРё РЅРµ РЅСѓР¶РЅС‹,РёР·-Р·Р° СЌС‚РѕРіРѕ РёР· СѓР±РёСЂР°РµРј
/// РџР°СЂСЃРµСЂ, Р·Р°РјРµРЅСЏСЋС‰РёР№ XML-С‚РµРіРё РІ РёСЃС‚РѕС‡РЅРёРєР°С… РЅР° РїСЂРѕР±РµР»:
ClassMethod Parse(textTag) As %String
{ 
		set i =1
		set empty=" "
		set subtext=""
		set condition = 0
		set text = textTag
link	for i=1:1:$LENGTH(text)
		{
			set char = $EXTRACT(text,i)
			if (condition = 1) 
			{
			    set subtext=subtext_char 
			    
			}
			if (char=">")
			 {
				 set text = $REPLACE(text,subtext,empty,1,1)
				 set condition = 0
				 set subtext=""
				 set i=1
				 goto link
		     }
			if (char="<")
			 {
				 set subtext=subtext_char
				 set condition=1		 
			 }
			
		}
		//Р·Р°РјРµРЅР° html СЃРёРјРІРѕР»РѕРІ
		set text = $REPLACE(text,"&reg;","В®")
		set text = $REPLACE(text,"&ntilde;","Г±")
		set text = $REPLACE(text,"&#39;","'")
		set text = $REPLACE(text,"&ldquo;","вЂњ")
		set text = $REPLACE(text,"&rdquo;","вЂќ")
		set text = $REPLACE(text,"&amp;","&")
		set text = $REPLACE(text,"&lt;","<")
		set text = $REPLACE(text,"&gt;",">")
		set text = $REPLACE(text,"&mdash;","вЂ”")
		set text = $REPLACE(text,"&eacute;","Г©")
		set text = $REPLACE(text,"&EACUTE;","É")
		set text = $REPLACE(text,"\"," ")
		set text = $REPLACE(text,"/"," ")
		set text = $REPLACE(text,""""," ")
		//СѓР±РёСЂР°РµС‚ СЃРєРѕР±РєРё С‡С‚РѕР± РїСЂРµРґРѕС‚РІСЂР°С‚РёС‚СЊ РєРѕРЅС„Р»РёРєС‚С‹ СЃ JSON
		set text = $REPLACE(text,"{"," ")
		set text = $REPLACE(text,"}"," ")
		set text = $REPLACE(text,"["," ")
		set text = $REPLACE(text,"]"," ")
		set text = $REPLACE(text,"\n"," ")
  		set text = $REPLACE(text,"\s"," ")
  		set text = $REPLACE(text,"\t"," ")
  		set text = $REPLACE(text,"\f"," ")
  		set text = $REPLACE(text,"\d"," ")
  		set text = $REPLACE(text,"\a"," ")
 		set text = $REPLACE(text,"  "," ")
 		//СѓР±РёСЂР°РµС‚ Р»РёС€РЅРёРµ РїСЂРѕР±РµР»С‹ РїРѕСЃР»Рµ РїР°СЂСЃРёРЅРіР°
  		set text = $REPLACE(text,"       "," ")
  		set text = $REPLACE(text,"      "," ")
  		set text = $REPLACE(text,"     "," ")
  		set text = $REPLACE(text,"    "," ")
  		set text = $REPLACE(text,"   "," ")
  		set text = $REPLACE(text,"  "," ")  
		quit text
}

/// РљРѕСЂСЂРµРєС‚РёСЂСѓРµС‚ РЅРµСЃС‚Р°РЅРґР°СЂС‚РЅС‹Рµ СЃРёРјРІРѕР»С‹ РІ Р·Р°РіРѕР»РѕРІРєР°С… СЂРµР·СѓР»СЊС‚Р°С‚РѕРІ РїРѕРёСЃРєР°
ClassMethod ParseTitle(textTag) As %String
{
		set i =1
		set empty=" "
		set subtext=""
		set condition = 0
		set text = textTag
		set text = $REPLACE(text,"&reg;","В®")
		set text = $REPLACE(text,"&ntilde;","Г±")
		set text = $REPLACE(text,"&NTILDE;","Ñ")
		set text = $REPLACE(text,"&#39;","'")
		set text = $REPLACE(text,"&rsquo;","'")
		set text = $REPLACE(text,"&ldquo;","вЂњ")
		set text = $REPLACE(text,"&rdquo;","вЂќ")
		set text = $REPLACE(text,"&amp;","&")
		set text = $REPLACE(text,"&lt;","<")
		set text = $REPLACE(text,"&gt;",">")
		set text = $REPLACE(text,"&mdash;","вЂ”")
		set text = $REPLACE(text,"&ndash;","-")
		set text = $REPLACE(text,"&eacute;","Г©")
		set text = $REPLACE(text,"&EACUTE;","É")
		quit text
}
}