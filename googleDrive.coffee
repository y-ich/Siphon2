# Google Drive

CLIENT_ID = '361799283439.apps.googleusercontent.com'
SCOPES = 'https://www.googleapis.com/auth/drive'

window.googleDrive =
    authorized: false

BOUNDARY = '-------314159265358979323846'
delimiter = "\r\n--#{BOUNDARY}\r\n"
close_delim = "\r\n--#{BOUNDARY}--"

class googleDrive.File
    @insert: (title, type, content, callback) ->
        metadata =
                'title': title
                'mimeType': type
        base64Data = btoa content

        multipartRequestBody =
            delimiter +
            'Content-Type: application/json\r\n\r\n' +
            JSON.stringify(metadata) +
            delimiter +
            "Content-Type: #{contentType}\r\n" +
            'Content-Transfer-Encoding: base64\r\n' +
            '\r\n' +
            base64Data +
            close_delim

        request = gapi.client.request
            'path': '/upload/drive/v2/files'
            'method': 'POST'
            'params':
                'uploadType': 'multipart'
            'headers':
                'Content-Type': "multipart/mixed; boundary=\"#{BOUNDARY}\""
            'body': multipartRequestBody
        request.execute callback

    @getList: (q, callback) ->
        retrievePageOfFiles = (request, result) ->
            request.execute (resp) ->
                result = result.concat resp.items
                nextPageToken = resp.nextPageToken
                if nextPageToken?
                    request = gapi.client.drive.files.list
                        'pageToken': nextPageToken
                    retrievePageOfFiles request, result
                else
                    callback result
        initialRequest = gapi.client.drive.files.list q: q
        retrievePageOfFiles initialRequest, []
        
    constructor: (idOrResource) ->
        if typeof idOrResource is 'string'
            request = gapi.client.drive.files.get 'fileId': idOrResource
            request.execute (resp) => @resource = resp
        else
            @resource = idOrResource

    id: -> @resource.id

    download: (callback) ->
        if @resource.downloadUrl?
            accessToken = gapi.auth.getToken().access_token
            xhr = new XMLHttpRequest()
            xhr.open 'GET', file.downloadUrl
            xhr.setRequestHeader 'Authorization', 'Bearer ' + accessToken
            xhr.onload = -> callback xhr.responseText
            xhr.onerror = -> callback null
            xhr.send()
        else
            callback null

    patch: (resource) ->
        request = gapi.client.drive.files.patch
            'fileId': @id(),
            'resource': resource
        request.execute (resp) -> @resource = resp

    update: (resource, content, callback) ->
        base64Data = btoa content

        multipartRequestBody =
            delimiter +
            'Content-Type: application/json\r\n\r\n' +
            JSON.stringify(resource) +
            delimiter +
            "Content-Type: #{contentType}\r\n" +
            'Content-Transfer-Encoding: base64\r\n' +
            '\r\n' +
            base64Data +
            close_delim

        request = gapi.client.request
            'path': "/upload/drive/v2/files/#{@id()}"
            'method': 'PUT'
            'params':
                'uploadType': 'multipart'
                'alt': 'json'
            'headers':
                'Content-Type': "multipart/mixed; boundary=\"#{BOUNDARY}\""
            'body': multipartRequestBody
        request.execute callback

    copy: (title, callback) ->
        resource = 'title': title
        request = gapi.client.drive.files.copy
            'fileId': @id()
            'resource': resource
        request.execute callback

    delete: ->
        request = gapi.client.drive.files.delete 'fileId': @id()
        request.execute()
    
    touch: ->
        request = gapi.client.drive.files.touch 'fileId': @id()
        request.execute (resp) => @resource = resp
    
    trash: ->
        request = gapi.client.drive.files.trash 'fileId': @id()
        request.execute (resp) => @resource = resp
    
    untrash: ->
        request = gapi.client.drive.files.untrash 'fileId': @id()
        request.execute (resp) => @resource = resp


# Check if the current user has authorized the application.
googleDrive.checkAuth = (success) ->
    handleAuthResult = (authResult) ->
        if authResult and not authResult.error
            googleDrive.authorized = true
            success()
        else
            gapi.auth.authorize
                    'client_id': CLIENT_ID
                    'scope': SCOPES
                    'immediate': false
                , handleAuthResult

    gapi.auth.authorize
            'client_id': CLIENT_ID
            'scope': SCOPES
            'immediate': true
        , handleAuthResult

window.handleClientLoad = ->
    gapi.client.load 'drive', 'v2'
