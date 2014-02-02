class NotesScene extends Marionette.Layout
  template: '#notes-template'
  id: 'notes'
  className: 'notes scene'

  regions:
    note_list_region: '#sidebar'
    note_region: '#note'

  initialize: ->
    @note_list_view = new NoteListView(collection: @model.documents, parent: @)
    @note_view = new NoteView()

  onRender: ->
    @_resize()
    @note_list_region.show @note_list_view
    if @model.documents.length > 0
      @note_region.show @note_view
    $(window).on 'resize', => @_resize()

  _resize: ->
    $window = $(window)
    margin = @$el.offset().top
    @$el.height($window.height() - margin)

  selectNote: (note_id)->
    note = @model.documents.get(note_id)
    console.log note
    if note
      @note_view.changeNote(note)
      @note_region.show @note_view


class NoteListItemView extends Marionette.ItemView
  template: '#note-list-item-template'
  tagName: 'li'
  className: 'note-list-item'

  events:
    'click': 'onClicked'

  onClicked: (e)->
    @trigger 'note:selected', id: @model.id


class NoteListView extends Marionette.CollectionView
  itemView: NoteListItemView
  tagName: 'ul'
  className: 'note-list'

  initialize: (options)->
    @parent = options.parent
    @on 'itemview:note:selected', @selectNote, @

  selectNote: (view, params)->
    @parent.selectNote params.id
    console.log "select note #{params.id}"


class NoteView extends Marionette.ItemView
  template: '#note-template'
  id: 'note'
  className: 'note'

  serializeData: ->
    console.log "serializing.. #{@model}"
    if @model
      @model.toJSON()
    else
      {title: 'Untitled', content: ''}

  changeNote: (note)->
    console.log note
    @model = note
    @render()


class NoteEditScene extends Marionette.Layout
  template: '#note-edit-template'
  id: 'note-edit'
  className: 'note-edit scene'
