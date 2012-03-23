//= require_self

@App =
  init: (ws_url) ->
    @db = new ChuChuGo.Database(ws_url)

    $('#query input[name=selector]').val('x: {$gt: 5}')
    $('#query').submit( (ev) =>
      query = $(ev.currentTarget).find('input[name=selector]').val()
      query = eval( "q={#{query}}" )
      @observer?.cancel()
      @observer = @db.$('things').observe(query)

      @db.modelsById = {}
      $('#results').empty()
      false
    ).submit()

    @db.on 'add',    (model) ->
      $(App.model2html(model)).appendTo('#results').hide().slideDown()
    @db.on 'remove', (model) ->
      $("#results [data-id=#{model.id.toString()}]").slideUp()
    @db.on 'change', (model, attr) ->
      $("#results [data-id=#{model.id.toString()}] [name=#{attr}]")
        .text(model.get(attr).toString())
        .effect('highlight', 'slow')

    $('#new').submit (ev) ->
      el = $(ev.currentTarget).find('input[name=x]')
      if _.isPresent(el.val())
        model = new ChuChuGo.Model( x: parseInt( el.val() ) )
        App.db.$('things').insert model
        el.val('')
      false

    $(document)
      .on 'click', '.model .header a.remove',  (ev) ->
        id = $(ev.currentTarget).closest('[data-id]').attr('data-id')
        App.db.$('things').remove id
        false

  model2html: (objs...) ->
    html = ''
    for obj in objs
      if _.isArray(obj)
        html += obj2html(obj...)
        continue

      html += "<div class='model' data-id='#{obj.id.toString()}'>\n" +
                "<div class='header'>\n" +
                  "<span class='id'>#{obj.id.toString()}</span>\n" +
                  "<a href='#' class='remove'>[remove]</a>\n" +
                "</div>\n" +
                "<table style='margin: 0.5em' class='model_attributes'>\n"
      for key in _.keys(obj.attributes).sort()
        html += "<tr><td>#{key}:</td><td name='#{key}'>#{obj.attributes[key].toString()}</td></tr>\n"
      html + "</table>\n" + "</div>\n"
    html
