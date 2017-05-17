var searchApp = angular.module('searchApp');
 
searchApp
	
	.controller('searchController', function ($scope, $http, pagination, $location) {
				
		$scope.search = {
			words: '',
			phrase: '',
			anyWords:'',
			without:'',
			startRecord:'1',
			recordCount: '10'	
		};
		
		var index = - 1;
		var prevNextCheck = 0;
		var baseUrl = '/csp/docsearch/rest/';
		var check = '';

		$scope.mylocation = location.host;
		$scope.inputToggle = false;
		$scope.resultToggle = true;
		$scope.preloadToggle = false;
		$scope.prevToggle = false;
		$scope.nextToggle = false;
		$scope.checkToggle = false;
		$scope.phraseToggle = false;
		$scope.anyWordsToggle = false;
		$scope.withoutToggle = false;
		$scope.title = "DocSearch";

		$scope.phraseDel = function () {
			$scope.search.phrase = '';
			$scope.phraseToggle = false;
			if ($scope.search.words != '')
				$scope.showPage(0);			
		}
		
		$scope.anyWordsDel = function () {
			$scope.search.anyWords = '';
			$scope.anyWordsToggle = false;
			if ($scope.search.words != '')
				$scope.showPage(0); 
		}
		
		$scope.withoutDel = function () {
			$scope.search.without = '';
			$scope.withoutToggle = false;
			if ($scope.search.words != '')
				$scope.showPage(0); 
		}
		
		$scope.clearAll=function(){
			$scope.search.words = "";
			$scope.search.phrase = "";
			$scope.search.anyWords = "";
			$scope.search.without = "";
		}
		
		$scope.change = function (){
								
			$http.get(baseUrl + 'GetSimilar/' + $scope.search.words)
				.then(function(response) {
					$scope.searchItems = response.data.entities;
			});	
	
			if ($scope.search.words == '')
				$scope.inputToggle = false;
			else 
				$scope.inputToggle = true;
		}
		
		$scope.handleClick = function (item) {
		
			$scope.currrentSearchItem = item;
			$scope.search.words = $scope.currrentSearchItem.value;
			$scope.makeSearch();
			
			$scope.inputToggle = false;
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
			if 	((event.keyCode === 40) || (event.keyCode === 38))
			{
				$scope.search.words = $scope.searchItems[index].value;
				$scope.currrentSearchItem = $scope.searchItems[index];
			}
			
			if (event.keyCode === 13)
					$scope.inputToggle = false;
			
		}		

		$scope.makeSearch = function (){
			
			$scope.inputToggle = false;
			$scope.title = $scope.search.words;
			
			if ($scope.search.words != '')
			{
				$scope.showPage(0); 
				$location.path("/DocResults");				

			} else			
				$location.path("/DocSearch");
	
		}

		$scope.showPage = function (page) {		
			
			$scope.currentPage = page;			
			
			if(check != $scope.search.words)
			{
				$scope.checkToggle = true;
				check = $scope.search.words;
				$scope.search.phrase = '';
				$scope.search.anyWords = '';
				$scope.search.without = '';
				$scope.phraseToggle = false;
				$scope.anyWordsToggle = false;
				$scope.withoutToggle = false;			
			}
			else 
				$scope.checkToggle = false;
			
			if ($scope.search.phrase != '')
				$scope.phraseToggle = true;
			
			if ($scope.search.anyWords != '')
				$scope.anyWordsToggle = true;

			if ($scope.search.without != '')
				$scope.withoutToggle = true;
					
			$scope.search.startRecord = (pagination.getCurrentPageNum()) * $scope.search.recordCount + 1;

			$scope.preloadToggle = true;		
			$http.post(baseUrl + 'Search', $scope.search)
				.then(function(response) {
					$scope.results = response.data.sources;
					$scope.totalCount = $scope.results[$scope.results.length - 1].totalCount;
					$scope.pagesNum = pagination.getTotalPagesNum($scope.totalCount, $scope.search.recordCount);
					$scope.paginationList = pagination.getPaginationList($scope.currentPage, $scope.pagesNum, $scope.checkToggle);
					
					if (prevNextCheck != $scope.pagesNum - 1)
						$scope.nextToggle = true;
					else
						$scope.nextToggle = false;
		
					if ($scope.pagesNum == undefined)
						$scope.nextToggle = false;
					
					$scope.preloadToggle = false;
			});
			
			if(!isNaN(page))
					prevNextCheck = page;
			
			if (page == 'prev') {
					$scope.results = pagination.getPrevPageProducts();
					prevNextCheck -= 1;
					if (prevNextCheck < 0)
						prevNextCheck = 0;
			} else if (page == 'next') {
					$scope.results = pagination.getNextPageProducts($scope.totalCount, $scope.search.recordCount);
					prevNextCheck += 1;
					if (prevNextCheck > $scope.pagesNum - 1)
						prevNextCheck = $scope.pagesNum;
			} else {
				$scope.results = pagination.getPageProducts(page);
			}
	
			if (prevNextCheck != 0)
				$scope.prevToggle = true;
			else
				$scope.prevToggle = false;
		}
				
		$scope.currentPageNum = function() {
		
				return pagination.getCurrentPageNum();
		}

	})/* END of controller - searchController */