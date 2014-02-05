class NotesScene extends Marionette.Layout
  template: '#notes-template'
  id: 'notes'
  className: 'notes scene'

  regions:
    note_list_region: '#sidebar'
    note_region: '#note'

  initialize: ->
    @current_note = @model.documents[0] if @model.documents.length > 0
    console.log "NotesScene created at #{new Date()}"

  onRender: ->
    @_resize()
    @note_list_region.show new NoteListView(collection: @model.documents, parent: @)
    @note_region.show new NoteView(model: @current_note)
    $(window).on 'resize', => @_resize()

  _resize: ->
    $window = $(window)
    margin = @$el.offset().top
    @$el.height($window.height() - margin)

  selectNote: (note_id)->
    @current_note = @model.documents.get(note_id)
    if @current_note
      @note_region.currentView.changeNote(@current_note)

class NoteListItemView extends Marionette.ItemView
  template: '#note-list-item-template'
  tagName: 'li'
  className: 'note-list-item'

  events:
    'click': 'onClicked'

  initialize: ->
    console.log "NoteListItemView#initialize #{@model.id}"

  serializeData: ->
    _.extend @model.toJSON(), updated_at: moment(@model.get('updated_at')).format('YYYY/MM/DD')

  onClicked: (e)->
    @trigger 'note:selected', id: @model.id


class NoteListView extends Marionette.CollectionView
  itemView: NoteListItemView
  tagName: 'ul'
  className: 'note-list'

  initialize: (options)->
    @parent = options.parent
    @on 'itemview:note:selected', @selectNote, @
    console.log 'NoteListView#initialize'

  onRender: ->
    console.log @._events
    console.log 'NoteListView#onRender'

  selectNote: (view, params)->
    console.log "Note #{params.id} selected."
    @parent.selectNote params.id

  onItemRemoved: (itemView)->
    console.log "NoteListView#itemRemoved #{itemView.model.id}"

  onClose: ->
    console.log @._events
    console.log 'NoteListView#onClose'

  onItemAdded: (view)->
    console.log "NoteListView#onItemAdded #{view.model.id}"


class NoteView extends Marionette.ItemView
  template: '#note-template'
  id: 'note'
  className: 'note'

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
