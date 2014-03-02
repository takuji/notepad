#
# model: Notepad
#
class NotesScene extends NoteListScene
  id: 'note-list-scene'
  className: 'scene note-list-scene'

  keymapData:
    'J': 'nextNote'
    'K': 'prevNote'
    'N': 'newNote'
    'ENTER': 'editCurrentNote'
    'DELETE': 'deleteCurrentNote'

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

