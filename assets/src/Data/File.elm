module Data.File exposing
    ( Data
    , File
    , getDirShopFiles
    , getFileBytes
    , getRootShopFiles
    )

import Api
import Bytes
import Bytes.Decode
import Data.Dir
import Dict
import Http
import Json.Decode



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


getRootShopFiles :
    { token : String
    , tracker : Maybe String
    , tagger : Result Http.Error Data -> msg
    }
    -> Cmd msg
getRootShopFiles { token, tracker, tagger } =
    Api.request token
        { method = "GET"
        , headers = []
        , url = "/shop/dirs/root/files"
        , body = Http.emptyBody
        , expect = Http.expectJson tagger dataDecoder
        , timeout = Nothing
        , tracker = tracker
        }


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
