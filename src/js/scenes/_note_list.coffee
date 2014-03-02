#
# model: Notepad
#
class NoteListScene extends BaseScene
  template: '#note-list-scene-template'
  id: 'note-list-scene'
  className: 'scene note-list-scene'

  events:
    'click .more': 'onMoreClicked'

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

  getNoteIndexReader: ->
    @model.getNoteIndexReader(count: 50)

  onRender: ->
    @note_index_reader = @getNoteIndexReader()
    @note_list_view = new NoteListView()
    @note_view      = new EmptyNoteView()
    @note_list_pane.show(@note_list_view)
    @main.show(@note_view)
    # Connect
    @listenTo @note_list_view, 'note:selected', @onNoteSelected
    @listenTo @note_list_view, 'note:delete', @deleteNote
    @listenTo @note_list_view, 'more', (options)=> @onMoreNotesRequested(@note_list_view, options)
    @note_list_pane.$el.on 'scroll', => @onNoteListPaneScrolled()
    # # Load note index data
    # @model.getActiveNoteIndex().then(
    #   (note_index)=> console.log "NOTE INDEX UPDATED"
    #   (error)=> console.log "NOTE INDEX NOT LOADED")
    console.log 'NotesScene.onRender'

  onShow: ->
    super
    @fetchEnoughNoteIndexes()
    console.log 'NotesScene.onShow'

  onClose: ->
    super

  _resize: ->
    super
    if @active
      $window = $(window)
      sidebar = @$('#sidebar')
      @main.$el.width($window.width() - sidebar.outerWidth())

  onMoreClicked: (e)->
    @fetchNextNoteIndexes()

  fetchNextNoteIndexes: ->
    @note_index_reader.next()
    .then(
      (note_indexes)=>
        @note_list_view.addNoteIndexes(note_indexes)
        note_indexes
      (error)=>
        console.log error)

  fetchEnoughNoteIndexes: ->
    if @_shouldFetchMoreNoteIndexes()
      @fetchNextNoteIndexes()
      .then(
        ()=>
          setTimeout(
            ()=> @fetchEnoughNoteIndexes()
            0)
        (error)=>
          console.log error)

  _shouldFetchMoreNoteIndexes: ->
    @note_index_reader.hasNext() &&
    @$('.more').viewportOffset().top <= $(window).height()


  onNoteListPaneScrolled: (e)->
    @fetchEnoughNoteIndexes()

  onMoreNotesRequested: (view, options)->
    @note_index_reader.next()
    .then(
      (note_indexes)=>
        view.addNoteIndexes(note_indexes)
      (error)=>
        console.log error)

  onNoteSelected: (note_info)->
    @model.selectNote(note_info.id).then(
      (note)=> @main.show(new NoteView(model: note)))

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
    @model.createNote().then(
      (note)=>
        location.href = "#notes/#{note.id}/edit")

  # Action to open the note edit scene to start editing the current note
  editCurrentNote: ->
    @note_list_view.editCurrentNote()

  deleteCurrentNote: ->
    console.log 'delete current note'
    @model.deleteNote(@current_note.id)

  deleteNote: (note_id)->
    @model.deleteNote(note_id)
