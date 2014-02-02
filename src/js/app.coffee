class Notepad
	constructor: ->
		@scenes = ['notes', 'note-edit']
		@current_scene = @scenes[0]
		@documents = {}	# id => Note
		console.log 'Application initialized.'


class Scenes extends Backbone.Router
	routes:
		'notes': 'list'
		'notes/:id/edit': 'edit'

	initialize: (option)->
		@app = option.app
		@scenes =
			notes: new NotesScene()
			note_edit: new NoteEditScene()
		console.log 'Screens initialized.'

	list: ->
		console.log 'list'
		@showScreen('notes')

	edit: (id)->
		console.log "edit #{id}"
		@showScreen('note_edit')

	showScreen: (screen_id)->
		@app.scene.show @scenes[screen_id]


class App extends Marionette.Application

notepad = new Notepad()

app = new App()
scenes = new Scenes(app: app)

app.addInitializer (options)->
	app.addRegions scene: '#scene'
	scenes.showScreen('notes')
	Backbone.history.start()

app.start()
