record = require '../models/record'
Feed = require './feed'

publicController = {}

# home page '/'
publicController.index = (req, res) ->
    hostname = req.host
    rss_url = "hackernews.io-meter.com/rss"
    res.render 'public/index', {'rss_url': rss_url}

publicController.rss = (req, res) ->
    res.type "text/xml"
    feed = Feed.cachedFeed()
    if feed and feed.length
        return res.send feed

    console.log 'build feed'
    feed = new Feed(
        title:'HackerRSS'
        description:'Convert articles from hackernews into RSS feed. see http://hackerrss.io-meter.com'
        link:req.host
    )
    record.feeds (feeds) =>
        for f in feeds
            guid = "http://news.ycombinator.com/?item=#{f.id}"
            feed.addItem(
                title:f.title
                link:f.url
                creator:f.user
                pubDate:f.accepted_at
                content: f.content
                guid:guid
                comments:guid
            )
        res.send feed.render()


module.exports = publicController
