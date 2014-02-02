class NotesScene extends Marionette.Layout
	template: '#notes-template'
	id: 'notes'
	className: 'notes scene'

	regions:
		note_list: '#note-list'
		note: '#note'

	initialize: ->
		@note_list_view = new NoteListView(collection: @model.documents)
		@note_view = new NoteView(model: @model)

	onRender: ->
		@_resize()
		@note_list.show @note_list_view
		@note.show @note_view
		$(window).on 'resize', => @_resize()

	_resize: ->
    $window = $(window)
    margin = @$el.offset().top
    @$el.height($window.height() - margin)


class NoteListItemView extends Marionette.ItemView
	template: '#note-list-item-template'


class NoteListView extends Marionette.CollectionView
	itemView: NoteListItemView


class NoteView extends Marionette.ItemView
	template: '#note-template'
	id: 'note'
	className: 'note'


class NoteEditScene extends Marionette.Layout
	template: '#note-edit-template'
	id: 'note-edit'
	className: 'note-edit scene'
