mysql_db = require 'mysql-activerecord'


db = new mysql_db.Adapter(
    server: process.env.MYSQL_SERVER ? 'localhost'
    username: process.env.MYSQL_USERNAME ? 'root'
    password: process.env.MYSQL_PASSWORD ? ''
    database: process.env.HACKER_ATOM_DB_NAME ? 'hackeratom')


feedTableQuery = "
CREATE TABLE IF NOT EXISTS `feed_record` (
  `id` INT(32) NOT NULL,
  `url` VARCHAR(256) NOT NULL,
  `user` VARCHAR(128) NOT NULL,
  `content` MEDIUMTEXT NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
);
"

rankTableQuery = "
CREATE TABLE IF NOT EXISTS `rank_record` (
  `id` TINYINT NOT NULL AUTO_INCREMENT,
  `rank` TINYINT NOT NULL,
  `hn_id` INT(32) NOT NULL,
  `datetime` DATETIME NOT NULL,
  PRIMARY KEY (`id`)
);
"

failed = (err) ->
    console.log 'database operation failed with error:', err

initDB = ->
    try
        connection = db.connection()
        connection.query feedTableQuery, (err) ->
            if err
                failed err
            else
                connection.query rankTableQuery, (err) ->
                    if err
                        failed err
                    else
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
        if err
            failed err


addFeedRecord = (obj) ->
    feed =
        id:obj.id
        url:obj.url
        user:obj.user

    addRankRecord obj
    db.insert 'feed_record', feed, (err)->
        if err
            failed err
        else
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
            
getRanks = (hn_id, callback) ->
    db.where(hn_id:hn_id).get 'rank_record', (err, rank_results, rank_fields) =>
        if err
            failed err
        else
            callback rank_results


record = {}

record.get = getFeed
record.getRanks = getRanks
record.addFeed = addFeedRecord
record.logRank = addRankRecord
record.now = ->
    pad = (n) ->
        if n < 10
            return '0' + n
        else
            return n
    now = new Date()
    date = now.getUTCFullYear() + '-' + pad(now.getUTCMonth()) + '-' + pad(now.getUTCDate())
    time = pad(now.getUTCHours()) + ':' + pad(now.getUTCMinutes()) + ':' + pad(now.getUTCSeconds())
    return date + ' ' + time

module.exports = record
