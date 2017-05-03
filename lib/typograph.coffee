http = require 'http'


class Typograph
    defaults: ->
        entity: 1
        use_p: 0
        use_br: 0
        max_nobr: 0

    start: (params={}, callback)->
        if typeof params is 'string'
            params = text: params

        unless params.text
            callback? 'no_text'
            throw 'No text'

        return @_send params, callback

    _send: (user_params, callback)->
        default_params = @defaults()
        params = @_extend default_params, user_params

        xmlRequest = """
            <?xml version="1.0" encoding="UTF-8"?>
            <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:xsd="http://www.w3.org/2001/XMLSchema"
            xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
                <soap:Body>
                    <ProcessText xmlns="http://typograf.artlebedev.ru/webservices/">
                        <text>#{params.text}</text>
                        <entityType>#{params.entity}</entityType>
                        <useP>#{params.use_p}</useP>
                        <useBr>#{params.use_br}</useBr>
                        <maxNobr>#{params.max_nobr}</maxNobr>
                    </ProcessText>
                </soap:Body>
            </soap:Envelope>
        """

        httpOptions =
            hostname: 'typograf.artlebedev.ru'
            port: 80
            path: '/webservices/typograf.asmx'
            method: 'POST'
            headers:
                'Content-length': @getLength xmlRequest
                'Content-Type': 'text/xml; charset=UTF-8'

        Promise.resolve()
        .then =>
            @_request httpOptions, xmlRequest

        .then (data)->
            tag    = 'ProcessTextResult'
            start  = data.indexOf(tag) + tag.length + 1
            length = data.indexOf('</'+tag) - start

            text = data.substr start, length
            text = text.replace /\&amp\;/gim, '&'
            text = text.replace /\&lt\;/gim, '<'
            text = text.replace /\&gt\;/gim, '>'
            text = text.replace /\n$/, ''

            return text

        .then (text)->
            callback? null, text
            return text

        .catch (err)->
            callback? err
            throw err

    _request: (options, data, callback)->
        new Promise (resolve, reject)->
            request = http.request options, (response)->
                text = ''
                response.setEncoding 'utf8'

                response.on 'data', (chunk)->
                    text += chunk.toString()

                response.on 'end', ->
                    callback? null, text
                    resolve text

            request.on 'error', (err)->
                callback? err
                reject err

            request.write data
            request.end()

    _extend: (dObj={}, uObj={})->
        has = Object.prototype.hasOwnProperty
        obj = {}
        keys = Object.keys dObj
        keys = keys.concat Object.keys uObj

        for key in keys
            unless obj[key]
                obj[key] = if has.call uObj, key then uObj[key] else dObj[key]

        return obj

    getLength: (text)->
        m = encodeURIComponent(text).match /%[89ABab]/g
        return text.length + if m then m.length else 0


typograf = new Typograph()
module.exports = -> typograf.start.apply typograf, arguments
