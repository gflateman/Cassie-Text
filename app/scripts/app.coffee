'use strict'

angular.module('cassieApp', ['ngRoute', 'ngResource'])
  .config ($routeProvider, $locationProvider) ->
    $locationProvider.html5Mode true
    $routeProvider
      .when '/',
        templateUrl: 'views/main.html'
        controller: 'MainCtrl'
        reloadOnSearch: false
      .otherwise
        redirectTo: '/'
