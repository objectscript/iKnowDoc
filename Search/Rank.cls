Class Search.Rank {

ClassMethod Ranking(SearchString As %String) As %Float
{
	set rank=0
	set wordArray = ##class(%ArrayOfDataTypes).%New()
	//смотрит одно ли слово в запросе или несколько
	set multiplewords = 0
	for i=1:1:$length(SearchString)
    	{
    		set chara = $EXTRACT(SearchString,i)
    		if (chara = " ")
    		{
    			set multiplewords = 1
    			quit
    		}
    	}
    if (multiplewords = 0) 
    { 
    set wordArray(1) = SearchString
    set wordArray(2) = ""
    set wordArray(3) = ""
    set wordArray(4) = ""
    set wordquantity = 1
    }
    else {
	set wordArray(1) = $PIECE(SearchString," ",1)
	set wordArray(2) = $PIECE(SearchString," ",2)
	set wordArray(3) = $PIECE(SearchString," ",3)
	set wordArray(4) = $PIECE(SearchString," ",4)
	set wordquantity = 4
	}
	set spaceArray = ##class(%ArrayOfDataTypes).%New()
	set wordCountArray = ##class(%ArrayOfDataTypes).%New()
	ZNSPACE "DOCBOOK"
	set tempArray = ##class(%ArrayOfDataTypes).%New()
	set counter = 1
	SET myquery = "SELECT count(*) As cnt,content,component->blockid AS link FROM DocBook.block WHERE component->blockid='BXJV_globals'"
  	SET tStatement = ##class(%SQL.Statement).%New()
  	SET qStatus = tStatement.%Prepare(myquery)
   	IF qStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(qStatus) QUIT}
  	SET rset = tStatement.%Execute()
  	WHILE rset.%Next() {
	  	ZNSPACE "DOCSEARCH"
	  	set tempArray(counter) = ##class(Search.Parser).Parse(rset.content)
    	set counter=counter+1
    	set rowcount = rset.cnt
  	}
  	w tempArray(1)
  	w rowcount,!
    for k=1:1:wordquantity
    { 
	 set word = wordArray(k)
	 if (word="") {quit}
	 set spaceArray(k)=0
  	 set wordCountArray(k)=0
	 set Wordlength=$length(word)
     for j=1:1:rowcount
      {	
      	set text=tempArray(j)
      	w "text: "_text,!
      	W "textlength: "_$length(text), !
    	for i=1:1:$length(text)-Wordlength
    	{
    		W "wordlength: "_Wordlength,!
	    	set substr=$EXTRACT(text,i,i+Wordlength-1)
	    	w "substring: "_substr,!
			set char = $EXTRACT(text,i)
			if (char=" ")
			{
				set spaceArray(k)=spaceArray(k)+1
				w "space count: "_spaceArray(k),!
			}
			if (substr=word)
			{ 
				set wordCountArray(k)=1+wordCountArray(k)
			}
    	}
      }
    }
    set rank0=0
    s rank1=0
    s rank2=0
    s rank3=0
    set rank0 =wordCountArray(1)/spaceArray(1)
    if (wordArray(2)'="")
    	{set rank1 =wordCountArray(2)/spaceArray(2)}
    if (wordArray(3)'="")
    	{set rank2=wordCountArray(3)/spaceArray(3)}
    if (wordArray(4)'="")
    	{set rank3 =wordCountArray(4)/spaceArray(4)}
    set rank=rank0+rank1+rank2+rank3
    w "rank0: "_rank0,!
    w "rank1: "_rank1,!
    w "rank2: "_rank2,!
    w "rank3: "_rank3,!
    w "final rank: "_rank,!
	s st=$$$OK
	q rank
}

}