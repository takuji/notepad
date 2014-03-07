class Notepad extends Backbone.Model
  initialize: (attrs, options)->
    # Settings
    @settings = new Settings()
    # File IO of Notes and Note Indexes
    @note_manager    = new NoteManager(settings: @settings)
    # File IO of History Events
    @history_manager = new HistoryManager(settings: @settings)
    # Note Indexes
    note_index_reader = new NoteIndexReader(note_manager: @note_manager)
    @note_indexes      = new NoteIndexCollection([], source: note_index_reader)
    # Archived Note Indexes
    archived_note_index_reader = new ArchivedNoteIndexReader(note_manager: @note_manager)
    @archived_note_indexes = new NoteIndexCollection([], source: archived_note_index_reader)
    # Notes cache
    @notes           = new NoteCollection()
    # Current active note
    @current_note = new CurrentNote()

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
    @_saveNote(note)
    .then((note)=>
      note_index = NoteIndexItem.fromNote(note)
      @note_indexes.push(note_index)
      )
    .then(()=>
      NoteCreateEvent.create(note))
    .then((event)=>
      @history_manager.addEvent(event))
    .then((event)=>
      @note_manager.addEvent(event))
    .then(()=>
      note)

  getNote: (note_id)->
    note = @notes.get(note_id)
    if note
      Q(note)
    else
      @loadNote(note_id)

  selectNote: (note_id)->
    @getNote(note_id)
    .then((note)=>
      @current_note.changeNote(note)
      note)

  getCurrentNote: ->
    @current_note.getNote()

  loadNote: (note_id)->
    @note_manager.loadNote(note_id).then(
      (json)=> 
        note = new Note(json)
        @notes.add(note)
        note)

  # Save a note and update it's index
  saveNote: (note)->
    if note && note.isModified()
      @_saveNote(note)
    else
      Q(note)

  _saveNote: (note)->
    @note_manager.saveNote(note)
    .then(()=>
      note.onSaved()
      @note_indexes.onNoteSaved(note)
      item = @note_indexes.get(note.id)
      @note_manager.saveNoteIndexItem(item).then(
        (note_index_item)=> note))

  deleteNote: (note_id)->
    console.log "Deleting note index #{note_id}"
    note_index = @note_indexes.get(note_id)
    if note_index
      @note_manager.deleteNote(note_id)
      .then(()=>
        @note_indexes.remove(note_index))
      .then(()=>
        @getNote(note_id))
      .then((note)=>
        console.log "Logging note index deletion #{note_id}"
        event = NoteDeleteEvent.create(note)
        @history_manager.addEvent(event))
      .then((event)=>
        @note_manager.addEvent(event))
      .then(()=>
        console.log 'Note deletion done')

  getNoteIndex: ->
    @note_indexes

  getNoteIndexReader: (options = {})->
    options.note_manager = @note_manager
    new NoteIndexReader(options)

  getArchivedNoteIndexReader: (options = {})->
    options.note_manager = @note_manager
    new ArchivedNoteIndexReader(options)

  # Load note index from the storage
  # and reset the note index.
  loadNoteIndex: ->
    @note_manager.loadNoteIndex().then(
      (arr)=> 
        items = _.map arr, (json)=> new NoteIndexItem(json)
        new NoteIndexCollection(items)
      (error)=>
        console.log error)

  loadActiveNoteIndex: ->
    @note_manager.loadActiveNoteIndex().then(
      (arr)=> 
        items = _.map arr, (json)=> new NoteIndexItem(json)
        @note_indexes.reset(items)
        @note_indexes
      (error)=>
        console.log error)

  getNoteIndexItem: (note_id)->
    @getActiveNoteIndex().then((note_index)=> note_index.get(note_id))

  getHistoryEvents: ->
    @history_manager.loadHistoryEvents().then(
      (attrs_list)=>
        attrs_list.map((attrs)=> new HistoryEvent(attrs)))

  getArchivedNoteIndex: ->
    @archived_note_indexes

#
#
#
class CurrentNote
  _.extend @::, Backbone.Events
  constructor: ->
    @note = null

  changeNote: (note)->
    @note = note
    @stopListening()
    @listenTo note, 'change', @onChanged
    @onChanged(note)

  onChanged: (note)->
    @trigger 'changed', note

  getNote: ->
    @note


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
