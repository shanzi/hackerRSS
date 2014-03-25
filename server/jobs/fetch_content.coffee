readability = require 'node-readability'
record = require '../models/record'
Feed = require '../controllers/feed'
request = require 'request'
cheerio = require 'cheerio'

read = (feed, callback) ->
    url = feed.url
    readability url, (err, article) =>
        content = null
        if err or article.content == false
            content = "<a href='#{feed.url}' >#{feed.url}</a>"
        else
            content = article.content
            content += "<div>[link]:<a href='#{feed.url}'>#{feed.url}</a></div>"
            hn_title = feed.title.replace(/\s/g, '').toLowerCase()
            original_title = article.title.replace(/\s/g, '').toLowerCase()
            if hn_title != original_title
                content = "<div>(Original Title: #{article.title})</div>" + content
        callback content
        
github = (feed, callback) ->
    url = feed.url
    type = null
    if url.match /^https?:\/\/github.com\/([\w\-\.]+)\/?$/
        type = 'user'
    else if url.match /^https?:\/\/github.com\/([\w\-\.]+)\/([\w\-\.]+)\/?$/
        type = 'project'
    else
        return read feed callback
    request.get url, (error, res, body) =>
        if (!error && res.statusCode==200)
            $ = cheerio.load body
            content = null
            if type == 'user'
                content = $('.vcard')
                content.find('.octicon').remove()
                content.find('.email').parent().remove()
                username = content.find '.vcard-username'
                nu = $ "<small>(#{username.text()})</small>"
                username.replaceWith nu
                avatar = $('.vcard-avatar')
                avatar.replaceWith avatar.html()
                $('.vcard-names').prepend '<img width="30" height="29"
                    src="https://hackernews.io-meter.com/assets/images/github.png" />'
                status = '<ul>'
                for a in $('.vcard-stat')
                    a = $ a
                    status += "<li><a href='#{a.attr "href" }'>#{a.html()}</a></li>"
                status += '</ul>'
                $('.vcard-stats').replaceWith status
                content = content.html()
            else if type =='project'
                desc = $('.repository-description').text()
                website = $('.repository-website a').html()
                article = $('.entry-content').html() ? 'No Readme'
                title = $('.entry-title')
                title.find('.octicon-repo').remove()
                title.find('.repo-label').remove()
                title.find('.page-context-loader').remove()
                title = title.html()
                content = "
                <h1>
                <img src='http://hackernews.io-meter.com/assets/images/github.png' width='30' height='29'>
                #{title}
                </h1>
                <pre>
                #{desc} #{website}
                </pre>
                <hr/>
                </hr>
                <p><b>README:</b></p>
                <hr/>
                <div>
                #{article}
                </div>
                "
            if content
                $ = cheerio.load content
                links = $ 'a'
                for link in links
                    link = $ link
                    href = link.attr 'href'
                    if href and href[0]=='/'
                        href = 'https://github.com' + href
                    link.attr 'href', href
                callback $.html()
                return
                        
        read feed callback

makeFeed = (feed) ->
    url = feed.url
    func = null
    if url.match /^https?:\/\/github.com/
        func = github
    else
        func = read
    func feed, (content) =>
        hn_line = "<div><b>HN:</b>
                    top rank #{feed.top} |
                    by <a href='https://news.ycombinator.com/user?id=#{feed.user}'>#{feed.user}</a> |
                    <a href='https://news.ycombinator.com/item?id=#{feed.id}'>comments</a></div>
                    <hr>
                    "
        feed.content = hn_line + content
        feed.accepted_at = record.now()
        record.update(feed.id, feed)
        console.log feed
        console.log 'new feed selected:', feed
        Feed.invalideCachedFeed()

module.exports = makeFeed
