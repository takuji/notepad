console.log 'hello'

class Screens extends Backbone.Router
	routes:
		'notes': 'list'
		'notes/:id/edit': 'edit'

	list: ->
		console.log 'list'

	edit: (id)->
		console.log "edit #{id}"


new Screens()

Backbone.history.start()
