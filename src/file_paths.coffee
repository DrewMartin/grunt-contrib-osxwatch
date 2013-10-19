{dirname, normalize, basename} = require 'path'
minimatch = require 'minimatch'
_ = require 'lodash'

exports.commonPaths = (paths) ->
  dirs = {}
  for path in paths
    # Cut off the string after ** globs
    # If there's a trailing slash, add a dummy string at the end or the dirname is one higher than it should be.
    # Ex: dirname("/what/the/hell/") resolves to "/what/the" where we'd want "/what/the/hell/"
    pathParts = normalize(dirname(path.replace(/(\*\*.*)$/, '').replace(/\/$/, '/token'))).split /\//
    obj = dirs

    # compose the object with the path such that a path like /a/b/c/ would create an object:
    # {a: {b: {c: true}}}
    # As it's created, it's compared against the current paths. If it's more general than a previous
    # path (such as /a/b/c/d/) then the less-general ones are removed
    for part, i in pathParts
      if obj[part] == true
        break

      if i == pathParts.length - 1
        obj[part] = true
      else
        obj[part] ?= {}
        obj = obj[part]

  # Depth-first traversal of the object to create the unique lists of paths to observe
  paths = []
  traverse = (path, obj) ->
    if obj == true
      paths.push path
      return

    for k, v of obj
      traverse "#{path}#{k}/", v

  traverse "", dirs
  return paths

ACTION_KEY = ":actions:" #colons aren't allowed in file names

# expects tasks to be:
# [{paths: [], actions: []}]
exports.matchingActions = (tasks) ->
  return (files) ->
    actions = []
    for task in tasks
      matches = []
      for p in task.paths
        if p[0] == '!'
          matches = _.difference matches, minimatch.match files, p[1...], {}
        else
          matches = _.union matches, minimatch.match files, p, {}

      if matches.length
        actions.push task.actions

    return actions
