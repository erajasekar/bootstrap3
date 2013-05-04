doctype 5
html ->
  head ->
    title @getPreparedTitle()
    meta charset: "utf-8"
    meta "http-equiv": "content-type", "content": "text/html; charset=utf-8"
    meta "http-equiv": "X-UA-Compatible", "content": "IE=edge,chrome=1"
    meta "name": "description", "content": @getPreparedDescription()
    meta "name": "keywords", "content": @getPreparedKeywords()
    meta "name": "author", "content": @site.author or 'Tadeusz Łazurski'
    text @getBlock('meta').toHTML()
    meta "name": "viewport", "content": "width=device-width, initial-scale=1.0"

    link rel: "shortcut icon",                href: "/ico/favicon.png"
    link rel: "apple-touch-icon-precomposed", href: "/ico/apple-touch-icon-144-precomposed.png", sizes: "144x144"
    link rel: "apple-touch-icon-precomposed", href: "/ico/apple-touch-icon-114-precomposed.png", sizes: "114x114"
    link rel: "apple-touch-icon-precomposed", href: "/ico/apple-touch-icon-72-precomposed.png",  sizes: "72x72"
    link rel: "apple-touch-icon-precomposed", href: "/ico/apple-touch-icon-57-precomposed.png"

    ie "lt IE 9", ->
      script async: yes, src: "http://html5shim.googlecode.com/svn/trunk/html5.js"

    text @getBlock('styles').add(@site.styles).toHTML()

    body ->
      # TODO: Too long and probabily repetitive. Convert to helper (?)
      div class: "navbar navbar-fixed-top", ->
        div class: "navbar-inner", ->
          div class: "container", ->
            a class: "brand", href: "/", ->
              @site.title

            ul class: "nav", ->
              for document in @getCollection('pages').toJSON()
                li typeof: "sioc:Page", about: document.url, class: ('active' if @document.url is document.url), ->
                  a href: document.url, property: "dc:title", ->
                    document.title

    div class: "container", ->
      text @content

      footer ->
        p "&copy #{@site.author}"
    
    text @getBlock('scripts').add(@site.scripts).toHTML()
