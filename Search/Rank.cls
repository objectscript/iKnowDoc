Class Search.Rank {

ClassMethod Ranking(SearchString) As %Float
{
	set rank=0
	set wordArray = ##class(%ArrayOfDataTypes).%New()
	set wordArray(0) = $PIECE(SearchString," ",1)
	set wordArray(1) = $PIECE(SearchString," ",2)
	set wordArray(2) = $PIECE(SearchString," ",3)
	set wordArray(3) = $PIECE(SearchString," ",4)
	set spaceArray = ##class(%ArrayOfDataTypes).%New()
	set wordCountArray = ##class(%ArrayOfDataTypes).%New()
	ZNSPACE "DOCBOOK"
	set tempArray = ##class(%ArrayOfDataTypes).%New()
	set count = 0	
	SET myquery = "SELECT content,component->blockid AS link FROM DocBook.block WHERE component->blockid='BXJV_globals'"
  	SET tStatement = ##class(%SQL.Statement).%New()
  	SET qStatus = tStatement.%Prepare(myquery)
   	IF qStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(qStatus) QUIT}
  	SET rset = tStatement.%Execute()
  	WHILE rset.%Next() {
	  	ZNSPACE "DOCSEARCH"
	  	set tempArray(count) = ##class(Search.Parser).Parse(rset.content)
    	set count=count+1
  	}
    for k=0:1:Count(wordArray)-1
    { 
	 set word = wordArray(k)
	 set spaceArray(k)=0
  	 set wordCountArray(k)=0
	 set Wordlength=$length(word)
     for j=0:1:Count(tempArray)-1
      {	
      	set text=tempArray(j)
    	for i=0:1:$length(text)
    	{
	    	set substring=SubString(text,i,i+Wordlength-1)
			set char = $EXTRACT(text,i)
			if (char=" ")
			{
				set spaceArray(k)=spaceArray(k)+1
			}
			if (substring=word)
			{ 
				set wordCountArray(k)=wordCountArray(k)+1
			}
    	}
      }
    }
    set rank0 =wordCountArray(0)/spaceArray(0)
    set rank1 =wordCountArray(1)/spaceArray(1)
    set rank2=wordCountArray(2)/spaceArray(2)
    set rank3 =wordCountArray(3)/spaceArray(3)
    set rank=rank0+rank1+rank2+rank3
	s st=$$$OK
	q rank
}

}