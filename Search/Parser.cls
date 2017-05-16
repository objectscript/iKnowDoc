Class Search.Parser {

// Данные документации в БД храняться со всеми тегами, для дальнейшей вставки на страницу. Нам же теги не нужны,из-за этого из убираем
/// Парсер, заменяющий XML-теги в источниках на пробел:
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
		//замена html символов
		set text = $REPLACE(text,"&reg;","®")
		set text = $REPLACE(text,"&ntilde;","ñ")
		set text = $REPLACE(text,"&#39;","'")
		set text = $REPLACE(text,"&ldquo;","“")
		set text = $REPLACE(text,"&rdquo;","”")
		set text = $REPLACE(text,"&amp;","&")
		set text = $REPLACE(text,"&lt;","<")
		set text = $REPLACE(text,"&gt;",">")
		set text = $REPLACE(text,"&mdash;","—")
		set text = $REPLACE(text,"&eacute;","é")
		set text = $REPLACE(text,"&EACUTE;","É")
		set text = $REPLACE(text,"&ndash;","-")
		set text = $REPLACE(text,"&rsquo;","'")
		set text = $REPLACE(text,"&NTILDE;","Ñ")
		set text = $REPLACE(text,"\"," ")
		set text = $REPLACE(text,"/"," ")
		set text = $REPLACE(text,""""," ")
		//убирает скобки чтоб предотвратить конфликты с JSON
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
 		//убирает лишние пробелы после парсинга
  		set text = $REPLACE(text,"       "," ")
  		set text = $REPLACE(text,"      "," ")
  		set text = $REPLACE(text,"     "," ")
  		set text = $REPLACE(text,"    "," ")
  		set text = $REPLACE(text,"   "," ")
  		set text = $REPLACE(text,"  "," ")  
		quit text
}

/// Корректирует нестандартные символы в заголовках результатов поиска
ClassMethod ParseTitle(textTag) As %String
{
		set i =1
		set empty=" "
		set subtext=""
		set condition = 0
		set text = textTag
		set text = $REPLACE(text,"&reg;","®")
		set text = $REPLACE(text,"&ntilde;","ñ")
		set text = $REPLACE(text,"&#39;","'")
		set text = $REPLACE(text,"&ldquo;","“")
		set text = $REPLACE(text,"&EACUTE;","É")
		set text = $REPLACE(text,"&ndash;","-")
		set text = $REPLACE(text,"&rsquo;","'")
		set text = $REPLACE(text,"&NTILDE;","Ñ")
		set text = $REPLACE(text,"&rdquo;","”")
		set text = $REPLACE(text,"&amp;","&")
		set text = $REPLACE(text,"&lt;","<")
		set text = $REPLACE(text,"&gt;",">")
		set text = $REPLACE(text,"&mdash;","—")
		set text = $REPLACE(text,"&eacute;","é")
		quit text
}
}