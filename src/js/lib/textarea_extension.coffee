$.fn.extend
  viewportOffset: ->
    $window = $(window)
    p = @offset()
    {left: p.left - $window.scrollLeft(), top: p.top - $window.scrollTop()}

  getCaretPos: ->
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
    pos = @getCaretPos()
    prevPos = @data('prevLocation')
    if !prevPos? || (prevPos.pos != pos)
      content = @.val()
      caretPos = @textareaHelper('caretPos')
      {
        pos: pos
        caretPos: caretPos
        l_line: content.substr(0, pos).split("\n").length
        p_line: (caretPos.top - 10) / 20 + 1
      }
    else
      prevPos
