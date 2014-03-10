#
# model requires 'html' attribute which contains HTML string.
#
class NoteView extends Marionette.ItemView
  className: 'note-view'
  template: '#note-template'

  events:
    'click a': 'onLinkClicked'

  initialize: ->
    @highlighted = null
    @active = false

  onLinkClicked: (e)->
    e.preventDefault()
    Shell.openExternal $(e.target).attr('href')

  onRender: ->
    # unless @highlighted
    #   @_highlightCodesAsync()

  onShow: ->
    @active = true

  onClose: ->
    @active = false

  _highlightCodesAsync: ->
    setTimeout(
      ()=>
        @_highlightCodes()
      0)

  _highlightCodes: ->
    @$('pre > code').each (i, e)=>
      if @active
        hljs.highlightBlock(e)
    @highlighted = @$el.html()

#
#
#
class EmptyNoteView extends Marionette.ItemView
  className: 'note-view'
  template: '#note-empty-template'
