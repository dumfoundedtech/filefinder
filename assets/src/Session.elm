module Session exposing
    ( NextScreen(..)
    , Session
    , decoder
    , loadDirs
    , loadFiles
    , updateDir
    , updateFile
    )

import Data.Dir
import Data.File
import Dict
import Http
import Json.Decode



-- SESSION


type alias Session =
    { dirId : Data.Dir.Id
    , dirs : Data.Dir.Data
    , files : Data.File.Data
    , shopName : String
    , token : String
    }



-- DECODER


decoder : Json.Decode.Decoder Session
decoder =
    Json.Decode.map5 Session
        (Json.Decode.succeed Data.Dir.initId)
        (Json.Decode.succeed Data.Dir.initData)
        (Json.Decode.succeed Data.File.initData)
        (Json.Decode.field "shop_name" Json.Decode.string)
        (Json.Decode.field "token" Json.Decode.string)



-- DATA


loadDirs : Data.Dir.Data -> Session -> Session
loadDirs dirs session =
    { session | dirs = dirs }


loadFiles : Data.File.Data -> Session -> Session
loadFiles files session =
    { session | files = files }


updateDir : Data.Dir.Dir -> Session -> Session
updateDir dir session =
    let
        dirs =
            Dict.update (Data.Dir.idToString dir.id)
                (Maybe.andThen (\_ -> Just dir))
                session.dirs
    in
    { session | dirs = dirs }


updateFile : Data.File.File -> Session -> Session
updateFile file session =
    let
        files =
            Dict.update file.id (Maybe.andThen (\_ -> Just file)) session.files
    in
    { session | files = files }



-- NEXT SCREEN


type NextScreen
    = CurrentScreen
    | AppScreen
    | ErrorScreen Http.Error
