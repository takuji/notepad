#
# model: Notepad
#
class NotesScene extends Marionette.Layout
  template: '#notes-template'
  id: 'notes'
  className: 'notes scene'

  regions:
    note_list_region: '#sidebar'
    note_region: '#note'

  keymapData:
    'J': 'nextNote'
    'K': 'prevNote'
    'N': 'newNote'
    'ENTER': 'editCurrentNote'
    'DELETE': 'deleteCurrentNote'

  initialize: ->
    @current_note = null
    @keymap = Keymap.createFromData(@keymapData, @)
    $(window).on 'resize', => @_resize()
    console.log "NotesScene created at #{new Date()}"

  onRender: ->
    note_list_view = new NoteListView(collection: @model.note_index)
    note_view = new NoteView(model: @current_note)
    @note_list_region.show(note_list_view)
    @note_region.show(note_view)
    @listenTo note_list_view, 'note:selected', @onNoteSelected

  onShow: ->
    @_resize()
    @model.loadIndex().then(
      ((note_index)=>
        @model.note_index.reset(note_index.models)),
      ((error)=>
        console.info error))

  _resize: ->
    $window = $(window)
    margin = @$el.offset().top
    @$el.height($window.height() - margin)

  onNoteSelected: (note_info)->
    @model.getNote(note_info.id)
    .then((note)=>
      console.log '------------->>>'
      console.log note
      @current_note = note
      @note_region.currentView.changeNote(@current_note))

  nextNote: ->
    console.log 'next note'
    @note_list_region.currentView.selectNextNote()

  prevNote: ->
    console.log 'prev note'
    @note_list_region.currentView.selectPrevNote()

  newNote: ->
    console.log 'new note'
    new_note = @model.notes.createNote()
    location.href = "#notes/#{new_note.id}/edit"

  editCurrentNote: ->
    console.log 'edit current note'
    @note_list_region.currentView.editCurrentNote()

  deleteCurrentNote: ->
    console.log 'delete current note'


class NoteListItemView extends Marionette.ItemView
  template: '#note-list-item-template'
  tagName: 'li'
  className: 'note-list-item'

  events:
    'click': 'onClicked'
    'dblclick': 'onDoubleClicked'

  initialize: ->
    console.log @model
    console.log "NoteListItemView#initialize #{@model.id}"

  serializeData: ->
    _.extend @model.toJSON(), updated_at: moment(@model.get('updated_at')).format('YYYY/MM/DD')

  onClicked: (e)->
    @select()

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


class NoteListView extends Marionette.CollectionView
  itemView: NoteListItemView
  tagName: 'ul'
  className: 'note-list'

  initialize: (options)->
    @on 'itemview:note:selected', @onNoteSelected, @
    @current_item_view = null
    console.log 'NoteListView#initialize'

  onRender: ->
    console.log @._events
    console.log 'NoteListView#onRender'

  onNoteSelected: (view)->
    note = view.model
    console.log "Note #{note.id} selected."
    @_unselectCurrent()
    @_selectCurrent(view)
    @trigger 'note:selected', note

  onItemRemoved: (itemView)->
    console.log "NoteListView#itemRemoved #{itemView.model.id}"

  onClose: ->
    console.log @._events
    console.log 'NoteListView#onClose'

  onItemAdded: (view)->
    console.log "NoteListView#onItemAdded #{view.model.id}"


  selectNextNote: ->
    view = @nextNoteView()
    if view
      @_unselectCurrent()
      view.select()

  selectPrevNote: ->
    view = @prevNoteView()
    console.log "view #{view}"
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

class NoteView extends Marionette.ItemView
  id: 'note'
  className: 'note'
  template: (serializedData)->
    if @current_note
      _.template $('#note-template').html(), serializeData
    else
      _.template $('#note-empty-template').html(), {}

  serializeData: ->
    console.log "serializing.. #{@model}"
    if @model
      @model.toJSON()
    else
      {title: 'Untitled', html: ''}

  changeNote: (note)->
    console.log note
    @model = note
    @render()
