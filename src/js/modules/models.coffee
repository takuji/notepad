class Notepad extends Backbone.Model
  initialize: (attrs, options)->
    @settings = new Settings()
    @scenes = ['notes', 'note-edit']
    @current_scene = @scenes[0]
    @repository = new FileSystemRepository(settings: @settings)
    @notes      = new NoteCollection()
    @note_index = new NoteIndex()
    @note_index.listenTo @notes, 'add', @note_index.onNoteAdded

  prepareWorkspace: ->
    @_prepareHomeDirectory()
    .then(()=> @_prepareSettings())
    .then(()=> @repository.setupWorkspace())
    .then(()=> @)
    .catch((error)=> throw error)

  _prepareHomeDirectory: ->
    FileUtils.createDirectory(@settings.getHomeDirectory())

  _prepareSettings: ->
    @settings.loadFile().then(
      null
      (err)=> @settings.save())

  createNote: ->
    note = @notes.newNote()
    @saveNote(note).then(
      ()=> note)

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

  # Save a note and update it's index
  saveNote: (note)->
    if note && note.isModified()
      @repository.saveNote(note).then(
        ()=>
          note.onSaved()
          @note_index.onNoteUpdated(note)
          item = @note_index.get(note.id)
          @repository.saveNoteIndexItem(item).then(
            (note_index_item)=> note))
    else
      d = Q.defer()
      d.resolve(note)
      d.promise

  deleteNote: (note_id)->
    index_item = @note_index.get(note_id)
    if index_item
      @repository.deleteNoteIndexItem(index_item).then(
        ()=>
          @note_index.remove(index_item)
          console.log "Note #{note_id} is moved to the deleted notes collection")

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
class Settings extends Backbone.Model
  defaults: ->
    workspace:
      root_path: @defaultWorkspaceDirectory()
    scenes:
      note_edit:
        note_map_level: 6

  initialize: ->

  loadFile: ()->
    FileUtils.slurp(@getFilePath()).then(
      (s)=>
        console.log "settings file loaded: #{s}"
        @set(JSON.parse(s))
        @)

  creatDefaultFile: ->
    s = JSON.stringify(@toJSON(), null, 2)
    FileUtils.spit(@getFilePath(), s)

  # Returns the directory where the settings file is located
  getHomeDirectory: ->
    "#{process.env.HOME || process.env.HOMEPATH || process.env.USERPROFILE}/.notepad"

  getFilePath: ->
    "#{@getHomeDirectory()}/settings.json"

  defaultWorkspaceDirectory: ->
    "#{@getHomeDirectory()}/data"

  getWorkspaceDirectory: ->
    @get('workspace').root_path

  getNotesDirectory: ->
    "#{@defaultWorkspaceDirectory()}/notes"

  getNoteEditSceneSettings: ->
    @get('note_edit_scene')

  getSceneSettings: (scene)->
    @get('scenes')[scene]

  changeWorkspaceDirectory: (path)->
    @get('workspace').root_path = path

  save: ->
    s = JSON.stringify(@toJSON(), null, 2)
    FileUtils.spit(@getFilePath(), s)

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
    @remove item
    @unshift item

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
    console.log "Note index of #{note.id} updated"
    console.log @attributes

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
    @_changed = false
    @_updateTitle()
    @_compile()

  onSaved: ->
    @_changed = false

  isModified: ->
    @_changed

  updateContent: (content)->
    if content != @get('content')
      @_changed = true
      @set content: content, title: @_titleOfContent(content)
      # @_compile()

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
class NoteMap extends Backbone.Collection

#
#
#
class NoteMapItem extends Backbone.Model
  initialize: (attrs)->
    unless attrs.line || attrs.title || attrs.depth
      throw new Error("Required parameter is missing")

  # note map items are the same if their title and depth are equal respectively.
  isSame: (other)->
    @get('title') == other.get('title') && @get('depth') == other.get('depth')

  adjustLine: (other)->
    if @isSame(other)
      if @get('line') != other.get('line')
        @set 'line', other.get('line') if @get('line') != other.get('line')


#
#
#
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
    cuid()

  onNoteAdded: (note)->
    console.log "Note #{note.id} added"
