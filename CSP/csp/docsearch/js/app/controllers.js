var searchApp = angular.module('searchApp');
 
searchApp
	
	.controller('searchController', function ($scope, $http, pagination, $location) {
				
		$scope.search = {
			words: '',
			phrase: '',
			anyWords:'',
			without:'',
			startRecord:'1',
			recordCount: '20'	
		};

		$scope.mylocation = location.host;
		
		var index = - 1;
		
		$scope.imputToggle = false;
		
		$scope.change = function (){
								
				$http.get('http://' + location.host + '/csp/docsearch/rest/GetSimilar/' + $scope.search.words)
					.then(function(response) {
							$scope.searchItems = response.data.entities;
						});	
	
				if ($scope.search.words == '')
					$scope.imputToggle = false;
				else 
					$scope.imputToggle = true;
		}
		
		$scope.handleClick = function (item) {
		
			$scope.currrentSearchItem = item;
			$scope.search.words = $scope.currrentSearchItem.value;
			$scope.makeSearch();
			
			$scope.imputToggle = false;
		}
		
		$scope.handleArrows = function (event) {
			
			if(event.keyCode  === 40) // up
				index += 1;
			if(event.keyCode  === 38) // down
				index -= 1;
				
			if (index < 0)
				index = 9;
			if (index > 9)
				index = 0;	
			if 	((event.keyCode  === 40) || (event.keyCode  === 38))
			{
				$scope.search.words = $scope.searchItems[index].value;
				$scope.currrentSearchItem = $scope.searchItems[index];
			}
			
			if (event.keyCode  === 13)
					$scope.imputToggle = false;
			
		}
		
		$scope.advancedSearch = function(){
			
			if ($scope.search.words != '')
			{
				$http.post('http://' + location.host + '/csp/docsearch/rest/Search', $scope.search)
					.then(function(response) {
								$scope.results = response.data.sources;
							});
				$location.path("/DocResults");

			} else 
				$location.path("/DocSearch");
		}
		

		$scope.makeSearch = function (){

			$scope.search.startRecord = 1;
			if ($scope.search.words != '')
			{
				
				$http.post('http://' + location.host + '/csp/docsearch/rest/Search', $scope.search)
					.then(function(response) {
							$scope.results = response.data.sources;
							$scope.totalCount = $scope.results[$scope.search.recordCount].totalCount;
							$scope.paginationList = pagination.getPaginationList($scope.totalCount, $scope.search.recordCount);
							console.log($scope.search.startRecord);
						});
						
						
				$location.path("/DocResults");
				
			} else 
			
				$location.path("/DocSearch");
		}

		$scope.showPage = function (page) {

					if ( page == 'prev' ) {
						$scope.results = pagination.getPrevPageProducts();
					} else if ( page == 'next' ) {
						$scope.results = pagination.getNextPageProducts($scope.totalCount, $scope.search.recordCount);
					} else {
						$scope.results = pagination.getPageProducts( page );
					}
					$http.post('http://' + location.host + '/csp/docsearch/rest/Search', $scope.search)
					.then(function(response) {
							$scope.results = response.data.sources;
						});
					
					$scope.search.startRecord = (pagination.getCurrentPageNum()) * $scope.search.recordCount + 1;
					//console.log($scope.search.startRecord);
		}
				
		$scope.currentPageNum = function() {
			return pagination.getCurrentPageNum();
		}

	})/* END of controller - searchController */
	

