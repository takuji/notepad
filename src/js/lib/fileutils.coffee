FileUtils =
  slurp: (path)->
    d = Q.defer()
    fs.readFile path, {encoding: 'utf8'}, (err, data)=>
      if err
        d.reject(err)
      else
        d.resolve(data)
    d.promise

  spit: (path, data)->
    d = Q.defer()
    fs.writeFile path, data, (err)=>
      if err
        d.reject(err)
      else
        d.resolve(@)
    d.promise

  createDirectory: (path)->
    d = Q.defer()
    mkdirp path, (error)=>
      if error
        d.reject(error)
      else
        d.resolve()
    d.promise
