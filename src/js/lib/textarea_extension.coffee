$.fn.extend
  viewportOffset: ->
    $window = $(window)
    p = @offset()
    left: p.left - $window.scrollLeft()
    top: p.top - $window.scrollTop()

  getCaretPosition: ->
    el = @[0]
    if el.selectionStart
      el.selectionStart
    else if document.selection
      el.focus()
      r = document.selection.createRange()
      if r == null
        0
      else
        re = el.createTextRange()
        rc = re.duplicate()
        re.moveToBookmark(r.getBookmark())
        rc.setEndPoint('EndToStart', re)
        rc.text.length
    else
      0

  setCaretPosition: (pos)->
    el = @[0]
    if el.setSelectionRange
      el.focus()
      el.setSelectionRange(pos,pos)
    else if el.createTextRange
      range = el.createTextRange()
      range.collapse(true)
      range.moveEnd('character', pos)
      range.moveStart('character', pos);
      range.select()

  textareaCaret: ->
    options = if arguments.length > 0 then arguments[0] else {}
    @textareaHelper()
    if options['cursorMoved']
      cursorMoved = options['cursorMoved']
      if typeof(cursorMoved) == 'function'
        @.on 'keyup', =>
          loc = @getCaretLocation()
          if loc
            @data 'prevLocation', loc
            cursorMoved loc

  getCaretLocation: ->
    pos = @getCaretPosition()
    prevPos = @data('prevLocation')
    if !prevPos? || (prevPos.pos != pos)
      content = @.val()
      pos: pos
      line_no: content.substr(0, pos).split("\n").length
    else
      prevPos

  scrollToCaretPos: ->
    cur_pos = @getCaretPosition()
    @setCaretPosition(0)
    base_pos = @textareaHelper('caretPos')
    @setCaretPosition(cur_pos)
    target_pos = @textareaHelper('caretPos')
    y = target_pos.top - base_pos.top
    console.log y
    @scrollTop(y)