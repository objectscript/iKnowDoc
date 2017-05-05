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