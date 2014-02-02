class NotesScene extends Marionette.Layout
	template: '#notes-template'
	id: 'notes'
	className: 'notes scene'

	regions:
		note_list: '#note-list'
		note: '#note'

	initialize: ->
		@note_list_view = new NoteListView()
		@note_view = new NoteView()

	onRender: ->
		@_resize()
		@note_list.show @note_list_view
		@note.show @note_view
		$(window).on 'resize', => @_resize()

	_resize: ->
    $window = $(window)
    margin = 0
    @$el.height($window.height() - margin)



class NoteListView extends Marionette.CollectionView
	item: NoteListItemView


class NoteListItemView extends Marionette.ItemView
	template: '#note-list-item-template'


class NoteView extends Marionette.ItemView
	template: '#note-template'
	id: 'note'
	className: 'note'


class NoteEditScene extends Marionette.Layout
	template: '#note-edit-template'
	id: 'note-edit'
	className: 'note-edit scene'
