var searchApp = angular.module('searchApp');
 
searchApp.filter('showAllResults', function( $sce ){
     
     var tempResults = [];
     var results = [];
     
     return function(input, first, last, hideToggle, phrase){
       	
       	if (!input || !input.length) return;
       	
       	for(var i = 0; i < input.length; i++){       		
       		var content = input[i].text.replace(new RegExp(phrase, "gi" ), '<span class="Illumination"><b> $& </b></span>');
       		tempResults.push({
       			text: $sce.trustAsHtml(String(content)),
       			textKey: input[i].textKey
       		});
       	};
       	
       	if (hideToggle)
       	{
     		results = tempResults.slice(first, last);
     		//tempResults.length = 0;
     	}
     	if(!hideToggle)
     	{
     		results = tempResults;
     		//tempResults.length = 0;
     	}
     	
        return results;
    }
})