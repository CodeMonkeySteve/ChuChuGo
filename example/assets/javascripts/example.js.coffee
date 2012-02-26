//= require chuchugo
//= require_tree .
//= require_self

@App =
  init: (ws_url) ->
    @db = new ChuChuGo.Database(ws_url)

    $('#query input[name=selector]').val('x: {$gt: 5}')
    $('#query').submit( (ev) ->
      query = $(ev.currentTarget).find('input[name=selector]').val()
      query = eval( "q={#{query}}" )
      App.db.$('things').find query, (resp) ->
        $('#results').html( obj2html(resp) )
      false
    ).submit()

@obj2html = (objs...) ->
  html = ''
  for obj in objs
    if _.isArray(obj)
      html += obj2html(obj...)
      continue

    html += '<table style="margin: 0.5em">'
    for key in _.keys(obj).sort()
      html += "<tr><td>#{key}</td><td>#{obj[key].toString()}</td></tr>"
    html + "</table>\n"
  html
