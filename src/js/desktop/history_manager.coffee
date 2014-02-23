#
#
#
class HistoryManager
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
    console.log 'HistoryManager.addEvent'
    @history_file.add(history_event)

  loadHistoryEvents: ->
    @history_file.getAll()

#
#
#
class HistoryFile
  constructor: (options)->
    unless options.file_path
      throw new Error 'file_path is required'
    @file_path = options.file_path
    @db = new Datastore(filename: @file_path)

  _loadDatabase: ->
    d = Q.defer()
    @db.loadDatabase (err)=>
      if err
        d.reject(err)
      else
        d.resolve(@db)
    d.promise

  add: (history_event)->
    @_loadDatabase()
    .then(()=> @_add(history_event))

  _add: (history_event)->
    console.log "HisotyFile.add"
    d = Q.defer()
    json = history_event.toJSON()
    @db.insert json, (err, item)=>
      if err
        d.reject(err)
      else
        d.resolve(history_event)
    d.promise

  getAll: (options)->
    @_loadDatabase().then(()=> @_getAll(options))

  _getAll: (options)->
    d = Q.defer()
    @db.find({}).sort({datetime: -1}).exec (err, items)=>
      if err
        d.reject(err)
      else
        d.resolve(items)
    d.promise
