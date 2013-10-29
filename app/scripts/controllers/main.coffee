'use strict'

angular.module('cassieApp')

  .factory "UrlShortener", ($resource) ->
    UrlShortener = $resource "https://api-ssl.bitly.com/v3/shorten",
      access_token: '260efaa7be55f0f2da0ce1873df1c59c9c3317b1'
    ,
      # longUrl: string # the url to be shortened
      shorten:
        method: 'GET'

  .factory "eventBroadcast", ($rootScope) ->
    EB = {}
    EB.message = ""
    EB.eventName = ""
    EB.broadcast = (evName, msg) ->
      @message = msg
      @eventName = evName
      @broadcastItem()

    EB.broadcastItem = ->
      $rootScope.$broadcast @eventName
    EB

  .controller 'MainCtrl', ($scope, $timeout, $window, $routeParams, $location, UrlShortener, eventBroadcast) ->

    # Init Variables
    $scope.MOVEMENT_SENSITIVITY_MAX = 15
    # URL Params
    initData = ->
      urlData = $location.search()
      $scope.data =
        numberOfLayers: urlData.layers || 6
        movementSensitivity: urlData.sens ||  3
        mainText: if urlData.text then decodeURIComponent urlData.text else null
        userOptionsListIsExpanded: if urlData.options_collapsed then false else true
        neonMode: if urlData.neon then true else false
        titleFontSize: urlData.zoom || 100

      $scope.titleStyle = {"font-size": "#{$scope.data.titleFontSize}px"}

    $scope.resetDefaults = ->
      $location.search({})
      getDataFromUrl()

    $scope.clickShorten = ->
      $scope.toggleUserOptionsList(false)
      $scope.shortenUrl $location.absUrl()

    $scope.shortenUrl = (url) ->
      UrlShortener.shorten
        longUrl: url
      , (response) ->
        if response.status_code is 200
          $scope.shortenedUrl = response.data.url
        else
          alert "Error #{response.status_code}: #{response.status_txt}"
          console.log "Error #{response.status_code}: #{response.status_txt}"
      , (error) ->
        alert 'Something went wrong! Please try again.'
        console.log error

    $scope.changeTitleOffset = (height) ->
      offset = ($window.innerHeight - height) / 2
      $scope.textContainerStyle = {"top": "#{offset}px"}

    $scope.broadcastMousePosition = ($event) ->
      eventBroadcast.broadcast 'changeMousePosition',
        xPos: $event.clientX || $event.x || $event.pageX
        yPos: $event.clientY || $event.y || $event.pageY

    $scope.getSensitivityDenominator = ->
      $scope.data.numberOfLayers * ($scope.MOVEMENT_SENSITIVITY_MAX - $scope.data.movementSensitivity)

    # URL Functions
    $scope.updateTextParam = ->
      text = if $scope.data.mainText then encodeURIComponent($scope.data.mainText) else null
      $location.search 'text', text

    $scope.toggleNeonMode = ->
      $scope.data.neonMode = !$scope.data.neonMode
      $location.search 'neon', ($scope.data.neonMode || null)

    $scope.toggleUserOptionsList = (valueBool) ->
      $scope.data.userOptionsListIsExpanded = valueBool
      $location.search 'options_collapsed', (if valueBool then null else true)

    $scope.$watch 'data.movementSensitivity', (val) ->
      $location.search 'sens', val

    $scope.$watch 'data.numberOfLayers', (val) ->
      $location.search 'layers', val

    $scope.$watch 'data.titleFontSize', (val) ->
      $location.search 'zoom', val

    # Init
    initData()

  .directive "onKeyup", ->
    (scope, element, attrs) ->
      element.bind "keyup", (event) ->
        scope.$apply ->
          scope.$eval attrs.onKeyup

  .directive "gfTitleStyle", ($window, $timeout, eventBroadcast) ->
    transclude: true
    template: '<span ng-transclude></span>'
    scope:
      denominator:"&"
      index:"@"
    link: (scope, element, attrs) ->
      returnOffset = (multiplier, index) ->
        Math.floor(multiplier * (parseInt(index) + 1))

      randomHex = ->
        '#' + Math.floor(Math.random()*16777215).toString(16)

      changeColor = ->
        element.css
          'color': randomHex()
        $timeout(changeColor, 200)
      changeColor()

      element.css
        "z-index": "#{1000-scope.index}"
        "margin-left": "#{returnOffset(10, scope.index)}px"
        "margin-top": "#{returnOffset(10, scope.index)}px"

      scope.$on "changeMousePosition", ->
        msg = eventBroadcast.message
        multiplierX = (($window.innerWidth / 2) - msg.xPos) / scope.denominator()
        multiplierY = (($window.innerHeight / 2) - msg.yPos) / scope.denominator()
        element.css
          "margin-left": "#{returnOffset(multiplierX, scope.index)}px"
          "margin-top": "#{returnOffset(multiplierY, scope.index)}px"


  .directive "changeHeight", ->
    transclude: true
    template: '<span ng-transclude></span>'
    scope:
      changeHeight:"&"
    link: (scope, element, attrs) ->
      getHeight = -> element[0].getBoundingClientRect().height
      scope.$watch getHeight, (height) ->
        scope.changeHeight(height: height)

  .directive "selectOnClick", ->
    (scope, element, attrs) ->
      element.bind 'click', -> @select()

  .filter "range", ->
    (input, range) ->
      initial = parseInt(range[0])
      final = parseInt(range[1])
      i = initial
      while i < final
        input.push i
        i++
      input
