var searchApp = angular.module('searchApp');
 
searchApp.filter('showAllResults', function(){
     var results = [];
     return function(input, first, last, bool){
       	if (!input || !input.length) { return; }
       	if (bool == true)
     		results = input.slice(first, last);
     	if(bool == false)
     		results = input;
        return results;
    }
})