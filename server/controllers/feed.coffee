xml = require 'xml'
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
            {'content:encoded':{_cdata:args.content}},
            {'dc:creator':args.creator},
            {pubDate:args.pubDate.toUTCString()},
            {guid:[_attr:{isPermalink:false}, args.guid]},
            {comments:args.comments ? ''}
        ]
        @items.push item:item

    render: ->
        attr =
            version:'2.0'
            'xmlns:content':'http://purl.org/rss/1.0/modules/content/'
            'xmlns:wfw':'http://wellformedweb.org/CommentAPI/'
            'xmlns:dc':'http://purl.org/dc/elements/1.1/'
            'xmlns:atom':'http://www.w3.org/2005/Atom'
            'xmlns:sy':'http://purl.org/rss/1.0/modules/syndication/'
            'xmlns:slash':'http://purl.org/rss/1.0/modules/slash/'
        feedInfo = [
            {title:@title},
            {link:@link},
            {description:@description},
            {'sy:updatePeriod':@updatePeriod},
            {'sy:updateFrequency':@updateFrequency}
        ]
        channel = channel: feedInfo.concat @items
        xml rss: [_attr:attr, channel]

module.exports = Feed
