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
    @keymap = Keymap.createFromData(@keymapData, @)
    @active = false
    @settings = @model.settings.getSceneSettings('note_edit')

  onShowing: (options)->
    console.log 'NoteEditScene.onShowing'

  onRender: ->
    note = @model.getCurrentNote()
    @_setupSubViews(note)
    $(window).on 'resize', => @_resize()
    console.log "NoteEditScene.onRender"

  _setupSubViews: (note)->
    note_map_view = new NoteMapView(
      model: note
      collection: new NoteMap()
      note_map_level: @settings.note_map_level)
    main_view = new NoteEditMain(model: note)
    @sidebar.show(note_map_view)
    @main.show(main_view)
    @listenTo note_map_view, 'clicked', @onNoteMapClicked

  onShow: ->
    @active = true
    @_resize()
    @main.currentView.focus()
    console.log "NoteEditScene.onShow"

  onClose: ->
    @active = false

  onNoteMapClicked: (note_map)->
    @goToLine(note_map.get('line'))
    console.log 'NoteEditScene.onNoteMapClicked'

  _resize: ->
    if @active
      $window = $(window)
      @$el.height($window.height() - @$el.offset().top)
      @main.$el.width($window.width() - @sidebar.$el.width())
      @main.currentView.resize()
      #@main.currentView.$el.width($window.width() - @sidebar.currentView.$el.width())

  saveCurrentNote: ->
    console.log 'Saving...'
    note = @model.getCurrentNote()
    @model.saveNote(note)

  saveAndQuit: ->
    note = @model.getCurrentNote()
    @model.saveNote(note).then(
      ()=>
        location.href = '#notes')

  goToLine: (line_no)->
    @main.currentView.goToLine(line_no)

#
# model: Note
#
class NoteEditMain extends Marionette.Layout
  template: '#note-main-views-template'
  regions:
    editor: '#editor'
    preview: '#preview'

  onRender: ->
    editor  = new CMNoteEditorView(model: @model)
    preview = new NotePreviewView(model: @model)
    @editor.show(editor)
    @preview.show(preview)
    @listenTo editor, 'scrolled', @onEditorScrolled
    console.log "NoteEditMain.onRender #{@$el.width()}"

  onShow: ->
    console.log "NoteEditMain.onShow"

  onEditorScrolled: (percent)->
    h1 = @preview.$el.height()
    h2 = @preview.currentView.$el.outerHeight()
    if h2 > h1
      d = percent * (h2 - h1)
      @preview.$el.scrollTop(d)

  resize: ->
    @editor.$el.width(@$el.width() - @preview.$el.width())
    @editor.currentView.resize()

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

  hide: ->
    @$el.hide()

  getLevel: ->
    @model.get('depth')

#
# model: NoteMap
#
class NoteMapView extends Marionette.CompositeView
  itemView: NoteMapItemView
  itemViewContainer: 'ul'
  template: '#note-index-template'
  className: 'note-index'

  initialize: (options)->
    @collection = new NoteMap()
    @note_map_level = options.note_map_level || 6
    @note_map_worker = new Worker('js/workers/note_map_worker.js')
    @note_map_worker.onmessage = (e)=> @onContentParsed(e.data)
    @listenTo @model, 'change:content', @onContentChanged
    @on 'itemview:clicked', @onItemClicked
    console.log @collection
    console.log "INDENT LEVEL #{@note_map_level}"

  onRender: ->
    console.log "NoteMapView#onRender #{@$el.width()}"

  onShow: ->
    @_updateNoteMap()
    console.log 'NoteMapView.onShow'

  _updateNoteMap: ->
    @note_map_worker.postMessage(@model.get('content'))

  onContentChanged: (note)->
    @_updateNoteMap()

  onContentParsed: (data)->
    note_map_items = _.map data, (attrs)=> new NoteMapItem(attrs)
    if @collection.length == note_map_items.length
      for new_item, i in note_map_items
        cur_item = @collection.at(i)
        if cur_item.isSame(new_item)
          cur_item.adjustLine(new_item)
        else
          @collection.reset(note_map_items)
          break
    else
      @collection.reset(note_map_items)

  onItemClicked: (item_view)->
    @trigger 'clicked', item_view.model

  onBeforeItemAdded: (view)->
    if view.getLevel() > @note_map_level
      view.hide()
#
# Editor based on CodeMirror
#
class CMNoteEditorView extends Marionette.ItemView
  template: '#note-editor-template'
  className: 'editor'

  events:
    'keydown .CodeMirror': 'onKeyDown'

  keymapData: {}

  cm_keymap:
    'Tab': (cm)-> @forwardHeadingLevel()
    'Shift-Tab': (cm)-> @backwardHeadingLevel()

  initialize: ->
    @keymap = Keymap.createFromData(@keymapData, @)

  _makeKeymap: ->
    'Tab': (cm)=> @forwardHeadingLevel()
    'Shift-Tab': (cm)=> @backwardHeadingLevel()

  onRender: ->
    $textarea = @$('textarea')
    $textarea.val(@model.get('content'))
    $textarea.scroll((e)=> @onScrolled(e))
    @code_mirror = CodeMirror.fromTextArea($textarea[0],
      lineWrapping: true
      theme: 'twilight'
      extraKeys: @_makeKeymap()
    )
    @_setupEventHandlers(@code_mirror, @model)
    console.log 'NoteEditorView.onRender'

  _setupEventHandlers: (cm, note)->
    cm.on 'change', (code_mirror, changeObj)=>
      note.updateContent code_mirror.getValue()
    cm.on 'viewportChange', (cm, from, to)=>
      console.log "viewportChange: #{from} - #{to}"
    cm.on 'scroll', (cm)=>
      @syncScroll()
      console.log "scrolled"

  onShow: ->
    @code_mirror.refresh()
    console.log 'NoteDeitorView.onShow'

  syncScroll: ->
    info = @code_mirror.getScrollInfo()
    console.log info
    h1 = info.clientHeight
    h2 = info.height
    if h2 > h1
      percent = info.top / (h2 - h1)
      @trigger 'scrolled', percent

  resize: ->
    @code_mirror.refresh()
    console.log 'NoteEditorView.refresh'

  redraw: ->
    @code_mirror.refresh()

  onKeyDown: (e)->
    key = Key.fromEvent(e)
    action = @keymap.get(key)
    if action
      e.preventDefault()
      action.fire()

  focus: ->
    @code_mirror.focus()

  goToLine: (line_no)->
    @code_mirror.scrollIntoView line: line_no, ch: 0
    @code_mirror.setCursor line: line_no, ch: 0
    @code_mirror.focus()
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
    start: pos
    end: newLinePos

  lineCount: ->
    @$textarea.val().split("\n").length

  forwardHeadingLevel: ->
    cursor_loc = @code_mirror.getCursor()
    line_no = cursor_loc.line
    ch = cursor_loc.ch
    @_nextHeadingLevel line_no,
      nextLevel: (level)=> (level + 1) % 7
      nextCaretPos: (nextLevel, level) => if nextLevel > level then ch + 1 else ch - 6

  backwardHeadingLevel: ->
    cursor_loc = @code_mirror.getCursor()
    line_no = cursor_loc.line
    ch = cursor_loc.ch
    @_nextHeadingLevel line_no,
      nextLevel: (level)=> (level + 6) % 7
      nextCaretPos: (nextLevel, level)=> if nextLevel > level then ch + 6 else ch - 1

  _nextHeadingLevel: (line_no, funcs)->
    line = @code_mirror.getLine(line_no)
    console.log line
    level = @_headingLevelOfString(line)
    console.log "heading level = #{level}"
    nextLevel = funcs.nextLevel(level)
    h = @_makeHeading(nextLevel)
    heading = @_extractHeading(line)
    new_line = h + heading
    @code_mirror.replaceRange(new_line, {line: line_no, ch: 0}, {line: line_no, ch: line.length})
    ch = funcs.nextCaretPos(nextLevel, level)

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
class NoteEditorView extends Marionette.ItemView
  template: '#note-editor-template'
  className: 'editor'

  events:
    'keyup textarea': 'onKeyUp'
    'keydown textarea': 'onKeyDown'
    'scroll textarea': 'onScrolled'

  keymapData:
    'TAB': 'forwardHeadingLevel'
    'SHIFT-TAB': 'backwardHeadingLevel'

  initialize: ->
    @keymap = Keymap.createFromData(@keymapData, @)

  onRender: ->
    @$textarea = @$('textarea')
    @$textarea.val(@model.get('content'))
    @$textarea.scroll((e)=> @onScrolled(e))
    console.log 'NoteEditorView.onRender'

  onShow: ->
    console.log 'NoteDeitorView.onShow'

  onKeyUp: ->
    if @_contentChanged()
      @updateModel()

  _contentChanged: ->
     @model.get('content').length != @$textarea.val().length ||
     @model.get('content') != @$textarea.val()

  onKeyDown: (e)->
    key = Key.fromEvent(e)
    action = @keymap.get(key)
    if action
      e.preventDefault()
      action.fire()

  onScrolled: (e)->
    h1 = @$textarea.outerHeight()
    h2 = @$textarea.prop('scrollHeight')
    if h2 > h1
      percent = @$textarea.scrollTop() / (h2 - h1)
      @trigger 'scrolled', percent

  updateModel: ->
    content = @$textarea.val()
    @model.updateContent(content)

  resize: ->

  focus: ->
    @$('textarea').focus()

  goToLine: (line_no)->
    @moveCaretToLine(line_no)
    @$textarea.scrollToCaretPos()
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
    start: pos
    end: newLinePos

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
  className: 'preview note-view'

  events:
    'click a': 'onLinkClicked'

  initialize: ->
    html_converter = new HtmlConverter(model: @model)
    @listenTo html_converter, 'done', @onHtmlArrived

  onHtmlArrived: (html)->
    @model.updateHtml(html)
    @render()

  onLinkClicked: (e)->
    e.preventDefault()
    Shell.openExternal $(e.target).attr('href')

  serializeData: ->
    html: @model.get('html')

  onShow: ->
    console.log 'NotePreviewView.onShow'

#
#
#
class HtmlConverter
  _.extend @::, Backbone.Events

  constructor: (options)->
    @jobs = []
    model = options.model
    markdown_worker = new Worker('js/workers/markdown_worker.js')
    markdown_worker.onmessage = (e)=> @onPlainHtmlCreated(e.data)
    @listenTo model, 'change:content', ()=>
      markdown_worker.postMessage(model.get('content'))

  onPlainHtmlCreated: (html)->
    @_clearJobs()
    @_highlight(html)

  _highlight: (html)->
    job = new CodeHighlightJob(html)
    @jobs.push job
    job.run().then(
      (highlighted)=>
        @trigger 'done', highlighted
      (error)=>
        unless job.isCancelled()
          console.error error)

  _clearJobs: ->
    _.each @jobs, (job)=> job.cancel()
    @jobs = []

#
#
#
class CodeHighlightJob
  constructor: (html)->
    @$elem = $(html)
    @cancelled = false

  run: ->
    if @cancelled
      Q.reject(new Error('Already cancelled'))
    else
      $root = $('<div>').append(@$elem)
      jobs = $root.find('pre > code').map((i, e)=> @_highlight(e))
      Q.all(jobs).then(
        ()=> $root.html())

  _highlight: (code)->
    if @cancelled
      Q.reject(new Error('Already cancelled'))
    else
      @_highlightAsync(code)

  _highlightAsync: (code)->
    d = Q.defer()
    setTimeout(
      ()=>
        try
          if @cancelled
            d.reject(new Error('cancelled'))
          else
            $code = $(code)
            highlighted = hljs.highlightAuto($code.text()).value
            $code.html(highlighted)
            d.resolve(highlighted)
        catch e
          d.reject(e)
      0)
    d.promise

  cancel: ->
    @cancelled = true

  isCancelled: ->
    @cancelled

#
#
#
class CodeHighlighter
  constructor: (elem)->
    @$elem = $(elem)
    @cancelled = false

  run: ->
    if @cancelled
      Q.reject(new Error('Already cancelled'))
    else
      jobs = @$elem.find('pre > code').map((i, code)=> @_highlight(code))
      Q.all(jobs)

  _highlight: (code)->
    if @cancelled
      Q.reject(new Error('Already cancelled'))
    else
      @_highlightAsync(code)

  _highlightAsync: (code)->
    d = Q.defer()
    setTimeout(
      ()=>
        try
          if @cancelled
            d.reject(new Error('cancelled'))
          else
            hljs.highlightBlock(code)
            d.resolve()
        catch e
          d.reject(e)
      0)
    d.promise

  cancel: ->
    @cancelled = true

  isCancelled: ->
    @cancelled
