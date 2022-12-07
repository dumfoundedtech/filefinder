module Screen.App.FileModal exposing (Model, Msg, init, update, view)

import Bytes
import Data.Dir
import Data.File
import File.Download
import Html
import Html.Attributes
import Html.Events
import Http
import Ports
import Session



-- MODEL


type alias Model =
    { session : Session.Session
    , dirs : Data.Dir.Data
    , file : Data.File.File
    , state : State
    , message : String
    }


type State
    = Init
    | ConfirmDelete
    | Error Http.Error


init : Session.Session -> Data.Dir.Data -> Data.File.File -> ( Model, Cmd Msg )
init session dirs file =
    ( { session = session
      , dirs = dirs
      , file = file
      , state = Init
      , message = ""
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
    | GotFileBytes (Result Http.Error Bytes.Bytes)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickCopyUrl ->
            ( { model | message = "Url copied to clipboard!" }
            , Ports.copyToClipboard model.file.url
            )

        ClickDownload ->
            ( model, Data.File.getFileBytes model.file GotFileBytes )

        ClickMove ->
            -- TODO: move
            ( model, Cmd.none )

        ClickDelete ->
            ( { model | state = ConfirmDelete }, Cmd.none )

        ClickConfirm ->
            case model.state of
                ConfirmDelete ->
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ClickCancel ->
            case model.state of
                ConfirmDelete ->
                    -- TODO: delete
                    ( { model | state = Init }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        GotFileBytes result ->
            case result of
                Ok bytes ->
                    ( model
                    , File.Download.bytes model.file.name
                        model.file.mimeType
                        bytes
                    )

                Err err ->
                    ( { model | state = Error err }, Cmd.none )



-- VIEW


view : Model -> Html.Html Msg
view model =
    case model.state of
        Init ->
            viewInit model

        ConfirmDelete ->
            -- TODO: finish confirm delete view
            Html.div [ Html.Attributes.id "modal-content" ]
                [ Html.div [ Html.Attributes.id "modal-banner" ] []
                , Html.div
                    [ Html.Attributes.id "modal-confirm" ]
                    [ Html.div [ Html.Attributes.id "modal-confirm-message" ]
                        [ Html.text
                            "Are you sure you want to delete this file?"
                        ]
                    , Html.div [ Html.Attributes.id "modal-confirm-actions" ]
                        [ Html.button [ Html.Events.onClick ClickCancel ]
                            [ Html.text "Cancel" ]
                        , Html.button
                            [ Html.Attributes.id "modal-confirm-delete-action"
                            ]
                            [ Html.text "Delete" ]
                        ]
                    ]
                ]

        Error err ->
            -- TODO: finish error view
            let
                message =
                    case err of
                        Http.BadUrl url ->
                            url ++ " is invalid"

                        Http.Timeout ->
                            "Hit network timeout"

                        Http.NetworkError ->
                            "Hit network error"

                        Http.BadStatus code ->
                            String.fromInt code ++ " status code"

                        Http.BadBody message_ ->
                            message_
            in
            Html.pre [] [ Html.text message ]


viewInit : Model -> Html.Html Msg
viewInit model =
    Html.div [ Html.Attributes.id "modal-content" ]
        [ Html.div [ Html.Attributes.id "modal-banner" ]
            [ Html.text model.message ]
        , Html.div [ Html.Attributes.id "modal-item-wrap" ]
            [ Html.div [ Html.Attributes.class "item" ]
                [ Html.div [ Html.Attributes.class "file" ]
                    [ Html.img [ Html.Attributes.src model.file.previewUrl ] [] ]
                , Html.div [ Html.Attributes.class "file-name" ]
                    [ Html.text <|
                        String.join "/"
                            [ Data.Dir.dirPath model.file.dirId model.dirs
                            , model.file.name
                            ]
                    ]
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
        ]
