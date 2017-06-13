var searchApp = angular.module('searchApp');
 
	searchApp.filter('itemsLength', function(){
	     
	     return function(input, first, last, hideToggle){
	       	var template =/<span class="Illumination">[\S]+/ig;
	       	var pattern =/[\S]+/ig;
	       	var len = template.length;
	     	if (!input || !input.length) return;
	       	
	       	if (hideToggle){
	       		if(last+200>input.length) return input;
	       		 var temp;
	       		 while (((temp = template.exec(input)) != null) || ((temp = pattern.exec(input)) != null)) {
	       		 	if((temp.index < last) && (last < template.lastIndex)){
	       		 		last=template.lastIndex;
	       		 		break;
	       		 	}
	       		 	if((temp.index < last) && (last < pattern.lastIndex)){
	       		 		last=pattern.lastIndex;
	       		 		break;
	       		 	}
	       		 	if((template.lastIndex > last) && (pattern.lastIndex > last)) break;
	       		 }
	       		return input.slice(first, last);
	       	}
	       	else
	       		return input;
	    }
	})