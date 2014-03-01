#
# model: Notepad
#
class ArchiveScene extends BaseScene
  template: '#archive-scene-template'
  id: 'archive-scene'
  className: 'archive-scene scene'

  regions:
    sidebar: '#sidebar'
    main: '#main'

  initialize: ->
    super
    @keymap = Keymap.createFromData(@keymapData, @)
    $(window).on 'resize', => @_resize()
    console.log "NotesScene created at #{new Date()}"

  onRender: ->
    super
    note_list_view = new NoteListView(collection: @model.getArchivedNoteIndex())
    @main.show(note_list_view)

  onShow: ->
    super

  onClose: ->
    super

  _resize: ->
    super
