#
#
#
class NoteIndex extends Backbone.Collection
  initialize: ->
    @up_to_date = false
    @listenTo @, 'reset', => @up_to_date = true

  updateIndex: (note)->
    item = @get(note.id)
    item.reset(note)
    @remove item
    @unshift item

  onNoteUpdated: (note)->
    @updateIndex(note)
    console.log "NoteIndex.onNoteUpdated #{note.id}"

  onNoteAdded: (note)->
    @unshift NoteIndexItem.fromNote(note)
    console.log "NoteIndex.onNoteAdded #{note.id}"
    note

  isUpToDate: ->
    @up_to_date

#
#
#
class NoteIndexItem extends Backbone.Model
  reset: (note)->
    if @id == note.id
      @set(
        title: note.get('title')
        updated_at: note.get('updated_at'))
    console.log "Note index of #{note.id} updated"
    console.log @attributes

  delete: ->
    @set deleted: true

  isActive: ->
    @get('deleted') != true

NoteIndexItem.fromNote = (note)->
  new NoteIndexItem(
    id: note.id
    title: note.get('title')
    created_at: note.get('created_at')
    updated_at: note.get('updated_at'))


#
#
#
class Note extends Backbone.Model
  initialize: ->
    @_changed = false
    @_updateTitle()
    @_compile()

  onSaved: ->
    @_changed = false

  isModified: ->
    @_changed

  updateContent: (content)->
    if content != @get('content')
      @_changed = true
      @set content: content, title: @_titleOfContent(content)
      # @_compile()

  _updateTitle: ->
    @set title: @_titleOfContent(@get('content'))

  _compile: ->
    if @get('content')
      @set html: marked(@get('content'))

  _titleOfContent: (content)->
    if _.isEmpty(content)
      'Untitled'
    else
      content.split('\n')[0]

  getMap: ->
    new NoteMap().attachNote(@)

  getInfo: ->
    {id: @id, title: @get('title'), created_at: @get('created_at'), updated_at: @get('updated_at')}

  isHighlighted: ->
    @get('highlighted') == true

#
#
#
class NoteMap extends Backbone.Collection

#
#
#
class NoteMapItem extends Backbone.Model
  initialize: (attrs)->
    unless attrs.line || attrs.title || attrs.depth
      throw new Error("Required parameter is missing")

  # note map items are the same if their title and depth are equal respectively.
  isSame: (other)->
    @get('title') == other.get('title') && @get('depth') == other.get('depth')

  adjustLine: (other)->
    if @isSame(other)
      if @get('line') != other.get('line')
        @set 'line', other.get('line') if @get('line') != other.get('line')


#
#
#
class NoteCollection extends Backbone.Collection
  initialize: ->
    console.log @
    console.log @length
    @listenTo @, 'add', @onNoteAdded
    console.log "@id_seed is #{@id_seed}"

  # Creates a new note instance and add it to the head of this collection
  # Returns the new note.
  newNote: (params)->
    note = new Note(id: @_nextNoteId(), title: 'Untitled', content: '')
    @unshift(note)
    note

  _nextNoteId: ->
    cuid()

  onNoteAdded: (note)->
    console.log "Note #{note.id} added"
