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
    'J': 'nextSection'
  #   'K': 'prevNote'
  #   'N': 'newNote'

  initialize: ->
    settings = @model.settings
    @sections =
      workspace: new WorkspaceSettingsView(model: settings)
      editor: new EditorSettingsView(model: settings)
    @keymap = Keymap.createFromData(@keymapData, @)
    @active = false
    $(window).on 'resize', => @_resize()

  onRender: ->
    sections_view = new SettingsSidebarView()
    @sidebar.show sections_view
    @listenTo sections_view, 'section:selected', @onSectionSelected
    @changeSection 'workspace'
    console.log 'SettingsScene.onRender'

  onSectionSelected: (section_id)->
    @changeSection section_id

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

  nextSection: ->
    console.log 'SettingsScene.nextSection'

#
#
#
class WorkspaceSettingsView extends Marionette.ItemView
  template: '#workspace-settings-template'
  className: 'settings-section'

  events:
    'change #workspace-root_path': 'onRootPathChanged'
    'click #save-button': 'onSaveButtonClicked'

  initialize: ->
    console.log @model.toJSON()
  
  onRender: ->
    console.log 'WorkspaceSettingsView.onRender'

  onShow: ->
    console.log 'WorkspaceSettingsView.onShow'

  onRootPathChanged: (e)->
    console.log 'WorkspaceSettingsView.onRootPathChanged'
    path = e.target.files[0].path
    @model.changeWorkspaceDirectory(path)
    @render()

  onSaveButtonClicked: (e)->
    @model.save()
    location.href = 'index.html'


class SettingsSidebarView extends Marionette.ItemView
  template: '#settings-sections-template'
  tagName: 'ul'
  className: 'settings-section-list'

  events:
    'click li a': 'onItemClicked'

  sections:
    workspace:
      path: '#settings/workspace'
      name: 'Workspace'
    editor:
      path: '#settings/editor'
      name: 'Editor'

  initialize: ->
    @collection = new Backbone.Collection()
    _.each @sections, (attrs, name)=>
      obj = _.extend attrs, {id: name}
      console.log obj
      @collection.add(obj)

  onItemClicked: (e)->
    $a = $(e.target)
    @trigger 'section:selected', $a.attr('data-id')
    console.log 'clicked!'

#
#
#
class EditorSettingsView extends Marionette.ItemView
  template: '#editor-settings-template'
  className: 'settings-section editor-settings'

  events:
    'change input[name="note_map_depth_level"]': 'onNoteMapVisibleDepthChanged'
    'click #save-button': 'onSaveButtonClicked'

  initialize: ->
    console.log @model.toJSON()
  
  onRender: ->
    console.log 'WorkspaceSettingsView.onRender'

  onShow: ->
    @displayCurrentLevel()
    console.log 'WorkspaceSettingsView.onShow'

  displayCurrentLevel: ->
    console.log 'EditorSettingsView.displayCurrentLevel'
    level = @model.getNoteEditSceneSettings().note_map_level
    @$("#note_map_depth_level_#{level}").prop('checked', true)
    console.log 'EditorSettingsView.displayCurrentLevel done'

  onNoteMapVisibleDepthChanged: (e)->
    level = +$(e.target).val()
    @model.changeNoteMapLevel(level)
    @model.save()
    console.log 'WorkspaceSettingsView.onNoteMapVisibleDepthChanged'

  onSaveButtonClicked: (e)->
    @model.save()
    location.href = 'index.html'

  