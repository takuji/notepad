class FileSystemRepository
  settings:
    root_path: "#{process.env.HOME || process.env.HOMEPATH || process.env.USERPROFILE}/.notepad"

  constructor: (options)->
    {@root_path} = @settings
    console.log @root_path

  createWorkspace: ->
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

  # _saveNote: (note)->
  #   d = Q.defer()
  #   fs.writeFile @getNoteFilePath(note), JSON.stringify(note.toJSON()), (error)=>
  #     if error
  #       d.reject(error)
  #     else
  #       d.resolve(note)
  #   d.promise

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

  saveNoteIndex: (index)->
    @prepareDirectory(@getNotesDirectory())
    .then(()=> @_saveNoteIndex(index))

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
    Q.fcall ()=> @loadNoteIndexSync()

  loadNoteIndexSync: ->
    s = fs.readFileSync @getIndexFilePath()
    JSON.parse(s)

class NoteIndexStorage
  constructor: (options)->
    unless @file_path
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
    fs.exists @file_path, (exists)=>
      if exists || @ready
        d.resolve()
      else
        mkdirp @file_path, (err)=>
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
    id = json._id
    delete json._id
    json.updated_at = now
    @db.update {_id: json._id}, json, {}, (err, num)=>
      if err
        d.reject(err)
      else
        d.resolve(num)
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

