storage = require 'node-simple-cache'
xml = require 'xml'


cache = new storage.Storage()

class Feed extends Object

    constructor: (args) ->
        @title = args.title
        @link = args.link
        @description = args.description
        @lastBuildDate = args.lastBuildDate ? (new Date()).toUTCString()
        @updatePeriod = args.updatePeriod ? 'hourly'
        @updateFrequency = args.updateFrequency ? 1
        @items = []

    addItem: (args) ->
        item = [
            {title:args.title},
            {link:args.link},
            {description:{_cdata:args.description ? args.content}},
            {'dc:creator':args.creator},
            {author:args.creator},
            {pubDate:args.pubDate.toUTCString()},
            {guid:[_attr:{isPermalink:false}, args.guid]},
            {comments:args.comments ? ''}
        ]
        @items.push item:item

    render: ->
        attr =
            version:'2.0'
            'xmlns:wfw':'http://wellformedweb.org/CommentAPI/'
            'xmlns:dc':'http://purl.org/dc/elements/1.1/'
            'xmlns:atom':'http://www.w3.org/2005/Atom'
            'xmlns:sy':'http://purl.org/rss/1.0/modules/syndication/'
            'xmlns:slash':'http://purl.org/rss/1.0/modules/slash/'
        feedInfo = [
            {title:@title},
            {link:@link},
            {'atom:link':[_attr:{href:@link,ref:'self',type:'application/rss+xml'}]},
            {description:@description},
            {'sy:updatePeriod':@updatePeriod},
            {'sy:updateFrequency':@updateFrequency},
            {language:'en-US'}
            {ttl:60}
        ]
        if @items and @items.length
            firstItem = @items[0]
            for pair in firstItem.item
                if pair.pubDate
                    feedInfo.push {pubDate:pair.pubDate}
        channel = channel: feedInfo.concat @items
        feed = rss: [_attr:attr, channel]
        rendered = xml feed, declaration: true
        cache.set 'rss', rendered
        return rendered

    @cachedFeed: ->
        cache.get 'rss'

    @invalideCachedFeed: ->
        cache.set 'rss', ''

module.exports = Feed
