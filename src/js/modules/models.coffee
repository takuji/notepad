class Notepad extends Backbone.Model
  initialize: (attrs, options)->
    @settings = {}
    @scenes = ['notes', 'note-edit']
    @current_scene = @scenes[0]
    @repository = new FileSystemRepository()
    @notes      = new NoteCollection()
    @note_index = new NoteIndex()
    @note_index.listenTo @notes, 'add', @note_index.onNoteAdded

  prepareWorkspace: ->
    @repository.createWorkspace().then(
      ()=> @
      (error)=>
        throw error)

  createNote: ->
    note = @notes.newNote()
    @saveNote(note).then(
      ()=>
        @saveNoteIndex()
        note)

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
    @repository.saveNote(note).then(
      ()=>
        console.log "Note #{note.id} saved."
        @note_index.onNoteUpdated(note)
        @saveNoteIndex()
        note)

  saveNoteIndex: ->
    @repository.saveNoteIndex(@note_index)

  getNoteIndex: ->
    Q.fcall =>
      if @note_index.isUpToDate()
        @note_index
      else
        @loadNoteIndex()
  # Load note index from the storage
  # and reset the note index.
  loadNoteIndex: ->
    @repository.loadNoteIndex().then(
      (arr)=> 
        items = _.map arr, (json)=> new NoteIndexItem(json)
        @note_index.reset(items)
        @note_index
      (error)=>
        console.log error)

#
#
#
class NoteIndex extends Backbone.Collection
  initialize: ->
    @up_to_date = false
    @listenTo @, 'reset', => @up_to_date = true

  updateIndex: (note)->
    item = @get(note.id)
    item.reset(note)

  onNoteUpdated: (note)->
    @updateIndex(note)
    console.log "NoteIndex.onNoteUpdated #{note.id}"

  onNoteAdded: (note)->
    @unshift NoteIndexItem.fromNote(note)
    console.log "NoteIndex.onNoteAdded #{note.id}"
    note

  isUpToDate: ->
    @up_to_date

#
#
#
class NoteIndexItem extends Backbone.Model
  reset: (note)->
    if @id == note.id
      @set(
        title: note.get('title')
        updated_at: note.get('updated_at'))

NoteIndexItem.fromNote = (note)->
  new NoteIndexItem(
    id: note.id
    title: note.get('title')
    created_at: note.get('created_at')
    updated_at: note.get('updated_at'))


#
#
#
class Note extends Backbone.Model
  initialize: ->
    @changed = false
    @_updateTitle()
    @_compile()

  updateContent: (content)->
    if content != @get('content')
      @changed = true
      @set content: content, title: @_titleOfContent(content)
      @_compile()
      console.log 'Note.updateContent'
    console.log @attributes

  _updateTitle: ->
    @set title: @_titleOfContent(@get('content'))

  _compile: ->
    if @get('content')
      @set html: marked(@get('content'))

  _titleOfContent: (content)->
    if _.isEmpty(content)
      'Untitled'
    else
      content.split('\n')[0]

  getMap: ->
    new NoteMap().attachNote(@)

  getInfo: ->
    {id: @id, title: @get('title'), created_at: @get('created_at'), updated_at: @get('updated_at')}


#
#
#
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

  # Creates a new note instance and add it to the head of this collection
  # Returns the new note.
  newNote: (params)->
    note = new Note(id: @_nextNoteId(), title: 'Untitled', content: '')
    @unshift(note)
    note

  _nextNoteId: ->
    Date.now()

  onNoteAdded: (note)->
    console.log "Note #{note.id} added"
