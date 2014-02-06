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
Key.fromEvent = (e)-> new Key(code: e.keyCode, shift: e.shiftKey, ctrl: (e.ctrlKey && !e.metaKey) || (!e.ctrlKey && e.metaKey))
