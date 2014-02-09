class NoteManager
  constructor: (options)->

  getNotes: (options)->


class FileSystemRepository
  settings:
    root_path: "#{process.env.HOME || process.env.HOMEPATH || process.env.USERPROFILE}/.notepad"

  constructor: (options)->
    {@root_path} = @settings
    console.log @root_path

  save: (note)->
    Q.fcall (=> @_save(note))

  _save: (note)->
    dir_path = @getNoteDirectory(note)
    @_prepareDirectory dir_path, (err)->
      if err
        throw err
      file_path = "#{dir_path}/content.md"
      console.log file_path
      console.log note.get('content')
      fs.writeFile file_path, note.get('content'), (err)=>
        if err
          throw err

  load: (id)->

  getNoteDirectory: (note)->
    "#{@root_path}/notes/#{note.id}"

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
