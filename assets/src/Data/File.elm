module Data.File exposing
    ( Data
    , File
    , addFile
    , create
    , delete
    , getDirShopFiles
    , getFileBytes
    , initData
    , mergeData
    , update
    )

import Api
import Bytes
import Bytes.Decode
import Data.Dir
import Dict
import File
import Http
import Json.Decode
import Json.Encode



-- FILE


type alias File =
    { id : Int
    , type_ : Type_
    , name : String
    , url : String
    , previewUrl : String
    , mimeType : String
    , dirId : Data.Dir.Id
    }


type alias Data =
    Dict.Dict Int File


initData : Data
initData =
    Dict.empty


addFile : File -> Data -> Data
addFile file =
    Dict.insert file.id file


mergeData : Data -> Data -> Data
mergeData =
    Dict.union



-- DECODER


decoder : Json.Decode.Decoder File
decoder =
    Json.Decode.map7 File
        (Json.Decode.field "id" Json.Decode.int)
        (Json.Decode.field "type" typeDecoder)
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "url" Json.Decode.string)
        (Json.Decode.field "preview_url" Json.Decode.string)
        (Json.Decode.field "mime_type" Json.Decode.string)
        (Json.Decode.field "dir_id" Data.Dir.optionalIdDecoder)


dataDecoder : Json.Decode.Decoder Data
dataDecoder =
    Json.Decode.map
        (Dict.fromList << List.map (\dir -> ( dir.id, dir )))
        (Json.Decode.list decoder)



-- TYPE


type Type_
    = Generic
    | Image
    | Video


typeDecoder : Json.Decode.Decoder Type_
typeDecoder =
    Json.Decode.andThen
        (\type_ ->
            case type_ of
                "file" ->
                    Json.Decode.succeed Generic

                "image" ->
                    Json.Decode.succeed Image

                "video" ->
                    Json.Decode.succeed Video

                _ ->
                    Json.Decode.fail <|
                        "Unknown file type \""
                            ++ type_
                            ++ "\"."
        )
        Json.Decode.string



-- REQUESTS


getDirShopFiles :
    Data.Dir.Id
    ->
        { token : String
        , tracker : Maybe String
        , tagger : Result Http.Error Data -> msg
        }
    -> Cmd msg
getDirShopFiles id { token, tracker, tagger } =
    let
        url =
            "/shop/dirs/" ++ Data.Dir.idToString id ++ "/files"
    in
    Api.request token
        { method = "GET"
        , headers = []
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson tagger dataDecoder
        , timeout = Nothing
        , tracker = tracker
        }


getFileBytes : File -> (Result Http.Error Bytes.Bytes -> msg) -> Cmd msg
getFileBytes { url } tagger =
    Http.request
        { method = "GET"
        , headers = []
        , url = url
        , body = Http.emptyBody
        , expect = getFileBytesResponse tagger
        , timeout = Nothing
        , tracker = Nothing
        }


getFileBytesResponse : (Result Http.Error Bytes.Bytes -> msg) -> Http.Expect msg
getFileBytesResponse tagger =
    Http.expectBytesResponse tagger <|
        \response ->
            case response of
                Http.BadUrl_ url_ ->
                    Err <| Http.BadUrl url_

                Http.Timeout_ ->
                    Err <| Http.Timeout

                Http.NetworkError_ ->
                    Err <| Http.NetworkError

                Http.BadStatus_ metadata _ ->
                    Err <| Http.BadStatus metadata.statusCode

                Http.GoodStatus_ _ body ->
                    let
                        width =
                            Bytes.width body
                    in
                    case Bytes.Decode.decode (Bytes.Decode.bytes width) body of
                        Just bytes_ ->
                            Ok bytes_

                        Nothing ->
                            Err <| Http.BadBody "unexpected bytes"



-- CREATE


create :
    String
    -> Data.Dir.Id
    -> File.File
    -> (Result Http.Error File -> msg)
    -> Cmd msg
create token dirId file tagger =
    Api.request token
        { method = "POST"
        , headers = []
        , url = "/shop/dirs/" ++ Data.Dir.idToString dirId ++ "/files"
        , body = Http.multipartBody [ Http.filePart "file" file ]
        , expect = Http.expectJson tagger decoder
        , timeout = Nothing
        , tracker = Nothing
        }



-- UPDATE


update : String -> File -> (Result Http.Error File -> msg) -> Cmd msg
update token file tagger =
    Api.request token
        { method = "PATCH"
        , headers = []
        , url = "/files/" ++ String.fromInt file.id
        , body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "file"
                      , Json.Encode.object
                            [ ( "dir_id"
                              , Json.Encode.int <|
                                    Maybe.withDefault 0 <|
                                        String.toInt <|
                                            Data.Dir.idToString file.dirId
                              )
                            ]
                      )
                    ]
        , expect = Http.expectJson tagger decoder
        , timeout = Nothing
        , tracker = Nothing
        }



-- DELETE


delete : String -> File -> (Result Http.Error File -> msg) -> Cmd msg
delete token file tagger =
    Api.request token
        { method = "DELETE"
        , headers = []
        , url = "/files/" ++ String.fromInt file.id
        , body = Http.emptyBody
        , expect = Http.expectJson tagger decoder
        , timeout = Nothing
        , tracker = Nothing
        }
