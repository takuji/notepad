class NotesScene extends Marionette.Layout
	template: '#notes-template'

	regions:
		note_list: '#note-list'
		note: '#note'

	initialize: ->
		@note_list_view = new NoteListView()
		@note_view = new NoteView()

	onRender: ->
		@note_list.show @note_list_view
		@note.show @note_view


class NoteListView extends Marionette.CollectionView
	item: NoteListItemView


class NoteListItemView extends Marionette.ItemView
	template: '#note-list-item-template'


class NoteView extends Marionette.ItemView
	template: '#note-template'


class NoteEditScene extends Marionette.Layout
	template: '#note-edit-template'
