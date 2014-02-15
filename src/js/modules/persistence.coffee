class FileSystemRepository
  settings:
    root_path: "#{process.env.HOME || process.env.HOMEPATH || process.env.USERPROFILE}/.notepad"

  constructor: (options)->
    {@root_path} = @settings
    @note_index_storage = new NoteIndexStorage(file_path: @getNoteIndexFilePath())
    console.log @root_path

  createWorkspace: ->
    @_createHomeDirectory().then(
      ()=> @note_index_storage.prepare())

  _createHomeDirectory: ->
    d = Q.defer()
    mkdirp @getNotesDirectory(), (error)=>
      if error
        d.reject(error)
      else
        console.log "Directory #{@getNotesDirectory()} created."
        d.resolve()
    d.promise

  prepareDirectory: (dir)->
    d = Q.defer()
    mkdirp dir, (error)=>
      if error
        d.reject(error)
      else
        d.resolve(dir)
    d.promise

  saveNote: (note)->
    d = Q.defer()
    @prepareDirectory(@getNoteDirectory(note))
    .then((dir)=> @_saveNote(note))
    .then((note)=> d.resolve(note))
    .catch((error)=> d.reject(d))
    d.promise

  _saveNote: (note)->
    file_path = @getNoteFilePath(note)
    s = JSON.stringify(note.toJSON())
    fs.writeFileSync file_path, s, {encoding: 'utf-8'}
    console.log "Note is saved to #{file_path}"
    note

  loadNote: (id)->
    Q.fcall (=> @loadNoteSync(id))

  loadNoteSync: (id)->
    json = fs.readFileSync("#{@root_path}/notes/#{id}/note.json", 'utf-8')
    JSON.parse(json)

  getNoteDirectory: (note)->
    "#{@root_path}/notes/#{note.id}"

  getNoteFilePath: (note)->
    "#{@getNoteDirectory(note)}/note.json"

  getNotesDirectory: ->
    "#{@root_path}/notes"

  getIndexFilePath: ->
    "#{@getNotesDirectory()}/index.json"

  getNoteIndexFilePath: ->
    "#{@getNotesDirectory()}/index.db"

  saveNoteIndex: (index)->
    @prepareDirectory(@getNotesDirectory())
    .then(()=> @_saveNoteIndex(index))

  saveNoteIndexItem: (note_index_item)->
    if note_index_item.get('_id')
      @note_index_storage.update(note_index_item)
    else
      @note_index_storage.add(note_index_item)

  _saveNoteIndex: (index)->
    json = JSON.stringify(index.toJSON())
    d = Q.defer()
    fs.writeFile @getIndexFilePath(), json, {encoding: 'utf-8'}, (err)=>
      if err
        d.reject(err)
      else
        d.resolve(index)
      console.log "Note index is saved to #{@getIndexFilePath()}"
    d.promise

  loadNoteIndex: ->
    @note_index_storage.getAll()

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

  # _hoge: (f, context, args)->
  #   d = Q.defer()
  #   callback = (err, result)=>
  #     if err
  #       d.reject(err)
  #     else
  #       d.resolve(result)
  #   args.push callback
  #   f.apply context, args
  #   d.promise

