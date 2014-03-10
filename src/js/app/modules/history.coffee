#
#
#
class HistoryEvent extends Backbone.Model


#
#
#
class History extends Backbone.Collection


#
#
#
class NoteHistoryEvent extends HistoryEvent
  defaults: ->
    category: 'note'
    datetime: new Date()

  initialize: ->
    @set code: @code
    console.log "NEW NOTE HISTORY EVENT"
    console.log @attributes

NoteHistoryEvent.newConstructor = (event_class)->
  (note)->
    console.log "NOTE EVENT CONSTRUCTOR"
    console.log note
    new event_class(id: cuid(), note_id: note.id)

#
# NoteCreateEvent
#
class NoteCreateEvent extends NoteHistoryEvent
  code: 'create'
NoteCreateEvent.create = NoteHistoryEvent.newConstructor(NoteCreateEvent)

#
# NoteDeleteEvent
#
class NoteDeleteEvent extends NoteHistoryEvent
  code: 'delete'
NoteDeleteEvent.create = NoteHistoryEvent.newConstructor(NoteDeleteEvent)

#
#
#
class NoteHistory extends Backbone.Collection
  model: NoteHistoryEvent
