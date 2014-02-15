#
# model: Notepad
#
class SettingsScene extends Marionette.Layout
  template: '#settings-template'
  id: 'settings'
  className: 'settings scene'

  regions:
    sidebar: '#sidebar'
    main: '#main'

  keymapData:
    'J': 'nextNote'
  #   'K': 'prevNote'
  #   'N': 'newNote'

  initialize: ->
    settings = @model.settings
    @sections =
      workspace: new WorkspaceSettingsView(settings)
    @keymap = Keymap.createFromData(@keymapData, @)
    #$(window).on 'resize', => @_resize()

  onRender: ->
    # note_list_view = new NoteListView(collection: @model.note_index)
    # note_view      = new NoteView(model: @current_note)
    # @note_list_region.show(note_list_view)
    # @note_region.show(note_view)
    # @listenTo note_list_view, 'note:selected', @onNoteSelected
    # @listenTo note_list_view, 'note:delete', @deleteNote
    # # Load note index data
    # @model.getNoteIndex().then(
    #   (note_index)=> console.log "NOTE INDEX UPDATED"
    #   (error)=> console.log "NOTE INDEX NOT LOADED")
    console.log 'SettingsScene.onRender'

  onShow: ->
    @changeSection 'workspace'
    console.log 'SettingsScene.onShow'

  changeSection: (section_id)->
    @main.show @sections[section_id]

  _resize: ->
  #   $window = $(window)
  #   margin = @$el.offset().top
  #   @$el.height($window.height() - margin)

class WorkspaceSettingsView extends Marionette.ItemView
  template: '#workspace-settings-template'
  
  onRender: ->
    console.log 'WorkspaceSettingsView.onRender'

  onShow: ->
    console.log 'WorkspaceSettingsView.onShow'
