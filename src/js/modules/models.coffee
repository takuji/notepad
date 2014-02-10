class Note extends Backbone.Model
  initialize: ->
    console.log @attributes
    @listenTo @, 'change:content', @onContentUpdated
    @onContentUpdated()

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

  getIndex: ->
    new NoteIndex().attachNote(@)

  getInfo: ->
    {id: @id, title: @get('title'), created_at: @get('created_at'), updated_at: @get('updated_at')}

class NoteIndex extends Backbone.Model
  initialize: ->
    @index_items = new Backbone.Collection()

  attachNote: (note)->
    @stopListening()
    @listenTo note, 'change:content', => @_updateItems(note.get('content'))
    @listenTo note, 'change:title', => @_updateTitle(note.get('title'))
    @_updateItems(note.get('content'))
    @_updateTitle(note.get('title'))
    @

  getItems: ->
    @index_items

  _updateItems: (content)->
    @index_items.reset(@_createIndexListFromContent(content))

  _updateTitle: (title)->
    @set(title: title)

  _createIndexListFromContent: (markdownString)->
    if markdownString
      lines = markdownString.split("\n")
      lines_with_index = $.map(lines, (line, i)->{title: line, line: i + 1})
      indexes = $.grep(lines_with_index, (title_and_index, i)->title_and_index.title.match("^#+"))
      $.map(indexes, (idx)->
        idx.title.match(/^(#+)(.*)$/)
        title = $.trim(RegExp.$2)
        depth = RegExp.$1.length
        new NoteIndexItem($.extend(idx, {depth: depth, title: title}))
      )
    else
      []

  hoge: ->
    alert 'Hoge!'

class NoteIndexItem extends Backbone.Model


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
