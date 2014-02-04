class NoteEditScene extends Marionette.Layout
  template: '#note-edit-template'
  id: 'note-edit'
  className: 'note-edit scene'

  regions:
    sidebar: '#sidebar'
    main: '#main'

  initialize: ->
    @current_note = null

  onRender: ->
    console.log "scene: #{@$el.width()}"
    if @current_note
      @sidebar.show(new NoteIndexView(model: @current_note))
      console.log @sidebar.$el.width()
      @main.show(new NoteEditMain(model: @current_note))
      console.log @main.$el.width()
    $(window).on 'resize', => @_resize()

  onShow: ->
    console.log 'onShow!'
    @_resize()

  _resize: ->
    $window = $(window)
    @$el.height($window.height() - @$el.offset().top)
    @main.$el.width($window.width() - @sidebar.$el.width())
    #@main.currentView.$el.width($window.width() - @sidebar.currentView.$el.width())

  changeNote: (note_id)->
    @current_note = @model.getNote(note_id)
    console.log "current note is #{@current_note}"


class NoteEditMain extends Marionette.Layout
  template: '#note-main-views-template'
  regions:
    editor: '#editor'
    preview: '#preview'

  onRender: ->
    console.log "NoteEditorView#onRender #{@$el.width()}"
    @editor.show(new NoteEditorView(model: @model))
    @preview.show(new NotePreviewView(model: @model))
    @_resize()

  _resize: ->
    console.log @$el.width()
    console.log @preview.$el.width()
    #@editor.$el.width(@$el.width() - @preview.$el.width())


class NoteIndexView extends Marionette.ItemView
  template: '#note-index-template'

  onRender: ->
    console.log "NoteIndexView#onRender #{@$el.width()}"


class NoteEditorView extends Marionette.ItemView
  template: '#note-editor-template'
  className: 'editor'

  onRender: ->
    @$('textarea').val(@model.get('content'))


class NotePreviewView extends Marionette.ItemView
  template: '#note-preview-template'
  className: 'preview'
