var searchApp = angular.module('searchApp');
 
	searchApp.filter('itemsLength', function(){
	     
	     return function(input, first, last, hideToggle){
	       	var template =/[\S]+/ig;
	       	var len = template.length;
	       	
	     	if (!input || !input.length) return;
	       	
	       	if (hideToggle){
	       		 var temp;
	       		 while ((temp = template.exec(input)) != null) {
	       		 	if(temp.index<last&&last<template.lastIndex){
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