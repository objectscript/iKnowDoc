var searchApp = angular.module('searchApp');
 
searchApp.filter('showAllResults', function($sce){
     
     var tempResults = [];
     var results = [];
     
     return function(input, first, last, hideToggle, phrase){
       	
       	if (!input || !input.length) return;
       	
       	/*while(input.length)
       	{
       		tempResults.text += input.text.replace(new RegExp(phrase, "gi" ), '<span class="Illumination"><b> $&'+'</b></span>' );
       		tempResults.textKey += input.textKey;
       	}*/
       	
       	if (hideToggle)
     		results = input.slice(first, last);
     	if(!hideToggle)
     		results = input;
        
        return results;
    }
})