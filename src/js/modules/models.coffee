class Notepad extends Backbone.Model
  initialize: (attrs, options)->
    @settings = {}
    @scenes = ['notes', 'note-edit']
    @current_scene = @scenes[0]
    @repository = new FileSystemRepository()
    @notes      = new NoteCollection()
    @note_index = new NoteIndex()
    @note_index.listenTo @notes, 'change', @note_index.onNoteUpdated

  createNote: ->
    note = @notes.createNote()
    @saveNote(note)

  getNoteAsync: (note_id)->
    note = @notes.get(note_id)
    Q.fcall =>
      if note
        note
      else
        @loadNote(note_id)

  loadNote: (note_id)->
    @repository.loadNote(note_id).then(
      (json)=> 
        note = new Note(json)
        @notes.add(note)
        note)

  saveNote: (note)->
    @repository.save(note)

  saveNoteIndex: ->
    @repository.saveIndex(@note_index)

  # Load note index from the storage
  # and reset the note index.
  loadIndex: ->
    @repository.loadIndex().then(
      (arr)=> 
        items = _.map arr, (json)=> new NoteIndexItem(json)
        @note_index.reset(items)
        @note_index)

#
#
#
class NoteIndex extends Backbone.Collection
  updateIndex: (note)->
    item = @get(note.id)
    item.reset(note)

  onNoteUpdated: (note)->
    console.log "NoteIndex.onNoteUpdated #{note.id}"


class NoteIndexItem extends Backbone.Model
  reset: (note)->
    if @id == note.id
      @set(title: note.title, updated_at: note.updated_at)


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
    new NoteMap().attachNote(@)

  getInfo: ->
    {id: @id, title: @get('title'), created_at: @get('created_at'), updated_at: @get('updated_at')}

class NoteMap extends Backbone.Model
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
        new NoteMapItem($.extend(idx, {depth: depth, title: title}))
      )
    else
      []

  hoge: ->
    alert 'Hoge!'

class NoteMapItem extends Backbone.Model


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
