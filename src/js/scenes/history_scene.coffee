class HistoryScene extends Marionette.Layout
  template: '#history-scene-template'
  id: 'history'
  className: 'history scene'

  regions:
    sub: '#sub'
    main: '#main'

  keymapData: {}

  initialize: ->
    @active = false
    @current_note = null
    @keymap = Keymap.createFromData(@keymapData, @)
    $(window).on 'resize', => @_resize()

  onRender: ->
    timeline_view = new TimelineView(collection: @model.note_index)
    note_view      = new NoteView(model: @current_note)
    @main.show(timeline_view)
    @sub.show(note_view)
    # Load history data
    @model.getHistoryEvents().then(
      (history_events)=> console.log "NOTE INDEX UPDATED"
      (error)=> console.log "NOTE INDEX NOT LOADED")
    console.log 'HistoryScene.onRender'

  onShow: ->
    @active = true
    @_resize()
    console.log 'History.onShow'

  onClose: ->
    @active = false

  _resize: ->
    if @active
      @_adjustRegionHeight()
      $window = $(window)
      @main.$el.width($window.width() - @sub.$el.outerWidth())

  _adjustRegionHeight: ->
    $window = $(window)
    margin = @$el.offset().top
    @$el.height($window.height() - margin)

class TimelineView extends Marionette.ItemView
  template: '#timeline-view-template'
  id: 'timeline'
  className: 'timeline'
