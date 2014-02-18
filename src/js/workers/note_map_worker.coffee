importScripts 'underscore.js'

onmessage = (e)->
  markdownString = e.data
  lines = markdownString.split('\n')
  lines_with_index = _.map lines, (line, i)->{title: line, line: i + 1}
  indexes = _.filter lines_with_index, (title_and_index, i)-> title_and_index.title.match("^#+")
  map_items = _.map indexes, (idx)->
    idx.title.match(/^(#+)(.*)$/)
    title = RegExp.$2.trim()
    depth = RegExp.$1.length
    _.extend(idx, {depth: depth, title: title})
  postMessage map_items
