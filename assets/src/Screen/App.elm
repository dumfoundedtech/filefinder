module Screen.App exposing (Model, Msg, init, update, view)

import Data.Dir
import Data.File
import Dict
import Html
import Html.Attributes
import Html.Events
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


type Msg
    = ClickNewFolder
    | ClickUploadFile


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickNewFolder ->
            ( model, Cmd.none )

        ClickUploadFile ->
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
        (viewInfoBar model
            :: (List.map viewItem <|
                    List.map viewDir dirs
                        ++ List.map viewFile files
               )
        )


viewInfoBar : Model -> Html.Html msg
viewInfoBar model =
    Html.div [ Html.Attributes.id "info-bar" ]
        [ Html.text <|
            Data.Dir.dirPath model.session.dirId model.dirs
                ++ " directory"
        ]


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
    , Html.div
        [ Html.Attributes.class "file-name"
        , Html.Attributes.title file.name
        ]
        [ Html.text file.name ]
    ]


viewFooter : Html.Html Msg
viewFooter =
    Html.footer [ Html.Attributes.id "footer" ]
        [ Html.div [ Html.Attributes.id "footer-actions" ]
            [ Html.button [ Html.Events.onClick ClickNewFolder ]
                [ Icons.add [ "button-icon" ]
                , Html.text "New Folder"
                ]
            , Html.button [ Html.Events.onClick ClickUploadFile ]
                [ Icons.cloud [ "button-icon" ]
                , Html.text "Upload File"
                ]
            ]
        ]
