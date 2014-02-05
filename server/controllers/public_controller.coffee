record = require '../models/record'
Feed = require './feed'

publicController = {}

# home page '/'
publicController.index = (req, res) ->
    hostname = req.host
    atom_url = "#{req.host}/atom"
    res.render 'public/index', {'atom_url': atom_url}

publicController.atom = (req, res) ->
    res.type "text/xml"
    feed = new Feed(
        title:'HackerAtom'
        description:'Convert articles from hackernews into atom feeds. see http://' + req.host
        link:req.host
    )
    record.feeds (feeds) =>
        for f in feeds
            guid = "http://news.ycombinator.com/?item=#{f.id}"
            feed.addItem(
                title:f.title
                link:f.url
                creator:f.user
                pubDate:f.created_at
                content: f.content
                guid:guid
                comments:guid
            )
        res.send feed.render()


module.exports = publicController
