var searchApp = angular.module('searchApp');
 
searchApp
	
	.controller('searchController', function ($scope, $http, pagination, $location, $sce) {
				
		$scope.search = {
			words: '',
			phrase: '',
			anyWords:'',
			without:'',
			fuzzy: false,
			rank: false,
			startRecord:'1',
			recordCount: '10'	
		};
		
		var index = - 1;
		var prevNextCheck = 0;
		var baseUrl = '/csp/docsearch/rest/';
		var check = '';
		var input = location.hash;
		
		$scope.sce = $sce;
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
		$scope.errorToggle = false;
		$scope.frankenshtein = false;
		$scope.link="http://"+ location.host +"/csp/docbook/DocBook.UI.Page.cls?KEY=";
		
		$scope.SwitchClick = function(){
			if($scope.frankenshtein == true)
				$scope.frankenshtein = false;
			else
				$scope.frankenshtein = true;
			}
		$scope.SwitchClickV2 = function(){
			$scope.SwitchClick();
			$scope.makeSearch();
			}
		
		angular.element(document).ready(function(){
			if ( (input != "#!/DocSearch") && (input != "#!/DocResults") && (input != "#!/SearchAdvance") && (input != "")  )
			{	
				var linkStr = input.split('#');
				$scope.search.words = decodeURIComponent(linkStr[2]);
				$scope.makeSearch();
			}
		});	
		
		$scope.phraseClear = function () {
			$scope.search.phrase = "";
			$scope.makeSearch();
		}
		
		$scope.anyWordsClear = function () {
			$scope.search.anyWords = "";
			$scope.makeSearch();
		}
		
		$scope.withoutClear = function () {
			$scope.search.without = "";
			$scope.makeSearch();
		}
		
		$scope.clearAll = function () {
			$scope.search.words = "";
			$scope.search.phrase = "";
			$scope.search.anyWords = "";
			$scope.search.without = "";
		}
		
		$scope.change = function () {
			if ($scope.search.words != "")
			{			
				$http.get(baseUrl + 'GetSimilar/' + $scope.search.words)
					.then(function(response) {
						$scope.searchItems = response.data.entities;
						
						if(angular.isDefined($scope.searchItems))
							if($scope.searchItems.length != 0 )
								if (($scope.searchItems[0].value == " ") || ($scope.search.words == ""))
									$scope.inputToggle = false;
								else 
									$scope.inputToggle = true;
				});
				$scope.inputToggle = false;
			}
		}
		
		$scope.getVersion = function () {
			$http.get(baseUrl + 'GetVersion')
					.then(function(response) {
						$scope.version = response.data.version;
				});
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
		$scope.handle = function (event) {
			if (event.keyCode === 13)
					$scope.makeSearch();	
		}		

		$scope.makeSearch = function () {
			$scope.inputToggle = false;
			$scope.errorToggle = false;
			
			if($scope.frankenshtein == true){$scope.link="https://docs.intersystems.com/latest/csp/docbook/DocBook.UI.Page.cls?KEY=";}
			else {$scope.link="http://"+ location.host +"/csp/docbook/DocBook.UI.Page.cls?KEY=";}
			
			$scope.search.phrase == '' ? $scope.phraseShow = false : $scope.phraseShow = true;
			$scope.search.anyWords == '' ? $scope.anyWordsShow = false : $scope.anyWordsShow = true;
			$scope.search.without == '' ? $scope.withoutShow = false : $scope.withoutShow = true;

			$scope.title = $scope.search.words;

			if ($scope.search.words != '' || $scope.search.phrase != '' || $scope.search.anyWords != '')
			{
				$scope.showPage(0); 
				$location.path("/DocResults");				

			} 
			else
				if ( $scope.search.without != '')
					$scope.errorToggle = true;
				else
					if ( $scope.search.without == '')	
						$location.path("/DocSearch");	
		}

		$scope.showPage = function (page) {		
			
			$scope.resultToggle = true;	
			
			$scope.currentPage = page;			
			
			if(check != $scope.search.words)
			{
				$scope.checkToggle = true;
				check = $scope.search.words;		
			}
			else 
				$scope.checkToggle = false;

			$scope.preloadToggle = true;

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
			
			$scope.search.startRecord = (pagination.getCurrentPageNum()) * $scope.search.recordCount + 1;
	
			$http.post(baseUrl + 'Search', $scope.search)
				.then(function(response) {
					$scope.results = response.data.sources;
					
					$scope.totalCount = response.data.totalCount[0].total;

					if ($scope.totalCount != 0)
					{	$scope.resultToggle = true;				
						$scope.pagesNum = pagination.getTotalPagesNum($scope.totalCount, $scope.search.recordCount);
						$scope.paginationList = pagination.getPaginationList($scope.currentPage, $scope.pagesNum, $scope.checkToggle);
						
						if (prevNextCheck != $scope.pagesNum - 1)
							$scope.nextToggle = true;
						else
							$scope.nextToggle = false;
						
						if ($scope.pagesNum == undefined)
							$scope.nextToggle = false;
					}
					else
						$scope.resultToggle = false;
					
					$scope.preloadToggle = false;					
			});
	
			if (prevNextCheck != 0)
				$scope.prevToggle = true;
			else
				$scope.prevToggle = false;
		}
				
		$scope.currentPageNum = function() {
		
				return pagination.getCurrentPageNum();
		}

	})/* END of controller - searchController */