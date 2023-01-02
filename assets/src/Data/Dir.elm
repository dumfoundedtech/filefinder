module Data.Dir exposing
    ( Data
    , Dir
    , Id
    , appendDir
    , create
    , delete
    , dirPath
    , getDirShopDirs
    , idDecoder
    , idFromInt
    , idToString
    , initData
    , initId
    , lineage
    , mergeData
    , optionalIdDecoder
    , removeDir
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


mergeData : Data -> Data -> Data
mergeData =
    Dict.union


appendDir : Dir -> Data -> Data
appendDir dir data =
    Dict.insert (idToString dir.id) dir data


removeDir : Dir -> Data -> Data
removeDir dir =
    Dict.remove <| idToString dir.id



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



-- CREATE


create :
    { dirId : Id
    , name : String
    , shopId : Int
    , token : String
    }
    -> (Result Http.Error Dir -> msg)
    -> Cmd msg
create { dirId, name, shopId, token } tagger =
    Api.request token
        { method = "POST"
        , headers = []
        , url = "/dirs"
        , body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "dir"
                      , Json.Encode.object
                            ([ ( "name", Json.Encode.string name )
                             , ( "shop_id", Json.Encode.int shopId )
                             ]
                                ++ encodedDirId dirId
                            )
                      )
                    ]
        , expect = Http.expectJson tagger decoder
        , timeout = Nothing
        , tracker = Nothing
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
                Json.Encode.object
                    [ ( "dir"
                      , Json.Encode.object
                            (( "name", Json.Encode.string dir.name )
                                :: encodedDirId dir.dirId
                            )
                      )
                    ]
        , expect = Http.expectJson tagger decoder
        , timeout = Nothing
        , tracker = Nothing
        }


delete : String -> Dir -> (Result Http.Error Dir -> msg) -> Cmd msg
delete token dir tagger =
    Api.request token
        { method = "DELETE"
        , headers = []
        , url = "/dirs/" ++ idToString dir.id
        , body = Http.emptyBody
        , expect = Http.expectJson tagger decoder
        , timeout = Nothing
        , tracker = Nothing
        }


encodedDirId : Id -> List ( String, Json.Encode.Value )
encodedDirId dirId =
    case dirId of
        Root ->
            [ ( "dir_id", Json.Encode.null ) ]

        Sub id ->
            [ ( "dir_id", Json.Encode.int id ) ]



-- DIR PATH


dirPath : Id -> Data -> String
dirPath id data =
    String.dropRight 1 <|
        dirPathHelp id data ""


dirPathHelp : Id -> Data -> String -> String
dirPathHelp id data path =
    case id of
        Root ->
            if String.isEmpty path then
                "/root/"

            else
                "/root/" ++ path

        Sub id_ ->
            case Dict.get (String.fromInt id_) data of
                Just dir ->
                    dirPathHelp dir.dirId data <|
                        String.join "/" [ dir.name, path ]

                Nothing ->
                    ""



-- LINEAGE


lineage : Id -> Data -> List Dir
lineage id data =
    lineageHelp id data []


lineageHelp : Id -> Data -> List Dir -> List Dir
lineageHelp id data dirs =
    case id of
        Root ->
            { id = Root, name = "root", dirId = Sub 0 } :: dirs

        Sub id_ ->
            case Dict.get (String.fromInt id_) data of
                Just dir ->
                    lineageHelp dir.dirId data <|
                        dir
                            :: dirs

                Nothing ->
                    []
