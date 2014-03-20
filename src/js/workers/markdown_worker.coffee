importScripts '../marked.js'

onmessage = (e)->
	html = marked(e.data)
	postMessage html
