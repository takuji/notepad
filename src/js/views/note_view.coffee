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

  onLinkClicked: (e)->
    e.preventDefault()
    Shell.openExternal $(e.target).attr('href')

  onRender: ->
    unless @highlighted
      @_highlightCodesAsync()

  _highlightCodesAsync: ->
    setTimeout(
      ()=>
        @_highlightCodes()
      0)

  _highlightCodes: ->
    @$('pre > code').each (i, e)=>
      hljs.highlightBlock(e)
      @highlighted = @$el.html()

#
#
#
class EmptyNoteView extends Marionette.ItemView
  className: 'note-view'
  template: '#note-empty-template'
