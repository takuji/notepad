class Notepad extends Backbone.Model
	initialize: ->
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
			notes: new NotesScene(model: option.model)
			note_edit: new NoteEditScene(model: option.model)
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

notes = 
	1: {title: 'ネコ', content: '吾輩は猫である。'}
	2: {title: 'いぬ', content: '名前はまだない。'}
	1: {title: '猿', content: 'にゃーん。'}

notepad = new Notepad(documents: notes)

app = new App()
scenes = new Scenes(app: app, model: notepad)

app.addInitializer (options)->
	app.addRegions scene: '#scene'
	scenes.showScreen('notes')
	Backbone.history.start()

app.start()
