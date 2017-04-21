Class Search.Sort {

ClassMethod Partition(array As %ArrayOfObjects, start As %Integer, end As %Integer) As %Integer
{
	set pivot = array(1)
    set i = start
    set j = end    
    while i < j 
     {
        while array(i) > pivot
         { 
            set i = i + 1 
         }
        while array(j) < pivot
          {
	          set j = j - 1
	      }
        if (i >= j) 
        {
	        set k = i
	        set i = j
	        set j = k
        }
     }
    return i + 1
}

ClassMethod Sorting(array As %ArrayOfObjects, start As %Integer, end As %Integer) As %ArrayOfObjects
{

	if start < end
    {
	    set p = ##class(Search.Sort).Partition(array, start, end)
        do ##class(Search.Sort).Sorting(array, start, p-1)
        do ##class(Search.Sort).Sorting(array, p, end)
    }
}

}