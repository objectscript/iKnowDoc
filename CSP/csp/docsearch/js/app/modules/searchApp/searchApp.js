var searchApp = angular.module('searchApp', []);
 
searchApp.controller('listController', ['$scope', '$http',
  function ($scope, $http) {
    $http.get('http://localhost:57773/api/iknow/v1/DOCBOOK/domain/1/entities/iknow/similar').then(function(response) {
      $scope.persons = response.data.entities;
    });
 
    $scope.orderProp = 'frequency';
	
}]);
 
searchApp.controller('searchController', ['$scope', '$http',
  function ($scope, $http) {
	$scope.update = angular.copy.search;
	$scope.MakeSearch = function (){
		$http.post('http://localhost:57773/api/iknow/v1/DOCBOOK/domain/1/entities/iknow/similar').then(function(response) {
    });
	}
 
    $scope.orderProp = 'frequency';
	
}]);