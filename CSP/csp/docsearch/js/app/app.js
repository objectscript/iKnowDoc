var searchApp = angular.module('searchApp', ["ngRoute"])
    .config(function($routeProvider){
        $routeProvider.when('/DocSearch',
        {
            templateUrl:'js/app/templates/DocSearch.html',
            //controller:'searchController'
        });
        $routeProvider.when('/DocResults',
        {
            templateUrl:'js/app/templates/DocResults.html',
            //controller:'searchController'
        });
        $routeProvider.when('/SearchAdvance',
        {
            templateUrl:'js/app/templates/SearchAdvance.html',
            //controller:'searchController'
        });
        $routeProvider.otherwise({
        	redirectTo: '/DocSearch'
        });
});