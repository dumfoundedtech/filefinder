module Screen.App.FileModal exposing (Model, Msg, init, update, view)

import Data.Dir
import Data.File
import File.Download
import Html
import Html.Attributes
import Html.Events
import Ports
import Session



-- MODEL


type alias Model =
    { session : Session.Session
    , dirs : Data.Dir.Data
    , file : Data.File.File
    , panel : Panel
    }


type Panel
    = InitPanel
    | ConfirmPanel


init : Session.Session -> Data.Dir.Data -> Data.File.File -> ( Model, Cmd Msg )
init session dirs file =
    ( { session = session
      , dirs = dirs
      , file = file
      , panel = InitPanel
      }
    , Ports.toggleModal ()
    )



-- UPDATE


type Msg
    = ClickCopyUrl
    | ClickDownload
    | ClickMove
    | ClickDelete
    | ClickConfirm
    | ClickCancel


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickCopyUrl ->
            ( model, Ports.copyToClipboard model.file.url )

        ClickDownload ->
            ( model, File.Download.url model.file.url )

        ClickMove ->
            ( model, Cmd.none )

        ClickDelete ->
            ( { model | panel = ConfirmPanel }, Cmd.none )

        ClickConfirm ->
            case model.panel of
                ConfirmPanel ->
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ClickCancel ->
            case model.panel of
                ConfirmPanel ->
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )



-- VIEW


view : Model -> Html.Html Msg
view model =
    case model.panel of
        InitPanel ->
            viewInitPanel model

        ConfirmPanel ->
            Html.div [] []


viewInitPanel : Model -> Html.Html Msg
viewInitPanel model =
    Html.div [ Html.Attributes.id "modal-item-wrap" ]
        [ Html.div [ Html.Attributes.class "item" ]
            [ Html.div [ Html.Attributes.class "file-name" ]
                [ Html.text <|
                    String.join "/"
                        [ Data.Dir.dirPath model.file.dirId model.dirs
                        , model.file.name
                        ]
                ]
            , Html.div [ Html.Attributes.class "file" ]
                [ Html.img [ Html.Attributes.src model.file.previewUrl ] [] ]
            ]
        , Html.div [ Html.Attributes.id "modal-item-actions" ]
            [ Html.button [ Html.Events.onClick ClickCopyUrl ]
                [ Html.text "Copy URL" ]
            , Html.button [ Html.Events.onClick ClickDownload ]
                [ Html.text "Download" ]
            , Html.button [ Html.Events.onClick ClickMove ]
                [ Html.text "Move" ]
            , Html.button
                [ Html.Attributes.id "modal-item-delete-action"
                , Html.Events.onClick ClickDelete
                ]
                [ Html.text "Delete" ]
            ]
        ]
