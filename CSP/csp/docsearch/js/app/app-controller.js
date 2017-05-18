var searchApp = angular.module('searchApp');
 
searchApp
	
	.controller('searchController', function ($scope, $http, pagination, $location, $sce) {
				
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
		$scope.title = "DocSearch";
		$scope.phraseShow = false;
		$scope.anyWordsShow = false;
		$scope.withoutShow = false;
		
		$scope.phraseClear=function(){
			$scope.search.phrase="";
			$scope.makeSearch();
		}
		
		$scope.anyWordsClear=function(){
			$scope.search.anyWords="";
			$scope.makeSearch();
		}
		
		$scope.withoutClear=function(){
			$scope.search.without="";
			$scope.makeSearch();
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
			$scope.search.phrase=='' ? $scope.phraseShow=false : $scope.phraseShow=true;
			$scope.search.anyWords=='' ? $scope.anyWordsShow=false : $scope.anyWordsShow=true;
			$scope.search.without=='' ? $scope.withoutShow=false : $scope.withoutShow=true;
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
			}
			else 
				$scope.checkToggle = false;
					
			$scope.search.startRecord = (pagination.getCurrentPageNum()) * $scope.search.recordCount + 1;

			$scope.preloadToggle = true;		
			$http.post(baseUrl + 'Search', $scope.search)
				.then(function(response) {
					$scope.results = response.data.sources;
					$scope.totalCount = response.data.totalCount[0].total;
					$scope.pagesNum = pagination.getTotalPagesNum($scope.totalCount, $scope.search.recordCount);
					$scope.paginationList = pagination.getPaginationList($scope.currentPage, $scope.pagesNum, $scope.checkToggle);
					//$scope.searchWords();
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
		$scope.searchWords=function(){
		$scope.sce = $sce;
		$scope.test = "This chapter describes the iFind search facility. iFind is an SQL facility for performing text search operations. To use iFind you must define an iFind index for each column containing text that you wish to search. You can then search the text records using a standard SQL query with a WHERE clause containing iFind index syntax.";
        $scope.ifind="ifind";
        $scope.test=$scope.test.replace( new RegExp( $scope.ifind, "gi" ), '<span class="Illumination"><b> $&'+'</b></span>' );
        $scope.myHTML =$scope.test;
        
		}

	})/* END of controller - searchController */