#
# model: Notepad
#
class NotesScene extends NoteListScene
  id: 'note-list-scene'
  className: 'scene note-list-scene'

  keymapData:
    'J': 'nextNote'
    'K': 'prevNote'
    'N': 'newNote'
    'ENTER': 'editCurrentNote'
    'DELETE': 'deleteCurrentNote'

