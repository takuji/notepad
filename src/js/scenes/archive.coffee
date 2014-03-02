#
# model: Notepad
#
class ArchiveScene extends NoteListScene

  getNoteIndexReader: ->
    @model.getArchivedNoteIndexReader()
