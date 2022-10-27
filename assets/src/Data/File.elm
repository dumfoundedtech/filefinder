module Data.File exposing (Data, File, getDirShopFiles, getRootShopFiles)

import Api
import Data.Dir
import Dict
import Http
import Json.Decode



-- FILE


type alias File =
    { id : Int
    , name : String
    , previewUrl : String
    , type_ : Type_
    , url : String
    , dirId : Data.Dir.Id
    }


type alias Data =
    Dict.Dict Int File



-- DECODER


decoder : Json.Decode.Decoder File
decoder =
    Json.Decode.map6 File
        (Json.Decode.field "id" Json.Decode.int)
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "preview_url" Json.Decode.string)
        (Json.Decode.field "type" typeDecoder)
        (Json.Decode.field "url" Json.Decode.string)
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

                "Video" ->
                    Json.Decode.succeed Video

                _ ->
                    Json.Decode.fail <|
                        "Unknown file ttype \""
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
