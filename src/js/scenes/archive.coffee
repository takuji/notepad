#
# model: Notepad
#
class ArchiveScene extends NoteListScene
  className: 'scene note-list-scene archive-scene'

  getNoteIndexReader: ->
    @model.getArchivedNoteIndexReader()
