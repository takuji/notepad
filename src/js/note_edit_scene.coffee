#
#
#
class NoteEditScene extends Marionette.Layout
  template: '#note-edit-template'
  id: 'note-edit'
  className: 'note-edit scene'

  regions:
    sidebar: '#sidebar'
    main: '#main'

  keymapData:
    'CTRL-S': 'saveCurrentNote'
    'CTRL-L': 'saveAndQuit'

  initialize: ->
    @current_note = null
    @keymap = Keymap.createFromData(@keymapData, @)

  onRender: ->
    if @current_note
      note_map = @current_note.getMap()
      @sidebar.show(new NoteMapView(model: note_map, collection: note_map.getItems()))
      @main.show(new NoteEditMain(model: @current_note))
    $(window).on 'resize', => @_resize()
    console.log "NoteEditScene.onRender"

  onShow: ->
    @_resize()
    @main.currentView.focus()
    console.log "NoteEditScene.onShow"

  _resize: ->
    $window = $(window)
    @$el.height($window.height() - @$el.offset().top)
    @main.$el.width($window.width() - @sidebar.$el.width())
    @main.currentView.resize()
    #@main.currentView.$el.width($window.width() - @sidebar.currentView.$el.width())

  # 
  changeNoteAsync: (note_id)->
    @model.getNoteAsync(note_id).then(
      (note)=>
        @current_note = note)

  saveCurrentNote: ->
    if @current_note
      console.log 'Saving...'
      @model.saveNote(@current_note)

  saveAndQuit: ->
    @model.saveNote(@current_note).then(
      ()=>
        location.href = '#notes')

#
#
#
class NoteEditMain extends Marionette.Layout
  template: '#note-main-views-template'
  regions:
    editor: '#editor'
    preview: '#preview'

  onRender: ->
    @editor.show(new NoteEditorView(model: @model))
    @preview.show(new NotePreviewView(model: @model))
    console.log "NoteEditorView#onRender #{@$el.width()}"

  onShow: ->
    console.log "NoteEditMain.onShow"

  resize: ->
    @editor.$el.width(@$el.width() - @preview.$el.width())

  focus: ->
    @editor.currentView.focus()

#
# model: NoteMapItem
#
class NoteMapItemView extends Marionette.ItemView
  template: '#note-index-item-template'
  tagName: 'li'
  className: 'indexItem'
  events:
    'click': 'onClicked'

  onRender: ->
    @$el.attr('data-line': @model.get('line'), 'data-depth': @model.get('depth'))

  onClicked: ->
    @trigger 'clicked', @model

#
# model: NoteMap
#
class NoteMapView extends Marionette.CompositeView
  itemView: NoteMapItemView
  itemViewContainer: 'ul'
  template: '#note-index-template'
  className: 'note-index'

  initialize: ->

  onRender: ->
    console.log "NoteMapView#onRender #{@$el.width()}"

  onShow: ->


#
#
#
class NoteEditorView extends Marionette.ItemView
  template: '#note-editor-template'
  className: 'editor'

  events:
    'keyup textarea': 'onKeyUp'
    'keydown textarea': 'onKeyDown'

  keymapData:
    'TAB': 'forwardHeadingLevel'
    'SHIFT-TAB': 'backwardHeadingLevel'

  initialize: ->
    @keymap = Keymap.createFromData(@keymapData, @)

  onRender: ->
    @$textarea = @$('textarea')
    @$textarea.val(@model.get('content'))

  onShow: ->
    console.log 'NoteDeitorView.onShow'

  onKeyUp: ->
    @model.set('content': @$textarea.val())

  onKeyDown: (e)->
    key = Key.fromEvent(e)
    action = @keymap.get(key)
    if action
      e.preventDefault()
      action.fire()

  focus: ->
    @$('textarea').focus()

  forwardHeadingLevel: ->

  backwardHeadingLevel: ->

#
#
#
class NotePreviewView extends Marionette.ItemView
  template: '#note-preview-template'
  className: 'preview'

  initialize: ->
    @listenTo @model, 'change:content', @onNoteUpdated
    @updateHtml()

  onNoteUpdated: ->
    @updateHtml()
    @render()

  updateHtml: ->
    @html = marked(@model.get('content') || '')

  serializeData: ->
    {html: @html}

  onShow: ->
    console.log 'NotePreviewView.onShow'
