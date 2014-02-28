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
    @keymap = Keymap.createFromData(@keymapData, @)
    @active = false
    $(window).on 'resize', => @_resize()

  onRender: ->
    @sidebar.show new SettingsSidebarView(collection: [])
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

  nextSection: ->
    console.log 'SettingsScene.nextSection'

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
    'click li': 'onItemClicked'

  sections:
    workspace:
      path: '#settings/workspace'
      name: 'Workspace'

  initialize: ->
    @collection = new Backbone.Collection()
    _.each @sections, (attrs, name)=>
      @collection.add(attrs)

  onItemClicked: (e)->
    console.log 'clicked!'
