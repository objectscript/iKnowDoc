var searchApp = angular.module('searchApp');
 
searchApp
	
	.factory('pagination', function( $sce ) {

		var currentPage = 0;
		var itemsPerPage = 21;
		var results = [];

		return {
			
			//
			setResults: function( newResults ) {
				results = newResults
			}, /* END of setProducts */
			
			//
			getPageProducts: function(num) {
				var num = angular.isUndefined(num) ? 0 : num;
				var first = itemsPerPage * num;
				var last = first + itemsPerPage;
				currentPage = num;
				last = last > results.length ? (results.length - 1) : last;
				return results.slice(first, last);
			}, /* END of getPageProducts */
			
			//
			getTotalPagesNum: function() {
				return Math.ceil( results.length / itemsPerPage );
			}, /* END of getTotalPagesNum */
			
			//
			getPaginationList: function() {
				var pagesNum = this.getTotalPagesNum();
				var paginationList = [];
				paginationList.push({
					name: $sce.trustAsHtml('&laquo;'),
					link: 'prev'
				});
				for (var i = 0; i < pagesNum; i++) {
					var name = i + 1;
					paginationList.push({
						name: $sce.trustAsHtml( String(name) ),
						link: i
					});
				};
				paginationList.push({
					name: $sce.trustAsHtml('&raquo;'),
					link: 'next'
				});
				if (pagesNum > 1) {
					return paginationList;
				} else {
					return null;
				}
			}, /* END of getPaginationList */
			
			//
			getPrevPageProducts: function() {
				var prevPageNum = currentPage - 1;
				if ( prevPageNum < 0 ) prevPageNum = 0;
				return this.getPageProducts( prevPageNum );
			}, /* END of getPrevPageProducts */
			
			//
			getNextPageProducts: function() {
				var nextPageNum = currentPage + 1;
				var pagesNum = this.getTotalPagesNum();
				if ( nextPageNum >= pagesNum ) nextPageNum = pagesNum - 1;
				return this.getPageProducts( nextPageNum );
			}, /* END of getNextPageProducts */
			
			//
			getCurrentPageNum: function() {
				return currentPage;
			}, /* END of getCurrentPageNum */

		}
	}) /* END of factory-pagination */
	
	.controller('searchController', function ($scope, $http, pagination) {
				
		$scope.search = {
			words: '',
			phrase: '',
			anyWords:'',
			without:''
		};
		
		var index = -1;
		
		$scope.toggle = true;
		$scope.imputToggle = false;
		
		$scope.change = function (){
								
				$http.get('http://' + location.host + '/api/iknow/v1/docbook/domain/1/entities/' + $scope.search.words + '/similar')
					.then(function(response) {
							tempArray = response.data.entities;
							$scope.searchItems = tempArray.slice(0, 10);
						});		
				if ($scope.search.words == '')
					$scope.imputToggle = false;
				else
					$scope.imputToggle = true;
		}
		
		$scope.handleClick = function (item){
			$scope.currrentSearchItem = item;
			$scope.search.words = $scope.currrentSearchItem.value;
			$scope.toggle = false;
			$scope.imputToggle = true;
			if ($scope.toggle == false)
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
			
			$http.post('http://' + location.host + '/csp/docsearch/rest/Search', $scope.search)
				.then(function(response) {
							$scope.tempo = response.data.sources;
						});	
			
		}
		
		$scope.makeSearch = function (){

			if ($scope.search.words != '')
			{
				//$http.get('http://' + location.host + '/csp/docsearch/rest/SearchByText/' + $scope.search.words)
				$http.post('http://' + location.host + '/csp/docsearch/rest/Search', $scope.search)
					.then(function(response) {
							$scope.resObj = response.data.sources;
							pagination.setResults(response.data.sources);
							$scope.results = pagination.getPageProducts($scope.currentPage);
							$scope.paginationList = pagination.getPaginationList();
						});
				
				$scope.toggle = false;
				
			} else 
				$scope.toggle = true;		
		}

		$scope.showPage = function(page) {
					if ( page == 'prev' ) {
						$scope.results = pagination.getPrevPageProducts();
					} else if ( page == 'next' ) {
						$scope.results = pagination.getNextPageProducts();
					} else {
						$scope.results = pagination.getPageProducts( page );
					}
				}
				
		$scope.currentPageNum = function() {
			return pagination.getCurrentPageNum();
		}
	
	})/* END of controller - searchController */