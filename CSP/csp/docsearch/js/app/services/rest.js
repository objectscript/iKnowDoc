var searchApp = angular.module('searchApp')

searchApp

	.factory('rest', ['$http', 'defaults', function($http, defaults){
	  
	var service = {
	  baseUrl: '/csp/docsearch/rest/',
	  
	  ajax: function(method, uri, data){
	   var url = this.baseUrl + uri;
	   method = method.toUpperCase();
   
	   console.log(method + ' request: "' + url + '":', data);
   
	   var httpConfig = {
		    method: method,
		    url: url,
		    data: data,
		    timeout: 600000
	   };
   
   return $http(httpConfig).then(function(response){    
    console.log(method + ' response: "' + url + '":', response.data);
    
    response.data.alert = {
     code: response.data.errorCode,
     type: response.data.errorCode == "200" ? "success" : "error",
     message: response.data.errorMessage
    };
    return response.data;
   }, function(response){
    response.data.alert = {
     code: response.data.errorCode,
     type: "error",
     message: "Ошибка на сервере. Обратитесь к администратору."
    };
    return response.data;
   });
  },
  get: function(uri){
   return this.ajax('get', uri);
  },
  post: function(uri, options){
   return this.ajax('post', uri, options);
  },

  searchRequest: function(uri, gridOptions, pagingOptions, searchInputs){
   pagingOptions = pagingOptions || {pageSize: gridOptions ? gridOptions.paginationPageSize : defaults.gridOptions.paginationPageSize, pageNumber: 1};
   
   var recordCount = pagingOptions.pageSize;
   var startRecord = (pagingOptions.pageNumber - 1) * recordCount + 1;
   
   var requestOptions = {
    "startRecord": startRecord,
    "recordCount": recordCount,
    "filters": []
   };

   if(gridOptions && gridOptions.sortColumns.length){
    requestOptions["orderBy"] = gridOptions.sortColumns[0].name || "ID";
    requestOptions["orderDir"] = gridOptions.sortColumns[0].sort.direction || "DESC";
   } else {
    requestOptions["orderBy"] = "ID";
    requestOptions["orderDir"] = "DESC";    
   }
   
   if(requestOptions.orderDir)
    requestOptions.orderDir = requestOptions.orderDir.toUpperCase();   
   
   if(searchInputs){
    angular.forEach(searchInputs, function(value, field){
     if(['withHistory', 'onlyEtalon'].indexOf(field) != -1){
      requestOptions[field] = value;
     }
     else if(value){
      requestOptions.filters.push({
       "field": field,
       "value": value,
       "comparsion": 'equals',
       "type": 'string'
      });
     }
    });
   }
   
   console.log('Search ' + uri + ' request: ', requestOptions);
   return this.ajax('post', uri, requestOptions);
  }
 };
 
 return service;
}]);