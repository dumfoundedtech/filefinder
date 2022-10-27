module Session exposing (NextScreen(..), Session, decoder)

import Data.Dir
import Data.File
import Http
import Json.Decode



-- SESSION


type alias Session =
    { dirId : Data.Dir.Id
    , shopName : String
    , token : String
    }



-- DECODER


decoder : Json.Decode.Decoder Session
decoder =
    Json.Decode.map3 Session
        (Json.Decode.succeed Data.Dir.initId)
        (Json.Decode.field "shop_name" Json.Decode.string)
        (Json.Decode.field "token" Json.Decode.string)



-- NEXT SCREEN


type NextScreen
    = CurrentScreen
    | AppScreen ( Data.Dir.Data, Data.File.Data )
    | ErrorScreen Http.Error
