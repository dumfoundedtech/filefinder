module Data.Dir exposing
    ( Data
    , Dir
    , Id
    , appendDir
    , dirPath
    , getDirShopDirs
    , getRootShopDirs
    , idDecoder
    , idFromInt
    , idToString
    , initData
    , initId
    , optionalIdDecoder
    , update
    )

import Api
import Dict
import Http
import Json.Decode
import Json.Encode



-- DIR


type alias Dir =
    { id : Id
    , name : String
    , dirId : Id
    }


type alias Data =
    Dict.Dict String Dir


initData : Data
initData =
    Dict.empty


appendDir : Dir -> Data -> Data
appendDir dir data =
    Dict.insert (idToString dir.id) dir data



-- DECODER


decoder : Json.Decode.Decoder Dir
decoder =
    Json.Decode.map3 Dir
        (Json.Decode.field "id" idDecoder)
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "dir_id" optionalIdDecoder)


dataDecoder : Json.Decode.Decoder Data
dataDecoder =
    Json.Decode.map
        (Dict.fromList << List.map (\dir -> ( idToString dir.id, dir )))
        (Json.Decode.list decoder)



-- ID


type Id
    = Root
    | Sub Int


idDecoder : Json.Decode.Decoder Id
idDecoder =
    Json.Decode.andThen
        (\id ->
            case idFromInt id of
                Just sub ->
                    Json.Decode.succeed sub

                Nothing ->
                    Json.Decode.fail "Invalid id"
        )
        Json.Decode.int


optionalIdDecoder : Json.Decode.Decoder Id
optionalIdDecoder =
    Json.Decode.oneOf [ idDecoder, Json.Decode.null initId ]


initId : Id
initId =
    Root


idFromInt : Int -> Maybe Id
idFromInt id =
    if id > 0 then
        Just <| Sub id

    else
        Nothing


idToString : Id -> String
idToString id =
    case id of
        Root ->
            "root"

        Sub id_ ->
            String.fromInt id_



-- REQUESTS


getRootShopDirs :
    { token : String
    , tracker : Maybe String
    , tagger : Result Http.Error Data -> msg
    }
    -> Cmd msg
getRootShopDirs { token, tracker, tagger } =
    Api.request token
        { method = "GET"
        , headers = []
        , url = "/shop/dirs/root/dirs"
        , body = Http.emptyBody
        , expect = Http.expectJson tagger dataDecoder
        , timeout = Nothing
        , tracker = tracker
        }


getDirShopDirs :
    Id
    ->
        { token : String
        , tracker : Maybe String
        , tagger : Result Http.Error Data -> msg
        }
    -> Cmd msg
getDirShopDirs id { token, tracker, tagger } =
    let
        url =
            "/shop/dirs/" ++ idToString id ++ "/dirs"
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



-- UPDATE


update : String -> Dir -> (Result Http.Error Dir -> msg) -> Cmd msg
update token dir tagger =
    Api.request token
        { method = "PATCH"
        , headers = []
        , url = "/dirs/" ++ idToString dir.id
        , body =
            Http.jsonBody <|
                Json.Encode.object [ ( "name", Json.Encode.string dir.name ) ]
        , expect = Http.expectJson tagger decoder
        , timeout = Nothing
        , tracker = Nothing
        }



-- DIR PATH


dirPath : Id -> Data -> String
dirPath id data =
    dirPathHelp id data ""


dirPathHelp : Id -> Data -> String -> String
dirPathHelp id data path =
    case id of
        Root ->
            if String.isEmpty path then
                "/root"

            else
                "/root/" ++ path

        Sub id_ ->
            case Dict.get (String.fromInt id_) data of
                Just dir ->
                    dirPathHelp dir.dirId data <|
                        String.join "/" [ dir.name, path ]

                Nothing ->
                    ""
