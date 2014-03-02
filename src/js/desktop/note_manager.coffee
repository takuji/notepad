class NoteManager

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

  getNoteHistoryFilePath: (note_id)->
    "#{@getNoteDirectory(note_id)}/history.db"

  saveNoteIndexItem: (note_index_item)->
    if note_index_item.get('_id')
      @note_index_storage.update(note_index_item)
    else
      @note_index_storage.add(note_index_item)

  loadNoteIndex: ->
    @note_index_storage.getAll()

  loadActiveNoteIndex: ->
    @note_index_storage.onlyActive()

  deleteNoteIndexItem: (note_index_item)->
    note_index_item.delete()
    @note_index_storage.update(note_index_item)

  deleteNote: (note_id)->
    @note_index_storage.findByNoteId(note_id)
    .then(
      (json)=>
        note_index = new NoteIndexItem(json)
        note_index.delete()
        @note_index_storage.update(note_index))

  getActiveNoteIndexes: (params)->
    @note_index_storage.get(params)

  getArchivedNoteIndexes: (params)->
    @note_index_storage.getArchivedNoteIndexes(params)

  addEvent: (note_event)->
    console.log note_event
    d = Q.defer()
    db = new Datastore(filename: @getNoteHistoryFilePath(note_event.get('note_id')), autoload: true)
    db.insert note_event.toJSON(), (err, item)=>
      if err
        d.reject(err)
      else
        d.resolve(note_event)
    d.promise

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

  uniq: ->
    @getAll()
    .then(
      (items)=>
        _.groupBy items, (item)-> item.id)
    .then(
      (groups)=>
        console.log groups
        values = _.values(groups)
        console.log values
        latests = _.map values, (indexes)-> _.first(indexes))
    .then(
      (latests)=>
        console.log latests
        @_removeAll()
        latests)
    .then(
      (latests)=>
        @db.insert latests, (err, docs)=>
          if err
            console.error err
            false
          else
            true)

  _removeAll: ->
    d = Q.defer()
    @db.remove {}, {multi: true}, (err, num)=>
      console.log num
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
        index_item.set(item)
        d.resolve(index_item)
      console.log "NOTE INDEX ADDED #{index_item.id}"
    d.promise

  update: (index_item)->
    d = Q.defer()
    json = index_item.toJSON()
    now = new Date()
    _id = json._id
    delete json._id
    json.updated_at = now
    console.log json
    @db.update {_id: _id}, json, {}, (err, num)=>
      if err
        d.reject(err)
      else
        index_item.updated_at = now
        d.resolve(index_item)
      console.log "NOTE INDEX UPDATED #{index_item.id}"
    d.promise

  destroy: (index_item)->
    d = Q.defer()
    @db.remove {_id: index_item.get('_id')}, {}, (err)=>
      if err
        d.reject(err)
      else
        d.resolve()
    d.promise

  findByNoteId: (note_id)->
    d = Q.defer()
    @db.find({id: note_id}).limit(1).exec (err, items)=>
      if err
        d.reject(err)
      else
        if items.length > 0
          d.resolve(items[0])
        else
          d.resolve(null)
    d.promise

  get: (options)->
    @_getNoteIndexes(options.offset, options.count, deleted: {$ne: true})

  getArchivedNoteIndexes: (options)->
    @_getNoteIndexes(options.offset, options.count, deleted: true)

  _getNoteIndexes: (offset, count, query)->
    offset = offset || 0
    count  = count || 100
    d = Q.defer()
    @db.find(query).sort({updated_at: -1}).skip(offset).limit(count).exec (err, items)=>
      if err
        d.reject(err)
      else
        d.resolve(items)
    d.promise

  getAll: (options)->
    d = Q.defer()
    @db.find({}).sort({updated_at: -1}).exec (err, items)=>
      if err
        d.reject(err)
      else
        d.resolve(items)
    d.promise

  onlyActive: (options)->
    d = Q.defer()
    @db.find({deleted: {$ne: true}}).sort({updated_at: -1}).exec (err, items)=>
      if err
        d.reject(err)
      else
        d.resolve(items)
    d.promise
