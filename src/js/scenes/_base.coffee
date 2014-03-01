class BaseScene extends Marionette.Layout
  regions:
    main: '#main'

  keymapData: {}

  initialize: ->
    @active = false
    @keymap = Keymap.createFromData(@keymapData, @)
    $(window).on 'resize', => @_resize()

  onRender: ->

  onShow: ->
    @active = true
    @_resize()

  onClose: ->
    @active = false

  _resize: ->
    if @active
      $window = $(window)
      margin = @$el.offset().top
      @$el.height($window.height() - margin)
