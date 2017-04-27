Class Search.Parser {
 
/// Парсер, заменяющий XML-теги на пробел:
ClassMethod Parse(textTag) As %String
{
		set i =1
		set empty=" "
		set subtext=""
		set condition = 0
		s text = textTag
link	For i=1:1:$LENGTH(text)
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
			IF (char="<")
			 {
				 set subtext=subtext_char
				 set condition=1		 
			 }
			
		}
		set text = $REPLACE(text,"\"," ")
		set text = $REPLACE(text,"/"," ")
		set text = $REPLACE(text,""""," ")
		set text = $REPLACE(text,";",",")
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
  		set text = $REPLACE(text,"       "," ")
  		set text = $REPLACE(text,"      "," ")
  		set text = $REPLACE(text,"     "," ")
  		set text = $REPLACE(text,"    "," ")
  		set text = $REPLACE(text,"   "," ")
  		set text = $REPLACE(text,"  "," ")  
		q text
}

ClassMethod Frequency(text, word) As %Float
{
		set frequency = 0
		// Посмотреть для сложных запросов
		set frequency = $LENGTH(text,word) / $LENGTH(text, " ")
		q frequency
}

}