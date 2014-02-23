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
    timeline_view = new TimelineView()
    note_view     = new NoteView()
    @main.show(timeline_view)
    @sub.show(note_view)
    # Load history data
    Q.all([
      @model.getHistoryEvents()
      @model.loadNoteIndex()
    ]).then(
      (results)=>
        [history_events, note_index] = results
        console.log "------------------------ #{note_index.length} #{history_events.length}"
        timeline_items = @_buildTimelineItems(history_events, note_index)
        console.log timeline_items.length
        timeline_items.forEach (item)=> timeline_view.addTimelineItem(item)
      (error)=>
        console.log err
        console.log "History Events NOT LOADED")
    console.log 'HistoryScene.onRender'

  _buildTimelineItems: (history_events, note_index)->
    history_events.map (event)=>
      note_index_item = note_index.get(event.get('note_id'))
      TimelineItem.create(event: event, note_index_item: note_index_item)

  onShow: ->
    @active = true
    @_resize()
    console.log 'History.onShow'

  onClose: ->
    @active = false
    @note_index = null

  _resize: ->
    if @active
      @_adjustRegionHeight()
      # $window = $(window)
      # @main.$el.width($window.width() - @sub.$el.outerWidth())

  _adjustRegionHeight: ->
    $window = $(window)
    margin = @$el.offset().top
    @$el.height($window.height() - margin)

class TimelineItem extends Backbone.Model


TimelineItem.create = (params)->
  note_index_item = params.note_index_item
  console.log note_index_item
  event = params.event
  id = event.get('note_id')
  title = if note_index_item? then note_index_item.get('title') else id
  new TimelineItem
    id: id
    title: title
    datetime: event.get('datetime')
    event: event.toJSON()

class TimelineItemView extends Marionette.ItemView
  template: '#timeline-item-view-template'
  tagName: 'li'

  serializeData: ->
    _.extend @model.toJSON(), datetime: moment(@model.get('datetime')).format('YYYY-MM-DD HH:MM')


class TimelineView extends Marionette.CollectionView
  itemView: TimelineItemView
  tagName: 'ul'
  id: 'timeline'
  className: 'timeline'

  initialize: ->
    @collection = new History()

  onRender: ->

  onShow: ->

  addTimelineItem: (timeline_item)->
    @collection.push(timeline_item)