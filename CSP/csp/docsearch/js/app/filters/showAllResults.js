var searchApp = angular.module('searchApp');
 
searchApp.filter('showAllResults', function($sce){

     var results = [];
     
     return function(input, first, last, hideToggle){
       	
       	if (!input || !input.length) return;
       	
       	if (hideToggle)
     		results = input.slice(first, last);
     	if(!hideToggle)
     		results = input;
        
        return results;
    }
})