var searchApp = angular.module('searchApp');
 
	searchApp.filter('itemsLength', function(){
	     
	     return function(input, first, last, hideToggle, word){
	       	
	       	var template = '<span class = "Illumination">' + word + '</span>';
	       	
	       	var len = 
	       	
	     	if (!input || !input.length) return;
	       	
	       	if (hideToggle)
	       		return input.splice(first, last);
	       	else
	       		return input;
	    }
	})