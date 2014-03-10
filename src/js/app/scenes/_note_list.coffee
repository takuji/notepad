#
# model: Notepad
#
class NoteListScene extends BaseScene
  template: '#note-list-scene-template'
  id: 'note-list-scene'
  className: 'scene note-list-scene'

  regions:
    main: '#main'
    note_list_pane: '#note-list-pane'

  keymapData:
    'J': 'nextNote'
    'K': 'prevNote'
    'N': 'newNote'
    'ENTER': 'editCurrentNote'
    'DELETE': 'deleteCurrentNote'

  initialize: ->
    super

  getNoteIndex: ->
    @model.getNoteIndex()

  onRender: ->
    @note_list_view = new NoteListView(collection: @getNoteIndex())
    @note_view      = new EmptyNoteView()
    @note_list_pane.show(@note_list_view)
    @main.show(@note_view)
    # Connect
    @listenTo @note_list_view, 'note:selected', @onNoteSelected
    @listenTo @note_list_view, 'note:delete', @deleteNote
    @note_list_pane.$el.on 'scroll', => @onNoteListPaneScrolled()
    console.log 'NotesScene.onRender'

  onShow: ->
    super
    console.log 'NotesScene.onShow'

  onClose: ->
    super

  _resize: ->
    super
    if @active
      $window = $(window)
      sidebar = @$('#sidebar')
      @main.$el.width($window.width() - sidebar.outerWidth())

  onNoteListPaneScrolled: (e)->
    @note_list_view.fetchEnoughNoteIndexes()

  onMoreNotesRequested: (view, options)->
    @note_index_reader.next()
    .then(
      (note_indexes)=>
        view.addNoteIndexes(note_indexes)
      (error)=>
        console.log error)

  onNoteSelected: (note_index)->
    console.log note_index
    @model.selectNote(note_index.id).then(
      (note)=>
        console.log note
        @main.show(new NoteView(model: note)))

  nextNote: ->
    @note_list_view.selectNextNote()

  prevNote: ->
    @note_list_view.selectPrevNote()

  # Action to create a new note
  # - create a note data
  # - save it
  # - set it to the note edite scene
  # - open the note edit scene
  newNote: ->
    @model.createNote()
    .then((note)=>
      @model.selectNote(note.id))
    .then((note)=>
      console.log note
      location.href = "#notes/#{note.id}/edit")

  # Action to open the note edit scene to start editing the current note
  editCurrentNote: ->
    @note_list_view.editCurrentNote()

  deleteCurrentNote: ->
    console.log 'delete current note'
    note = @model.getCurrentNote()
    if note
      @model.deleteNote(note.id)

  deleteNote: (note_id)->
    console.log "Deleting #{note_id}..."
    @model.deleteNote(note_id)

#
#
#
class NoteListItemView extends Marionette.ItemView
  template: '#note-list-item-template'
  tagName: 'li'
  className: 'note-list-item'

  events:
    'click .delete': 'onDeleteClicked'
    'click': 'onClicked'
    'dblclick': 'onDoubleClicked'

  initialize: ->
    @listenTo @model, 'change', @render

  serializeData: ->
    _.extend @model.toJSON(), updated_at: moment(@model.get('updated_at')).format('YYYY/MM/DD')

  onClicked: (e)->
    @select()

  onDeleteClicked: (e)->
    e.stopImmediatePropagation()
    @trigger 'note:delete'

  onDoubleClicked: (e)->
    @editNote()

  onRender: ->
    console.log 'NoteListItemView.onRender'

  select: ->
    @$el.addClass 'selected'
    @trigger 'note:selected'

  unselect: ->
    @$el.removeClass 'selected'

  editNote: ->
    location.href = "#notes/#{@model.id}/edit"

  getRect: ->
    pos = @$el.position()
    left:   pos.left
    top:    pos.top
    right:  pos.left + @$el.width()
    bottom: pos.top + @$el.height()

#
#
#
class NoteListMoreView extends Backbone.View
  className: 'more'

  events:
    'click': 'onClicked'

  onClicked: (e)->
    @trigger 'clicked'

  render: ->
    @$el.text('More')
    @


#
#
#
class NoteListView extends Marionette.CollectionView
  itemView: NoteListItemView
  tagName: 'ul'
  className: 'note-list'

  events:
    'click .more': 'onMoreClicked'

  initialize: (options)->
    @on 'itemview:note:selected', @onNoteSelected, @
    @on 'itemview:note:delete', @onDeleteClicked, @
    @current_item_view = null

  onRender: ->
    console.log 'NoteListView.onRender'
    @_addMoreButton()

  _addMoreButton: ->
    more_view = new NoteListMoreView()
    @more = more_view.render().$el
    @$el.after(@more)

  onShow: ->
    @fetchEnoughNoteIndexes()

  onMoreClicked: ->
    if @collection.hasNext()
      @collection.next()

  fetchEnoughNoteIndexes: ->
    if @_shouldFetchMoreNoteIndexes()
      @collection.next()
      .then(
        ()=>
          setTimeout(
            ()=> @fetchEnoughNoteIndexes()
            0)
        (error)=>
          console.log error)

  _shouldFetchMoreNoteIndexes: ->
    @collection.hasNext() && 
    @more.viewportOffset().top <= $(window).height()


  onNoteSelected: (view)->
    @_unselectCurrent()
    @_selectCurrent(view)
    @_scrollToShowCurrentView()
    @trigger 'note:selected', view.model
    console.log 'NoteListView.onNoteSelected'

  onDeleteClicked: (view)->
    console.log 'NoteListView.onNoteDeleteClicked'
    view.model.delete()
    @trigger 'note:delete', view.model.id

  onItemRemoved: (itemView)->
    console.log "NoteListView.itemRemoved #{itemView.model.id}"

  onClose: ->
    console.log 'NoteListView.onClose'

  onItemAdded: (view)->
    console.log "NoteListView.onItemAdded #{view.model.id}"

  selectNextNote: ->
    view = @nextNoteView()
    if view
      @_unselectCurrent()
      view.select()

  selectPrevNote: ->
    view = @prevNoteView()
    if view
      @_unselectCurrent()
      view.select()

  editCurrentNote: ->
    if @current_item_view
      @current_item_view.editNote()


  _selectCurrent: (view)->
    console.log 'selectCurrent'
    @current_item_view = view

  _unselectCurrent: ->
    if @current_item_view
      @current_item_view.unselect()

  nextNoteView: ->
    if @current_item_view
      idx = @collection.indexOf @current_item_view.model
      if @collection.length > idx + 1
        @children.findByIndex(idx + 1)
    else
      if @children.length > 0
        @children.first()

  prevNoteView: ->
    if @current_item_view
      idx = @collection.indexOf @current_item_view.model
      if idx > 0
        @children.findByIndex(idx - 1)

  _scrollToShowCurrentView: ->
    region = @$el.parent()
    region_height = region.height()
    region_top    = region.position().top
    note_list_top = @$el.position().top
    item_top      = @current_item_view.$el.position().top
    item_bottom   = item_top + @current_item_view.$el.outerHeight()
    item_top_in_note_list  = item_top - note_list_top
    item_bottom_in_note_list = item_bottom - note_list_top
    console.log
      region_height: region_height
      region_top: region_top
      note_list_top: note_list_top
      item_top: item_top
      item_bottom: item_bottom
      item_top_in_note_list: item_top_in_note_list
      item_bottom_in_note_list: item_bottom_in_note_list
    if item_top < region_top
      console.log 'Hidden upwards'
      region.scrollTop(item_top_in_note_list)
    else if item_bottom - region_top > region_height
      console.log 'Hidden downwards'
      region.scrollTop(item_bottom_in_note_list - region_height)
    console.log "_scrollToShowCurrentView"

