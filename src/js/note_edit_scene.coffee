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
    @active = false

  onRender: ->
    if @current_note
      note_map = @current_note.getMap()
      note_map_view = new NoteMapView(model: note_map, collection: note_map.getItems())
      main_view = new NoteEditMain(model: @current_note)
      @sidebar.show(note_map_view)
      @main.show(main_view)
      @listenTo note_map_view, 'clicked', @onNoteMapClicked
    $(window).on 'resize', => @_resize()
    console.log "NoteEditScene.onRender"

  onShow: ->
    @active = true
    @_resize()
    @main.currentView.focus()
    console.log "NoteEditScene.onShow"

  onClose: ->
    @active = false


  onNoteMapClicked: (note_map)->
    console.log note_map
    @goToLine(note_map.get('line'))
    console.log 'NoteEditScene.onNoteMapClicked'

  _resize: ->
    if @active
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

  goToLine: (line_no)->
    @main.currentView.goToLine(line_no)

#
#
#
class NoteEditMain extends Marionette.Layout
  template: '#note-main-views-template'
  regions:
    editor: '#editor'
    preview: '#preview'

  onRender: ->
    editor  = new NoteEditorView(model: @model)
    preview = new NotePreviewView(model: @model)
    @editor.show(editor)
    @preview.show(preview)
    console.log "NoteEditorView#onRender #{@$el.width()}"

  onShow: ->
    console.log "NoteEditMain.onShow"

  resize: ->
    @editor.$el.width(@$el.width() - @preview.$el.width())

  focus: ->
    @editor.currentView.focus()

  goToLine: (line_no)->
    @editor.currentView.goToLine(line_no)

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
    @on 'itemview:clicked', @onItemClicked

  onRender: ->
    console.log "NoteMapView#onRender #{@$el.width()}"

  onShow: ->

  onItemClicked: (item_view)->
    @trigger 'clicked', item_view.model


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
    console.log 'NoteEditorView.onRender'

  onShow: ->
    console.log 'NoteDeitorView.onShow'

  onKeyUp: ->
    @model.updateContent(@$textarea.val())

  onKeyDown: (e)->
    key = Key.fromEvent(e)
    action = @keymap.get(key)
    if action
      e.preventDefault()
      action.fire()

  focus: ->
    @$('textarea').focus()

  goToLine: (line_no)->
    @moveCaretToLine(line_no)
    @scrollTo(line_no)
    console.log "NoteEditorView.goToLine #{line_no}"

  moveCaretToLine: (line_no)->
    pos = @_rangeOfLine(line_no, @$textarea.val())
    @$textarea.setCaretPosition(pos.start)

  _rangeOfLine: (line_no, text)->
    pos = 0
    _.times line_no - 1, ->
      newLinePos = text.indexOf("\n", pos)
      pos = newLinePos + 1
    newLinePos = text.indexOf("\n", pos)
    {start: pos, end: newLinePos}

  scrollTo: (line_no)->
    y0 = @$textarea.offset().top
    content_height = @$textarea.textareaHelper('height')
    line_count = @lineCount()
    y  = content_height * (line_no - 1) / line_count
    console.log "line_no=#{line_no}, y0=#{y0}, h=#{content_height}, lines=#{line_count}, y=#{y}"
    @$textarea.scrollTop(Math.floor(y))

  lineCount: ->
    @$textarea.val().split("\n").length

  forwardHeadingLevel: ->
    caret_loc = @$textarea.getCaretLocation()
    line_no = caret_loc.line_no
    caret_pos = caret_loc.pos
    @_nextHeadingLevel line_no,
      nextLevel: (level)=> (level + 1) % 7
      nextCaretPos: (nextLevel, level) => if nextLevel > level then caret_pos + 1 else caret_pos - 6

  backwardHeadingLevel: ->
    caret_loc = @$textarea.getCaretLocation()
    line_no = caret_loc.line_no
    caret_pos = caret_loc.pos
    @_nextHeadingLevel line_no,
      nextLevel: (level)=> (level + 6) % 7
      nextCaretPos: (nextLevel, level)=> if nextLevel > level then caret_pos + 6 else caret_pos - 1

  _nextHeadingLevel: (line_no, funcs)->
    line = @getLine(line_no)
    console.log line
    level = @_headingLevelOfString(line)
    console.log "heading level = #{level}"
    nextLevel = funcs.nextLevel(level)
    h = @_makeHeading(nextLevel)
    heading = @_extractHeading(line)
    new_line = h + heading
    text = @$textarea.val()
    @$textarea.val @_replaceLine(text, line_no, new_line)
    new_caret_pos = funcs.nextCaretPos(nextLevel, level)
    @$textarea.setCaretPosition(new_caret_pos)

  getLine: (line_no)->
    @$textarea.val().split("\n")[line_no - 1]

  _headingLevelOfString: (line) ->
    level = 0
    while line[level] == '#'
      level += 1
    if level <= 6 then level else 0

  _makeHeading: (level)->
    h = ''
    _.times(level, -> h += '#')
    h

  _extractHeading: (line)->
    line.replace /^#+/, ''

  _replaceLine: (text, line_no, new_text)->
    range = @_rangeOfLine(line_no, text)
    t1 = text.substring(0, range.start)
    t2 = if range.end >= 0 then text.substring(range.end) else ''
    t1 + new_text + t2

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
