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
