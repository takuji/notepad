class NoteIndexReader
  constructor: (options)->
    @manager = options.note_manager
    @offset = 0
    @count = options.count || 20
    @has_next = true
    @reading = false

  next: ->
    if @has_next
      if @reading
        Q.reject(new Error('Current job is still running'))
      else
        @_loadNext()
    else
      Q.reject(new Error('no more notes'))

  _loadNext: ->
    @reading = true
    @manager.getActiveNoteIndex(offset: @offset, count: @count)
    .then((arr)=>
      @offset += arr.length
      if arr.length < @count
        @has_next = false
      _.map arr, (attrs)=> new NoteIndexItem(attrs))
    .finally(
      ()=>
        @reading = false)

  hasNext: ->
    @has_next