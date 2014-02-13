readability = require 'node-readability'
schedule = require 'node-schedule'

record = require '../models/record'
Feed = require '../controllers/feed'

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


makeFeed = (feed) ->
    readability feed.url, (err, article) =>
        hn_line = "<div><b>HN:</b>
                    top rank #{feed.top} |
                    by <a href='https://news.ycombinator.com/user?id=#{feed.user}'>#{feed.user}</a> |
                    <a href='https://news.ycombinator.com/item?id=#{feed.id}'>comments</a></div>
                    <hr>
                    "

        if err or article.content == false
            content = "<a href='#{feed.url}' >#{feed.url}</a>"
        else
            hn_title = feed.title.replace(/\s/g, '').toLowerCase()
            original_title = article.title.replace(/\s/g, '').toLowerCase()
            if hn_title != original_title
                hn_line += "<div>(Original Title: #{article.title})</div>"
            content = article.content
            content += "<div>[link]:<a href='#{feed.url}'>#{feed.url}</a></div>"
        feed.content = hn_line + content
        feed.accepted_at = record.now()
        record.update(feed.id, feed)
        console.log feed
        console.log 'new feed selected:', feed
        Feed.invalideCachedFeed()


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
