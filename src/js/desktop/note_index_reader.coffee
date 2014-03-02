class NoteIndexReader
  constructor: (options)->
    @manager = options.note_manager
    @offset = 0
    @count = options.count || 20
    @has_next = true

  next: ->
    if @has_next
      @manager.getActiveNoteIndex(offset: @offset, count: @count)
      .then((arr)=>
        @offset += arr.length
        if arr.length < @count
          @has_next = false
        _.map arr, (attrs)=> new NoteIndexItem(attrs))
    else
      Q.reject(new Error('no more notes'))
