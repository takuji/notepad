class Note extends Backbone.Model
	initialize: ->
		@listenTo @, 'change:content', @compile
		@compile()

	compile: ->
		@set html: marked(@get('content'))

class NoteCollection extends Backbone.Collection
	initialize: ->
		console.log @
		console.log @length
		@listenTo @, 'add', @onNoteAdded
		console.log "@id_seed is #{@id_seed}"

	createNote: (params)->
		console.log "LENGTH: #{@length}"
		note = new Note(id: @_nextNoteId(), title: 'Untitled', content: '')
		@unshift(note)
		note

	_nextNoteId: ->
		Date.now()

	onNoteAdded: (note)->
		console.log "Note #{note.id} added"
