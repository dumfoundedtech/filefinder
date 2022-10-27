module Screen.App exposing (Model, Msg, init, update, view)

import Data.Dir
import Data.File
import Dict
import Html
import Html.Attributes
import Icons
import Session



-- MODEL


type alias Model =
    { session : Session.Session
    , dirs : Data.Dir.Data
    , files : Data.File.Data
    }


init :
    ( Data.Dir.Data, Data.File.Data )
    -> Session.Session
    -> ( Model, Cmd Msg )
init ( dirs, files ) session =
    ( { session = session
      , dirs = dirs
      , files = files
      }
    , Cmd.none
    )



-- UPDATE


type alias Msg =
    ()


update : Msg -> Model -> ( Model, Cmd Msg )
update _ model =
    ( model, Cmd.none )



-- VIEW


view : Model -> Html.Html Msg
view model =
    Html.section [ Html.Attributes.id "app", Html.Attributes.class "fade-in" ]
        [ viewHeader
        , viewMain model
        , viewFooter
        ]


viewHeader : Html.Html msg
viewHeader =
    Html.header [ Html.Attributes.id "header" ]
        [ Html.h1 []
            [ Html.a [ Html.Attributes.href "/" ] [ Html.text "File Finder" ] ]
        ]


viewMain : Model -> Html.Html Msg
viewMain model =
    let
        dirs =
            List.map Tuple.second <| Dict.toList model.dirs

        files =
            List.map Tuple.second <| Dict.toList model.files
    in
    Html.main_ [ Html.Attributes.id "main" ]
        (List.map viewItem <|
            List.map viewDir dirs
                ++ List.map viewFile files
        )


viewItem : List (Html.Html msg) -> Html.Html msg
viewItem item =
    Html.div [ Html.Attributes.class "item-wrap" ]
        [ Html.div [ Html.Attributes.class "item" ] item ]


viewDir : Data.Dir.Dir -> List (Html.Html msg)
viewDir dir =
    [ Html.div [ Html.Attributes.class "dir" ] [ Icons.dir [] ]
    , Html.div [ Html.Attributes.class "dir-name" ] [ Html.text dir.name ]
    ]


viewFile : Data.File.File -> List (Html.Html msg)
viewFile file =
    [ Html.div [ Html.Attributes.class "file" ]
        [ Html.img [ Html.Attributes.src file.previewUrl ] [] ]
    , Html.div [ Html.Attributes.class "file-name" ] [ Html.text file.name ]
    ]


viewFooter : Html.Html msg
viewFooter =
    Html.div [] []
