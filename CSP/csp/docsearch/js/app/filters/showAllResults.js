var searchApp = angular.module('searchApp');
 
searchApp.filter('showAllResults', function(){
     
     return function(input, first, last, hideToggle){
       	
       	if (!input || !input.length) return;
       	
       	if (hideToggle)
     		return input.slice(first, last);
     	else
     		return input;
    }
})