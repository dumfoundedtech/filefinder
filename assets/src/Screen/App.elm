module Screen.App exposing (Model, Msg, init, update, view)

import Data.Dir
import Data.File
import Dict
import Html
import Html.Attributes
import Html.Events
import Icons
import Json.Decode
import Ports
import Screen.App.DirModal
import Screen.App.FileModal
import Session



-- MODEL


type alias Model =
    { session : Session.Session
    , modal : Modal
    }


type Modal
    = InitModal
    | DirModal Screen.App.DirModal.Model
    | FileModal Screen.App.FileModal.Model


init : Session.Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , modal = InitModal
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = ClickNewFolder
    | ClickUploadFile
    | ClickDir Data.Dir.Dir
    | DoubleClickDir Data.Dir.Dir
    | ClickFile Data.File.File
    | ClickCloseModal
    | DirModalMsg Screen.App.DirModal.Msg
    | FileModalMsg Screen.App.FileModal.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickNewFolder ->
            ( model, Cmd.none )

        ClickUploadFile ->
            ( model, Cmd.none )

        ClickDir dir ->
            routeDirModal model
                (Screen.App.DirModal.init model.session dir)

        DoubleClickDir dir ->
            ( { model | session = Session.updateDirId dir.id model.session }
            , Cmd.none
            )

        ClickFile file ->
            Tuple.mapBoth (\model_ -> { model | modal = FileModal model_ })
                (Cmd.map FileModalMsg)
                (Screen.App.FileModal.init model.session file)

        ClickCloseModal ->
            ( model, Ports.toggleModal () )

        DirModalMsg msg_ ->
            case model.modal of
                DirModal model_ ->
                    routeDirModal model
                        (Screen.App.DirModal.update msg_ model_)

                _ ->
                    ( model, Cmd.none )

        FileModalMsg msg_ ->
            case model.modal of
                FileModal model_ ->
                    routeFileModal model
                        (Screen.App.FileModal.update msg_ model_)

                _ ->
                    ( model, Cmd.none )


routeDirModal :
    Model
    -> ( Screen.App.DirModal.Model, Cmd Screen.App.DirModal.Msg )
    -> ( Model, Cmd Msg )
routeDirModal model =
    Tuple.mapBoth
        (\model_ ->
            { model | modal = DirModal model_, session = model_.session }
        )
        (Cmd.map DirModalMsg)


routeFileModal :
    Model
    -> ( Screen.App.FileModal.Model, Cmd Screen.App.FileModal.Msg )
    -> ( Model, Cmd Msg )
routeFileModal model =
    Tuple.mapBoth
        (\model_ ->
            { model | modal = FileModal model_, session = model_.session }
        )
        (Cmd.map FileModalMsg)



-- VIEW


view : Model -> Html.Html Msg
view model =
    Html.section [ Html.Attributes.id "app", Html.Attributes.class "fade-in" ]
        [ viewHeader
        , viewMain model
        , viewFooter
        , viewModal model
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
            List.map Tuple.second <|
                List.filter (\( _, v ) -> v.dirId == model.session.dirId) <|
                    Dict.toList model.session.dirs

        files =
            List.map Tuple.second <|
                List.filter (\( _, v ) -> v.dirId == model.session.dirId) <|
                    Dict.toList model.session.files
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
            Data.Dir.dirPath model.session.dirId model.session.dirs
                ++ " directory"
        ]


viewItem : Html.Html Msg -> Html.Html Msg
viewItem item =
    Html.div [ Html.Attributes.class "item-wrap" ] [ item ]


viewDir : Data.Dir.Dir -> Html.Html Msg
viewDir dir =
    Html.div
        [ Html.Attributes.class "item"
        , Html.Events.on "click" <|
            Json.Decode.andThen
                (\detail ->
                    if detail < 2 then
                        Json.Decode.succeed <| ClickDir dir

                    else
                        Json.Decode.succeed <| DoubleClickDir dir
                )
                (Json.Decode.field "detail" Json.Decode.int)
        ]
        [ Html.div [ Html.Attributes.class "dir" ] [ Icons.dir [ "dir-icon" ] ]
        , Html.div [ Html.Attributes.class "dir-name" ] [ Html.text dir.name ]
        ]


viewFile : Data.File.File -> Html.Html Msg
viewFile file =
    Html.div
        [ Html.Attributes.class "item"
        , Html.Events.onClick <| ClickFile file
        ]
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
        [ Html.div [ Html.Attributes.id "footer-links" ]
            [ Html.a
                [ Html.Attributes.class "footer-link"
                , Html.Attributes.href "#"
                ]
                [ Html.text "feedback" ]
            , Html.a
                [ Html.Attributes.class "footer-link"
                , Html.Attributes.href "#"
                ]
                [ Html.text "support" ]
            ]
        , Html.div [ Html.Attributes.id "footer-actions" ]
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


viewModal : Model -> Html.Html Msg
viewModal model =
    Html.node "dialog"
        [ Html.Attributes.id "modal" ]
        (Html.div
            [ Html.Attributes.id "modal-close"
            , Html.Events.onClick ClickCloseModal
            ]
            [ Icons.close [ "close-icon" ] ]
            :: viewModalContent model
        )


viewModalContent : Model -> List (Html.Html Msg)
viewModalContent model =
    case model.modal of
        InitModal ->
            []

        DirModal model_ ->
            [ Html.map DirModalMsg <| Screen.App.DirModal.view model_ ]

        FileModal model_ ->
            [ Html.map FileModalMsg <| Screen.App.FileModal.view model_ ]
