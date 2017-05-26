var searchApp = angular.module('searchApp');
 
searchApp
	
	.factory('pagination', function($sce) {

		var currentPage = 0;
		var counter = 0;
		var startPage = 0;
				
		var results = [];

		return {		
			
			//
			getPageProducts: function(num) {
				num = angular.isUndefined(num) ? 0 : num;
				currentPage = num;
			}, /* END of getPageProducts */
			
			//
			getTotalPagesNum: function(TotalObjNum, itemsPerPage) {
				return Math.ceil(TotalObjNum / itemsPerPage);
			}, /* END of getTotalPagesNum */
			
			//			
			getPaginationList: function(page, pagesNum, check) {
				var paginationList = [];
				
				if(check || (page == 0) )
				{
					startPage = 0;
				}
				
				var endPage = startPage + 10;				
				
				if(!isNaN(page))
					counter = page;

				if(endPage > pagesNum)
					endPage = pagesNum;

				if (page == 'prev')
				{
					page = counter - 1;
					counter = page;
					if (page % 10 == 9)
						endPage = page + 1;
					
					startPage = endPage - 10;
					
					if(startPage < 0)
						startPage = 0;
				}
				
				if (page == 'next')
				{
					page = counter + 1;
					counter = page;
					if (page % 10 == 0)
						startPage = page;
					
					endPage = startPage + 10;
									
					if(endPage > pagesNum)
						endPage = pagesNum;
				}				
									
				for (var i = startPage; i < endPage; i++) {
					var name = i + 1;
					paginationList.push({
						name: $sce.trustAsHtml(String(name)),
						link: i
					});
				};
				
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