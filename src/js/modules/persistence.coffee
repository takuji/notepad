class FileSystemRepository
  settings:
    root_path: "#{process.env.HOME || process.env.HOMEPATH || process.env.USERPROFILE}/.notepad"

  constructor: (options)->
    {@root_path} = @settings
    console.log @root_path

  createWorkspace: ->
    Q.fcall =>
      @_prepareDirectory @getNotesDirectory(), (error)=>
        if error
          throw error

  save: (note)->
    Q.fcall (=> @saveNoteSync(note))

  saveNote: (note)->
    Q.fcall (=> @saveNoteSync(note))

  saveNoteSync: (note)->
    if note
      @_prepareDirectory @getNoteDirectory(note), (err)=>
        if err
          throw err
        @_saveNote(note)

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

  _prepareDirectory: (dir_path, callback)->
    fs.exists dir_path, (exists)=>
      if exists
        callback(null) if callback
      else
        fs.mkdir dir_path, (err)=>
          if err && err.errno == 34
            @_prepareDirectory(path.dirname(dir_path), callback)
            @_prepareDirectory(dir_path, callback)
          callback(err) if callback

  saveNoteIndex: (index)->
    Q.fcall (=> @saveNoteIndexSync(index))

  saveNoteIndexSync: (index)->
    @_prepareDirectory @getNotesDirectory(), (err)=>
      if err
        throw err
      json = JSON.stringify(index.toJSON())
      console.log json
      fs.writeFile @getIndexFilePath(), json, {encoding: 'utf-8'}, (err)=>
        if err
          throw err
        console.log "Note index is saved to #{@getIndexFilePath()}"

  loadNoteIndex: ->
    Q.fcall ()=> @loadNoteIndexSync()

  loadNoteIndexSync: ->
    s = fs.readFileSync @getIndexFilePath()
    JSON.parse(s)
