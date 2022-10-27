module Api exposing (request)

import Http



-- REQUEST


request :
    String
    ->
        { method : String
        , headers : List Http.Header
        , url : String
        , body : Http.Body
        , expect : Http.Expect msg
        , timeout : Maybe Float
        , tracker : Maybe String
        }
    -> Cmd msg
request token options =
    let
        auth =
            Http.header "Authorization" <| "Bearer " ++ token
    in
    Http.request
        { method = options.method
        , headers = auth :: options.headers
        , url = "/api" ++ options.url
        , body = options.body
        , expect = options.expect
        , timeout = options.timeout
        , tracker = options.tracker
        }
