class NoteHistoryEvent
  constructor: (options)->
    unless options.note? && options.event?
      throw new Error('invalid arguments')
    {@note, @event} = options
    console.log @note
    console.log @event

  toJSON: ->
    {
      category: 'note'
      event: @event
      note_id: @note.id
    }
