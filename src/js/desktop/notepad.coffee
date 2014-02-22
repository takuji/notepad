class Notepad extends Backbone.Model
  initialize: (attrs, options)->
    @settings = new Settings()
    @scenes = ['notes', 'note-edit']
    @current_scene = @scenes[0]
    @repository = new FileSystemRepository(settings: @settings)
    @notes      = new NoteCollection()
    @note_index = new NoteIndex()
    @note_index.listenTo @notes, 'add', @note_index.onNoteAdded
    @historian = new Historian(settings: @settings)

  prepareWorkspace: ->
    @_prepareHomeDirectory()
    .then(()=> @_prepareSettings())
    .then(()=> @repository.setupWorkspace())
    .then(()=> @historian.prepare())
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
    @saveNote(note)
    .then(()=>
      event = new NoteHistoryEvent(note: note, event: 'create')
      @historian.addEvent(event))
    .then(
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
      note = @notes.get(note_id)
      @repository.deleteNoteIndexItem(index_item)
      .then(()=>
        @note_index.remove(index_item)
        console.log "Note #{note_id} is moved to the deleted notes collection")
      .then(()=>
        event = new NoteHistoryEvent(note: note, event: 'delete')
        @historian.addEvent(event))

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
    toolbar:
      dev_tools: false

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

  getToolbarSettings: ->
    @get('toolbar')

  changeWorkspaceDirectory: (path)->
    @get('workspace').root_path = path

  save: ->
    s = JSON.stringify(@toJSON(), null, 2)
    FileUtils.spit(@getFilePath(), s)
