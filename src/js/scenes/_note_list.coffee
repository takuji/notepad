#
# model: Notepad
#
class NoteListScene extends BaseScene
  template: '#note-list-scene-template'
  id: 'note-list-scene'
  className: 'scene note-list-scene'

  regions:
    main: '#main'
    note_list_pane: '#note-list-pane'

  keymapData:
    'J': 'nextNote'
    'K': 'prevNote'
    'N': 'newNote'
    'ENTER': 'editCurrentNote'
    'DELETE': 'deleteCurrentNote'

  initialize: ->
    super

  getNoteIndex: ->
    @model.getNoteIndex()

  onRender: ->
    @note_list_view = new NoteListView(collection: @getNoteIndex())
    @note_view      = new EmptyNoteView()
    @note_list_pane.show(@note_list_view)
    @main.show(@note_view)
    # Connect
    @listenTo @note_list_view, 'note:selected', @onNoteSelected
    @listenTo @note_list_view, 'note:delete', @deleteNote
    @note_list_pane.$el.on 'scroll', => @onNoteListPaneScrolled()
    console.log 'NotesScene.onRender'

  onShow: ->
    super
    console.log 'NotesScene.onShow'

  onClose: ->
    super

  _resize: ->
    super
    if @active
      $window = $(window)
      sidebar = @$('#sidebar')
      @main.$el.width($window.width() - sidebar.outerWidth())

  onNoteListPaneScrolled: (e)->
    @note_list_view.fetchEnoughNoteIndexes()

  onMoreNotesRequested: (view, options)->
    @note_index_reader.next()
    .then(
      (note_indexes)=>
        view.addNoteIndexes(note_indexes)
      (error)=>
        console.log error)

  onNoteSelected: (note_index)->
    console.log note_index
    @model.selectNote(note_index.id).then(
      (note)=>
        console.log note
        @main.show(new NoteView(model: note)))

  nextNote: ->
    @note_list_view.selectNextNote()

  prevNote: ->
    @note_list_view.selectPrevNote()

  # Action to create a new note
  # - create a note data
  # - save it
  # - set it to the note edite scene
  # - open the note edit scene
  newNote: ->
    @model.createNote()
    .then((note)=>
      @model.selectNote(note.id))
    .then((note)=>
      console.log note
      location.href = "#notes/#{note.id}/edit")

  # Action to open the note edit scene to start editing the current note
  editCurrentNote: ->
    @note_list_view.editCurrentNote()

  deleteCurrentNote: ->
    console.log 'delete current note'
    note = @model.getCurrentNote()
    if note
      @model.deleteNote(note.id)

  deleteNote: (note_id)->
    console.log "Deleting #{note_id}..."
    @model.deleteNote(note_id)
