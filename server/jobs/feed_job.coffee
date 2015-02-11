readability = require 'node-readability'
schedule = require 'node-schedule'

record = require '../models/record'
makeFeed = require './fetch_content'

fetchJob = {}

request = require 'request'
cheerio = require 'cheerio'

retries = 0


parseFeed = (title, rank, datetime)->
    linkObj = title.children('a')
    if not linkObj.length
        return null
    else if linkObj.text().match(/^More$/ig)
        return -1
    link = linkObj.attr 'href'
    titleText = linkObj.text()
    next = title.parent().next()
    subLinks = next.find('a')
    if subLinks.length >= 2
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


parseHackerNewsBody = (body, datetime) ->
    $ = cheerio.load(body)
    titles = $('td.title')
    rank = 1
    feeds = []
    for index, title of titles
        parsedFeed = parseFeed($(title), rank, datetime)
        if parsedFeed == -1
            break
        else if parsedFeed
            rank += 1
            feeds.push parsedFeed
    ids = (feed.id for feed in feeds)
    record.gets ids, (results) =>
        old_ids = (feed.id for feed in results)
        for feed in feeds
            if feed.id in old_ids
                record.logRank feed
            else
                record.addFeed feed

fetchHackNews = (retries) ->
    retries = retries ? 1
    datetime = record.now()
    request.get 'https://news.ycombinator.com/', (error, response, body) =>
        if (!error && response.statusCode==200)
            console.log 'request HN front page finished'
            parseHackerNewsBody(body, datetime)
        else
            console.error 'Fetch hackernews failed: (' + retries + '/10)'
            retries += 1
            fetchHackNews(retries) if retries <= 10


selectTopFeeds = ->
    timelimit = new Date()
    timelimit.setHours(timelimit.getHours() - 4)
    record.feedAfter timelimit, (rs) ->
        if rs.length
            makeFeed rs[0]

job = {}
job.schedule =  ->
    job.fetchJob = schedule.scheduleJob minute:[10, 30, 50], fetchHackNews
    job.selectJob = schedule.scheduleJob minute:0, selectTopFeeds
    console.log 'jobs scheduled'

job.selectJobF = selectTopFeeds
job.fetchHackNewsF = fetchHackNews


module.exports = job
