class Historian
  constructor: (options)->
    @settings = options.settings
    @history_file = null

  prepare: ->
    @_prepareHistoryDirectory()
    .then(()=>
      @history_file = new HistoryFile(file_path: @getHisotryFilePath()))

  _prepareHistoryDirectory: ->
    FileUtils.createDirectory(@getHistoryDirectory())

  getHistoryDirectory: ->
    "#{@settings.getWorkspaceDirectory()}/history"

  getHisotryFilePath: ->
    "#{@getHistoryDirectory()}/current.db"

  addEvent: (history_event)->
    console.log 'Historian.addEvent'
    @history_file.add(history_event)

  loadHistoryEvents: ->
    @note_index_storage.getAll()

class HistoryFile
  constructor: (options)->
    unless options.file_path
      throw new Error 'file_path is required'
    @file_path = options.file_path
    @db = new Datastore(filename: @file_path)

  _loadFile: ->
    d = Q.defer()
    @db.loadDatabase (err)=>
      if err
        d.reject(err)
      else
        d.resolve(@db)
    d.promise

  add: (history_event)->
    @_loadFile()
    .then(()=> @_add(history_event))

  _add: (history_event)->
    console.log "HisotyFile.add"
    d = Q.defer()
    json = history_event.toJSON()
    now = new Date()
    json.created_at = now
    json.updated_at = now
    @db.insert json, (err, item)=>
      if err
        d.reject(err)
      else
        d.resolve(item)
    d.promise

  getAll: (options)->
    d = Q.defer()
    @db.find({}).sort({updated_at: -1}).exec (err, items)=>
      if err
        d.reject(err)
      else
        d.resolve(items)
    d.promise
