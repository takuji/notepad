class Note extends Backbone.Model
  initialize: ->
    @listenTo @, 'change:content', @onContentUpdated
    @compile()

  onContentUpdated: ->
    @compile()
    @updateTitle()

  compile: ->
    @set html: marked(@get('content'))

  updateTitle: ->
    @set title: @resolveTitle()

  resolveTitle: ->
    if _.isEmpty(@get('content'))
      'Untitled'
    else
      @get('content').split('\n')[0]


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
