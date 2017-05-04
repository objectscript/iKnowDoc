var searchApp = angular.module('searchApp');
 
searchApp
	
	.factory('pagination', function( $sce ) {

		var currentPage = 0;
		var results = [];

		return {		
			
			//
			getPageProducts: function(num) {
				var num = angular.isUndefined(num) ? 0 : num;
				currentPage = num;
			}, /* END of getPageProducts */
			
			//
			getTotalPagesNum: function(TotalObjNum, itemsPerPage) {
				return Math.ceil( TotalObjNum / itemsPerPage );
			}, /* END of getTotalPagesNum */
			
			//
			getPaginationList: function(TotalPagesNum, itemsPerPage) {
				var pagesNum = this.getTotalPagesNum(TotalPagesNum, itemsPerPage);
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
				if ( prevPageNum < 0 ) 
					prevPageNum = 0;
				return this.getPageProducts( prevPageNum );
			}, /* END of getPrevPageProducts */
			
			//
			getNextPageProducts: function(TotalPagesNum, itemsPerPage) {
				var nextPageNum = currentPage + 1;
				var pagesNum = this.getTotalPagesNum(TotalPagesNum, itemsPerPage);
				if ( nextPageNum >= pagesNum )
					nextPageNum = pagesNum - 1;
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
			without:'',
			startRecord:'1',
			recordCount: '20'	
		};
		
		var index = -1;
		
		$scope.toggle = true;
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
		
		$scope.handleClick = function (item){
			$scope.currrentSearchItem = item;
			$scope.search.text = $scope.currrentSearchItem.value;
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
				
				$http.post('http://' + location.host + '/csp/docsearch/rest/Search', $scope.search)
					.then(function(response) {
							$scope.results = response.data.sources;
							$scope.totalCount = $scope.results[$scope.search.recordCount].totalCount;
							$scope.paginationList = pagination.getPaginationList($scope.totalCount, $scope.search.recordCount);
							console.log($scope.totalCount);
							
						});
				
				$scope.toggle = false;
				
			} else 
				$scope.toggle = true;
		}

		$scope.showPage = function(page) {

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
		}
				
		$scope.currentPageNum = function() {
			return pagination.getCurrentPageNum();
		}
	})/* END of controller - searchController */
