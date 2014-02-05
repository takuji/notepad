class Note extends Backbone.Model
	initialize: ->
		@listenTo @, 'change:content', @compile
		@compile()

	compile: ->
		@set html: marked(@get('content'))
