class Notepad extends Backbone.Model
  initialize: (attrs, options)->
    @settings = new Settings()
    @scenes = ['notes', 'note-edit']
    @current_scene = @scenes[0]
    @note_manager    = new NoteManager(settings: @settings)
    @history_manager = new HistoryManager(settings: @settings)
    @notes           = new NoteCollection()
    @note_index      = new NoteIndex()
    @note_index.listenTo @notes, 'add', @note_index.onNoteAdded

  prepareWorkspace: ->
    @_prepareHomeDirectory()
    .then(()=> @_prepareSettings())
    .then(()=> @note_manager.setupWorkspace())
    .then(()=> @history_manager.prepare())
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
      NoteCreateEvent.create(note))
    .then((event)=>
      @history_manager.addEvent(event))
    .then((event)=>
      @note_manager.addEvent(event))
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
    @note_manager.loadNote(note_id).then(
      (json)=> 
        note = new Note(json)
        @notes.add(note)
        note)

  # Save a note and update it's index
  saveNote: (note)->
    if note && note.isModified()
      @note_manager.saveNote(note).then(
        ()=>
          note.onSaved()
          @note_index.onNoteUpdated(note)
          item = @note_index.get(note.id)
          @note_manager.saveNoteIndexItem(item).then(
            (note_index_item)=> note))
    else
      d = Q.defer()
      d.resolve(note)
      d.promise

  deleteNote: (note_id)->
    index_item = @note_index.get(note_id)
    if index_item
      note = @notes.get(note_id)
      @note_manager.deleteNoteIndexItem(index_item)
      .then(()=>
        @note_index.remove(index_item)
        console.log "Note #{note_id} is moved to the deleted notes collection")
      .then(()=>
        event = NoteDeleteEvent.create(note)
        @history_manager.addEvent(event))
      .then((event)=>
        @note_manager.addEvent(event))

  getNoteIndex: ->
    Q.fcall =>
      if @note_index.isUpToDate()
        @note_index
      else
        @loadNoteIndex()
  # Load note index from the storage
  # and reset the note index.
  loadNoteIndex: ->
    @note_manager.loadNoteIndex().then(
      (arr)=> 
        items = _.map arr, (json)=> new NoteIndexItem(json)
        @note_index.reset(items)
        @note_index
      (error)=>
        console.log error)

  getNoteIndexItem: (note_id)->
    @getNoteIndex().then((note_index)=> note_index.get(note_id))

  getHistoryEvents: ->
    @history_manager.loadHistoryEvents()

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
