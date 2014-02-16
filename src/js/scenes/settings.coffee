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
      workspace: new WorkspaceSettingsView(model: settings)
    @keymap = Keymap.createFromData(@keymapData, @)
    @active = false
    $(window).on 'resize', => @_resize()

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
    @sidebar.show new SettingsSidebarView()
    @changeSection 'workspace'
    console.log 'SettingsScene.onRender'

  onShow: ->
    @active = true
    @_resize()
    console.log 'SettingsScene.onShow'

  onClose: ->
    @active = false

  changeSection: (section_id)->
    @main.show @sections[section_id]

  _resize: ->
    if @active
      $window = $(window)
      @$el.height($window.height() - @$el.offset().top)
      @main.$el.width($window.width() - @sidebar.$el.width())

class WorkspaceSettingsView extends Marionette.ItemView
  template: '#workspace-settings-template'
  className: 'settings-section'

  initialize: ->
    console.log @model.toJSON()
  
  onRender: ->
    console.log 'WorkspaceSettingsView.onRender'

  onShow: ->
    console.log 'WorkspaceSettingsView.onShow'

class SettingsSidebarView extends Marionette.ItemView
  template: '#plain-template'
