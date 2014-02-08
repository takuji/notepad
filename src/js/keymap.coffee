class Keymap
  key: {true: {true: {}, false: {}}, false: {true: {}, false: {}}}

  get: (key)->
    @key[key.ctrl][key.shift][key.code]

  set: (key, action)->
    @key[key.ctrl][key.shift][key.code] = action

class KeyAction
  constructor: (action, context)->
    @action = action
    @context = context

  fire: ->
    @action.call @context

class Key
  constructor: (params)->
    {@code, @shift, @ctrl} = params
    @key = @codeToString(@code)

  codeToString: (code)->
    if code >= 48 && code <= 122
      String.fromCharCode(code)
    else
      switch code
        when  9 then 'TAB'
        when 13 then 'ENTER'
        when 46 then 'DELETE'

Key.fromChar = (c)-> new Key(code: c.charCodeAt(0), shift: false, ctrl: false)

Key.stringToCode = (s)->
  if s.length == 1
    s.charCodeAt(0)
  else
    switch s
      when 'ENTER' then 13
      when 'DELETE' then 46
      when 'TAB' then 9

Key.fromCodeString = (code_string)->
  elms = code_string.split('-')
  switch elms.length
    when 1
      new Key(code: Key.stringToCode(elms[0]), shift: false, ctrl: false)
    when 2
      [ctrl, shift] = [elms[0] == 'CTRL', elms[0] == 'SHIFT']
      new Key(code: Key.stringToCode(elms[1]), shift: shift, ctrl: ctrl)
    when 3
      [ctrl, shift] = [elms[0] == 'CTRL', elms[1] == 'SHIFT']
      new Key(code: Key.stringToCode(elms[2]), shift: shift, ctrl: ctrl)
    else
      throw new Error("invalid key code #{code_string}")

Key.fromEvent = (e)-> new Key(code: e.keyCode, shift: e.shiftKey, ctrl: (e.ctrlKey && !e.metaKey) || (!e.ctrlKey && e.metaKey))
