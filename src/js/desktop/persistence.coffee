class FileSystemRepository

  constructor: (options)->
    @settings = options.settings
    @note_index_storage = null
    @deleted_notes_storage = null

  setupWorkspace: ->
    @_createNotesDirectory()
    .then(()=>
      @note_index_storage = new NoteIndexStorage(file_path: @getNoteIndexFilePath())
      @note_index_storage.prepare())
    .then(()=>
      @deleted_notes_storage = new NoteIndexStorage(file_path: @getDeletedNotesIndexFilePath())
      @deleted_notes_storage.prepare())

  _createNotesDirectory: ->
    FileUtils.createDirectory(@getNotesDirectory())

  saveNote: (note)->
    d = Q.defer()
    FileUtils.createDirectory(@getNoteDirectory(note.id))
    .then((dir)=> @_saveNote(note))
    .then((note)=> d.resolve(note))
    .catch((error)=> d.reject(d))
    d.promise

  _saveNote: (note)->
    file_path = @getNoteFilePath(note.id)
    s = JSON.stringify(note.toJSON())
    fs.writeFileSync file_path, s, {encoding: 'utf-8'}
    console.log "Note is saved to #{file_path}"
    note

  loadNote: (note_id)->
    FileUtils.slurp(@getNoteFilePath(note_id))
    .then((json)=> JSON.parse(json))

  getNotesDirectory: ->
    "#{@settings.getWorkspaceDirectory()}/notes"

  getNoteIndexFilePath: ->
    "#{@getNotesDirectory()}/index.db"

  getDeletedNotesIndexFilePath: ->
    "#{@getNotesDirectory()}/deleted_notes.db"

  getNoteDirectory: (note_id)->
    "#{@getNotesDirectory()}/#{note_id}"

  getNoteFilePath: (note_id)->
    "#{@getNoteDirectory(note_id)}/note.json"

  saveNoteIndexItem: (note_index_item)->
    if note_index_item.get('_id')
      @note_index_storage.update(note_index_item)
    else
      @note_index_storage.add(note_index_item)

  loadNoteIndex: ->
    @note_index_storage.getAll()

  deleteNoteIndexItem: (note_index_item)->
    @deleted_notes_storage.add(note_index_item)
    .then(() => @note_index_storage.destroy(note_index_item))

#
#
#
class NoteIndexStorage
  constructor: (options)->
    unless options.file_path
      throw new Error 'file_path is required'
    @file_path = options.file_path
    @db = null
    @ready = false

  prepare: ->
    @_prepare().then(
      ()=>
        @db = new Datastore(filename: @file_path, autoload: true)
        @ready = true)

  _prepare: ->
    d = Q.defer()
    dir = path.basename @file_path
    fs.exists dir, (exists)=>
      if exists || @ready
        d.resolve()
      else
        mkdirp dir, (err)=>
          if err
            d.reject(err)
          else
            d.resolve()
    d.promise

  add: (index_item)->
    d = Q.defer()
    json = index_item.toJSON()
    now = new Date()
    json.created_at = now
    json.updated_at = now
    @db.insert json, (err, item)=>
      if err
        d.reject(err)
      else
        d.resolve(item)
    d.promise

  update: (index_item)->
    d = Q.defer()
    json = index_item.toJSON()
    now = new Date()
    _id = json._id
    delete json._id
    json.updated_at = now
    @db.update {_id: _id}, json, {}, (err, num)=>
      if err
        d.reject(err)
      else
        index_item.updated_at = now
        d.resolve(index_item)
    d.promise

  destroy: (index_item)->
    d = Q.defer()
    @db.remove {_id: index_item.get('_id')}, {}, (err)=>
      if err
        d.reject(err)
      else
        d.resolve()
    d.promise

  getAll: (options)->
    d = Q.defer()
    @db.find({}).sort({updated_at: -1}).exec (err, items)=>
      if err
        d.reject(err)
      else
        d.resolve(items)
    d.promise
