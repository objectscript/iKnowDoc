var searchApp = angular.module('searchApp');
 
	searchApp.filter('itemsLength', function(){
	     
	     return function(input, first, last, hideToggle){
	       	var template =/<span class="Illumination">[\S]+/ig;
	       	/*var template =new RegExp('<span class="Illumination">'+word+'<\/span>', "ig");*/
	       	var len = template.length;
	       	
	     	if (!input || !input.length) return;
	       	
	       	if (hideToggle){
	       		 var res;
	       		 while ((res = template.exec(input)) != null) {
	       		 	if(res.index<last&&last<template.lastIndex){
	       		 	last=template.lastIndex;
	       		 	break;
	       		 	}
	       		 }
	       		return input.slice(first, last);
	       	}
	       	else
	       		return input;
	    }
	})