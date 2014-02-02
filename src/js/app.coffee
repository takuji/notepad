console.log 'hello'

class Screens extends Backbone.Router
	routes:
		'notes': 'list'
		'notes/:id/edit': 'edit'

	list: ->
		console.log 'list'
		@showScreen('notes')

	edit: (id)->
		console.log "edit #{id}"
		@showScreen('note-edit')

	showScreen: (screen_id)->
		$('.screen').hide()
		$("##{screen_id}").show()

new Screens()

Backbone.history.start()
