Class iKnowDoc.Search.Parser
{

// Documentation data in database is stored with all XML-tags for further web page display. We don't need these tags, hence parsing.
/// Parser that replaces XML-tags with space characters:
ClassMethod Parse(textTag) As %String
{
		set i =1
		set empty=""
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
		//html escape characters replacement
		/*set text = $REPLACE(text,"&reg;","®")
		set text = $REPLACE(text,"&ntilde;","ñ")
		set text = $REPLACE(text,"&NTILDE;","Ñ")
		set text = $REPLACE(text,"&#39;","'")
		set text = $REPLACE(text,"&rsquo;","'")
		set text = $REPLACE(text,"&ldquo;","“")
		set text = $REPLACE(text,"&rdquo;","”")
		set text = $REPLACE(text,"&amp;","&")
		set text = $REPLACE(text,"&lt;","<")
		set text = $REPLACE(text,"&gt;",">")
		set text = $REPLACE(text,"&mdash;","—")
		set text = $REPLACE(text,"&ndash;","-")
		set text = $REPLACE(text,"&eacute;","é")
		*/
		set text = $REPLACE(text,"&EACUTE;","É")
		set text = $REPLACE(text,"&NTILDE;","Ñ")
		//set text = $REPLACE(text,"\"," ")
		//set text = $REPLACE(text,"/"," ")
		//set text = $REPLACE(text,""""," ")

		//removing other characters to prevent JSON conflicts
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
		quit text
}

/// Converts html-characters to proper letters in search result headers
ClassMethod ParseTitle(textTag) As %String
{
		set text = textTag
		/*
		set text = $REPLACE(text,"&reg;","®")
		set text = $REPLACE(text,"&ntilde;","ñ")
		set text = $REPLACE(text,"&NTILDE;","Ñ")
		set text = $REPLACE(text,"&#39;","'")
		set text = $REPLACE(text,"&rsquo;","'")
		set text = $REPLACE(text,"&ldquo;","“")
		set text = $REPLACE(text,"&rdquo;","”")
		set text = $REPLACE(text,"&amp;","&")
		set text = $REPLACE(text,"&lt;","<")
		set text = $REPLACE(text,"&gt;",">")
		set text = $REPLACE(text,"&mdash;","—")
		set text = $REPLACE(text,"&ndash;","-")
		set text = $REPLACE(text,"&eacute;","é")
		*/
		set text = $REPLACE(text,"&NTILDE;","Ñ")
		set text = $REPLACE(text,"&EACUTE;","É")
		quit text
}

/// Removes tags in entity hints (GetSimilar method)
ClassMethod ParseHints(textTag) As %String
{
		set text = textTag
		set empty = ""
		set y = $LOCATE(text,"<.*>",,,substr1)
		set z = $LOCATE(text,">.*<",,,substr2)
		if y'=0 && z'=0 {
		set substr2 = $REPLACE(substr2,"<",empty)
		set substr2 = $REPLACE(substr2,">",empty)
		set text = $REPLACE(text,substr1,substr2)
		}
		set x1 = $LOCATE(text,"<.*>",,,substr)
		if x1'=0 {
		set text = $REPLACE(text,substr,empty)
		}
		set x2 = $LOCATE(text,"&mdash",,,substr)
		if x2'=0 {
		set text = $REPLACE(text,text,empty)
		}
		set x3 = $LOCATE(text,"/",,,substr)
		if x3'=0 {
		set text = $REPLACE(text,text,empty)
		}
		if (text="")
			{set text=" "}
		quit text
}

}
