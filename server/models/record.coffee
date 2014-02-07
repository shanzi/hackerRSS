mysql_db = require 'mysql-activerecord'


db = new mysql_db.Adapter(
    server: process.env.MYSQL_SERVER ? 'localhost'
    username: process.env.MYSQL_USERNAME ? 'root'
    password: process.env.MYSQL_PASSWORD ? ''
    database: process.env.HACKER_ATOM_DB_NAME ? 'hackerrss')


feedTableQuery = "
CREATE TABLE IF NOT EXISTS `feed_record` (
  `id` INT(32) NOT NULL,
  `url` VARCHAR(256) NOT NULL,
  `user` VARCHAR(128) NOT NULL,
  `title` VARCHAR(256) NOT NULL,
  `content` MEDIUMTEXT NULL DEFAULT NULL,
  `created_at` DATETIME NOT NULL,
  `accepted_at` DATETIME NULL,
  PRIMARY KEY (`id`),
  INDEX `accepted_at_index` (`accepted_at`)
);
"

rankTableQuery = "
CREATE TABLE IF NOT EXISTS `rank_record` (
  `id` INT(32) NOT NULL AUTO_INCREMENT,
  `rank` TINYINT NOT NULL,
  `hn_id` INT(32) NOT NULL,
  `datetime` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `hn_id_index` (`hn_id`)
);
"

failed = (err) ->
    console.log 'database operation failed with error:', err

dateToSQL = (d)->
    pad = (n) ->
        if n < 10
            return '0' + n
        else
            return n
    date = d.getUTCFullYear() + '-' + pad(d.getUTCMonth()) + '-' + pad(d.getUTCDate())
    time = pad(d.getUTCHours()) + ':' + pad(d.getUTCMinutes()) + ':' + pad(d.getUTCSeconds())
    return date + ' ' + time

initDB = ->
    try
        connection = db.connection()
        connection.query feedTableQuery, (err) ->
            return failed err if err
            connection.query rankTableQuery, (err) ->
                return failed err if err
                console.log "init database success"
    catch error
        failed err

initDB()

addRankRecord = (obj) ->
    record =
        hn_id:obj.id
        rank:obj.rank
        datetime:obj.datetime

    db.insert 'rank_record', record, (err) ->
        failed err if err


addFeedRecord = (obj) ->
    feed =
        id:obj.id
        url:obj.url
        user:obj.user
        title:obj.title
        created_at:obj.datetime

    addRankRecord obj
    db.insert 'feed_record', feed, (err)->
        return failed err if err
        console.log 'added feed', feed


getFeed = (id, callback) ->
    db.where(id:id).get 'feed_record', (err, results, fields) =>
        if err
            failed err
        else if results.length == 0
            callback(null)
        else
            ret = results[0]
            callback ret


getFeeds = (ids, callback) ->
    db.where('id', ids).get 'feed_record', (err, results) =>
        return failed err if err
        callback results



getRanks = (hn_id, callback) ->
    db.where(hn_id:hn_id).get 'rank_record', (err, rank_results, rank_fields) =>
        return failed err if err
        callback rank_results

getFeedAfter = (limit, callback) ->
    limitString = dateToSQL(limit)
    db.where("content IS NULL AND created_at >= '#{limitString}'").get 'feed_record', (err, feed_results) =>
        return failed err if err
        ids = (rs.id for rs in feed_results)
        if ids.length
            db.where("hn_id", ids).where("datetime > '#{limitString}'").get 'rank_record', (err, results) =>
                return failed err if err
                scores = {}
                counts = {}
                for obj in results
                    hn_id = obj.hn_id
                    score = obj.rank
                    if counts[hn_id] > 0
                        counts[hn_id] += 1
                        scores[hn_id] += score
                    else
                        counts[hn_id] = 1
                        scores[hn_id] = score
                for rs in feed_results
                    rs.count = counts[rs.id] ? 1
                    rs.avg = scores[rs.id] / rs.count ? 999999
                    rs.score = rs.avg * (if rs.count <4 then (4/rs.count) else 1)
                feed_results.sort (a, b) ->
                    a.score - b.score
                callback(feed_results)


updateFeed = (id, feedObj) ->
    feed =
        content:feedObj.content
        accepted_at: feedObj.accepted_at

    db.where({id:id}).update 'feed_record', feed, (err) ->
        return failed err if err

feeds = (callback) ->
    db.where('content IS NOT NULL').order_by('accepted_at DESC').limit(30).get 'feed_record', (err, res) ->
        callback res

record = {}

record.get = getFeed
record.gets = getFeeds
record.update = updateFeed
record.getRanks = getRanks
record.addFeed = addFeedRecord
record.logRank = addRankRecord
record.feedAfter = getFeedAfter
record.feeds = feeds
record.now = ->
    now = new Date()
    dateToSQL(now)

module.exports = record
