#
# model: Notepad
#
class NotesScene extends Marionette.Layout
  template: '#notes-template'
  id: 'notes'
  className: 'notes scene'

  regions:
    sidebar: '#sidebar'
    main: '#main'

  keymapData:
    'J': 'nextNote'
    'K': 'prevNote'
    'N': 'newNote'
    'ENTER': 'editCurrentNote'
    'DELETE': 'deleteCurrentNote'

  initialize: ->
    @active = false
    @current_note = null
    @keymap = Keymap.createFromData(@keymapData, @)
    $(window).on 'resize', => @_resize()
    console.log "NotesScene created at #{new Date()}"

  onRender: ->
    note_list_view = new NoteListView(collection: @model.note_index)
    note_view      = new NoteView(model: @current_note)
    @sidebar.show(note_list_view)
    @main.show(note_view)
    @listenTo note_list_view, 'note:selected', @onNoteSelected
    @listenTo note_list_view, 'note:delete', @deleteNote
    # Load note index data
    @model.getActiveNoteIndex().then(
      (note_index)=> console.log "NOTE INDEX UPDATED"
      (error)=> console.log "NOTE INDEX NOT LOADED")
    console.log 'NotesScene.onRender'

  onShow: ->
    @active = true
    @_resize()
    console.log 'NotesScene.onShow'

  onClose: ->
    @active = false

  _resize: ->
    if @active
      $window = $(window)
      margin = @$el.offset().top
      @$el.height($window.height() - margin)
      @main.$el.width($window.width() - @sidebar.$el.outerWidth())

  onNoteSelected: (note_info)->
    @model.getNoteAsync(note_info.id).then(
      (note)=>
        @current_note = note
        @main.currentView.changeNote(@current_note))

  nextNote: ->
    @sidebar.currentView.selectNextNote()

  prevNote: ->
    @sidebar.currentView.selectPrevNote()

  # Action to create a new note
  # - create a note data
  # - save it
  # - set it to the note edite scene
  # - open the note edit scene
  newNote: ->
    @model.createNote().then(
      (note)=>
        location.href = "#notes/#{note.id}/edit")

  # Action to open the note edit scene to start editing the current note
  editCurrentNote: ->
    @sidebar.currentView.editCurrentNote()

  deleteCurrentNote: ->
    console.log 'delete current note'
    @model.deleteNote(@current_note.id)

  deleteNote: (note_id)->
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
    console.log "DELETE?"

  onDoubleClicked: (e)->
    @editNote()

  onRender: ->
    if @model.get('deleted')
      @$el.hide()
      console.log "Note #{@model.id} is hidden because it is deleted."
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
    {
      left:   pos.left,
      top:    pos.top
      right:  pos.left + @$el.width()
      bottom: pos.top + @$el.height()
    }


class NoteListView extends Marionette.CollectionView
  itemView: NoteListItemView
  tagName: 'ul'
  className: 'note-list'

  initialize: (options)->
    @on 'itemview:note:selected', @onNoteSelected, @
    @on 'itemview:note:delete', @onDeleteClicked, @
    @current_item_view = null

  onRender: ->
    console.log 'NoteListView.onRender'

  onNoteSelected: (view)->
    @_unselectCurrent()
    @_selectCurrent(view)
    @_scrollToShowCurrentView()
    @trigger 'note:selected', view.model
    console.log 'NoteListView.onNoteSelected'

  onDeleteClicked: (view)->
    console.log 'NoteListView.onNoteDeleteClicked'
    console.log view.model
    @trigger 'note:delete', view.model.id

  onItemRemoved: (itemView)->
    #console.log "NoteListView.itemRemoved #{itemView.model.id}"

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
    console.log "region_top:#{region_top} note_list_top:#{note_list_top} item_top:#{item_top} item_bottom:#{item_bottom} item_top_in_note_list:#{item_top_in_note_list}"
    console.log "region_height: #{region_height}, item_bottom - region_top: #{item_bottom - region_top}"
    if item_top < region_top
      console.log 'Hidden upwards'
      region.scrollTop(item_top_in_note_list)
    else if item_bottom - region_top > region_height
      console.log 'Hidden downwards'
      region.scrollTop(item_bottom_in_note_list - region_height)
    console.log "_scrollToShowCurrentView"

class NoteView extends Marionette.ItemView
  id: 'note'
  className: 'note'
  template: (serializedData)->
    if serializedData.content
      _.template $('#note-template').html(), serializedData
    else
      _.template $('#note-empty-template').html(), {}

  events:
    'click a': 'onLinkClicked'

  onLinkClicked: (e)->
    e.preventDefault()
    Shell.openExternal $(e.target).attr('href')

  serializeData: ->
    if @model
      @model.toJSON()

  changeNote: (note)->
    console.log 'NoteView.changeNote'
    @model = note
    @render()

  onRender: ->
    @$el.toggleClass('note-empty', !@model?)
