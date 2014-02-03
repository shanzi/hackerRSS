record = require '../models/record'

fetchJob = {}

request = require 'request'
cheerio = require 'cheerio'

retries = 0


parseSubmit = (title, rank, datetime)->
    linkObj = title.children('a')
    if not linkObj.length
        return null
    else if linkObj.text().match(/More/ig)
        return -1
    link = linkObj.attr 'href'
    titleText = linkObj.text()
    next = title.parent().next()
    subLinks = next.find('a')
    if subLinks.length == 2
        user = subLinks.eq(0).text()
        id = parseInt subLinks.eq(1).attr('href')[8..]
    else
        return null

    title: titleText
    url: link
    user: user
    id: id
    rank: rank
    datetime: datetime

handleArticle = (obj) ->
    id = obj.id
    record.get id, (result) =>
        if result
            record.logRank obj
        else
            record.addFeed obj


parseHackerNewsBody = (body, datetime) ->
    $ = cheerio.load(body)
    titles = $('td.title')
    rank = 0
    for index, title of titles
        rank += 1
        parsedTitle = parseSubmit($(title), rank, datetime)
        if parsedTitle == -1
            break
        else if parsedTitle
            handleArticle parsedTitle

fetchHackNews = ->
    datetime = record.now()
    request.get 'https://news.ycombinator.com/', (error, response, body) =>
        console.log 'request HN front page finished'
        if (!error && response.statusCode==200)
            retries = 0
            parseHackerNewsBody(body, datetime)
        else if retries >= 10
            console.error 'Fetch hackernews failed' 
        else
            retries+=1


fetchHackNews()
