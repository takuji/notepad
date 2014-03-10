#
# model: Notepad
#
class ArchiveScene extends NoteListScene
  className: 'scene note-list-scene archive-scene'

  getNoteIndex: ->
    @model.getArchivedNoteIndex()

  onNoteSelected: (note_index)->
    # On the archived scene, the current note is not changed.
    @model.getNote(note_index.id).then(
      (note)=>
        console.log note
        @main.show(new NoteView(model: note)))
