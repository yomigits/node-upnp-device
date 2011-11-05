http = require 'http'
fs = require 'fs'
url = require 'url'
portscanner = require 'portscanner'
device = require './device'
helpers = require './helpers'

createServer = exports.createServer = (deviceType, deviceName) ->
    http.createServer (req, res) ->
        if isServiceReq(req) or isDeviceReq(req)
            res.writeHead 200, 'Content-Type': 'text/xml'
            if isServiceReq(req) and getReqAction(req) is 'description'
                # service descriptions are static XML files
                fs.readFile makeServicePath(getReqType(req)), (err, file) ->
                    throw err if err
                    res.write file
                    res.end()
            else
                res.write '<?xml version="1.0" encoding="utf-8"?>\n'
                if isDeviceReq(req)
                    res.write device.buildDescription deviceType, deviceName
                res.end()
        else
            res.writeHead 404, 'Content-Type': 'text/plain'
            res.write '404 Not found'
            res.end()

# find a suitable IP/port and start listening on server
listen = exports.listen = (server, callback) ->
    helpers.getNetworkIP (err, address) ->
        return callback err if err
        portscanner.findAPortNotInUse 49201, 49220, address, (err, port) ->
            return callback err if err
            server.listen port, address, (err) ->
                callback err, { address: address, port: port }

# handle requests in various ways
parseReq = (req) ->
    # url formats:
    # /device/description
    # /service/(description|control|event)/serviceType
    path = url.parse(req.url).pathname.split('/')
    {
        category: path[1]
        action: path[2]
        type: path[3]
    }
getReqCategory = (req) -> parseReq(req).category
getReqAction = (req) -> parseReq(req).action
getReqType = (req) -> parseReq(req).type

isDeviceReq = (req) -> getReqCategory(req) is 'device'
isServiceReq = (req) -> getReqCategory(req) is 'service'

makeServicePath = (serviceType) ->
    __dirname + '/services/' + serviceType + '.xml'
