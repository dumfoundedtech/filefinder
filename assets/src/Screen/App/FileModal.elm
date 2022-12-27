module Screen.App.FileModal exposing (Model, Msg, init, update, view)

import Bytes
import Data.Dir
import Data.File
import Dict
import File.Download
import Html
import Html.Attributes
import Html.Events
import Http
import Json.Decode
import Ports
import Session



-- MODEL


type alias Model =
    { session : Session.Session
    , file : Data.File.File
    , state : State
    , message : String
    }


type State
    = Init
    | MoveFile Data.Dir.Id
    | ConfirmDelete
    | Error Http.Error


init : Session.Session -> Data.File.File -> ( Model, Cmd Msg )
init session file =
    ( { session = session
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
    | ClickOk
    | ChangeDir Data.Dir.Id
    | ClickDelete
    | ClickCancel
    | ClickConfirm
    | GotFileBytes (Result Http.Error Bytes.Bytes)
    | GotUpdate (Result Http.Error Data.File.File)
    | GotDelete (Result Http.Error Data.File.File)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ file } as model) =
    case msg of
        ClickCopyUrl ->
            ( { model | message = "Url copied to clipboard!" }
            , Ports.copyToClipboard model.file.url
            )

        ClickDownload ->
            ( { model | message = "File download initiated!" }
            , Data.File.getFileBytes model.file GotFileBytes
            )

        ClickMove ->
            ( { model | message = "", state = MoveFile Data.Dir.initId }
            , Cmd.none
            )

        ClickOk ->
            case model.state of
                MoveFile _ ->
                    ( { model | state = Init }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ChangeDir dirId ->
            case model.state of
                MoveFile _ ->
                    ( { model | state = MoveFile dirId }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ClickDelete ->
            ( { model | message = "", state = ConfirmDelete }, Cmd.none )

        ClickCancel ->
            case model.state of
                ConfirmDelete ->
                    ( { model | state = Init }, Cmd.none )

                MoveFile _ ->
                    ( { model | state = Init }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ClickConfirm ->
            case model.state of
                ConfirmDelete ->
                    ( model
                    , Data.File.delete model.session.token file GotDelete
                    )

                MoveFile dirId ->
                    ( model
                    , Data.File.update model.session.token
                        { file | dirId = dirId }
                        GotUpdate
                    )

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

        GotUpdate result ->
            case model.state of
                MoveFile dirId ->
                    case result of
                        Ok file_ ->
                            ( { model
                                | session =
                                    Session.updateDirId dirId <|
                                        Session.updateFile file_
                                            model.session
                                , file = file_
                                , state = Init
                              }
                            , Ports.toggleModal ()
                            )

                        Err err ->
                            ( { model | state = Error err }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        GotDelete result ->
            case model.state of
                ConfirmDelete ->
                    case result of
                        Ok file_ ->
                            ( { model
                                | session =
                                    Session.removeFile file_
                                        model.session
                                , state = Init
                                , message = "File deleted"
                              }
                            , Cmd.none
                            )

                        Err err ->
                            ( { model | state = Error err }, Cmd.none )

                _ ->
                    ( model, Cmd.none )



-- VIEW


view : Model -> Html.Html Msg
view model =
    case model.state of
        Init ->
            viewInit model

        MoveFile _ ->
            viewMoveFile model

        ConfirmDelete ->
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
                            [ Data.Dir.dirPath model.file.dirId
                                model.session.dirs
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


viewMoveFile : Model -> Html.Html Msg
viewMoveFile model =
    if Dict.isEmpty model.session.dirs then
        Html.div
            [ Html.Attributes.id "modal-content" ]
            [ Html.div [ Html.Attributes.id "modal-banner" ] []
            , Html.div
                [ Html.Attributes.id "modal-move-item" ]
                [ Html.div [ Html.Attributes.id "modal-move-item-select" ]
                    [ Html.text "Please first create some folders!"
                    ]
                , Html.div [ Html.Attributes.id "modal-move-item-actions" ]
                    [ Html.button [ Html.Events.onClick ClickOk ]
                        [ Html.text "Ok" ]
                    ]
                ]
            ]

    else
        Html.div
            [ Html.Attributes.id "modal-content" ]
            [ Html.div [ Html.Attributes.id "modal-banner" ] []
            , Html.div
                [ Html.Attributes.id "modal-move-item" ]
                [ Html.div [ Html.Attributes.id "modal-move-item-select" ]
                    [ Html.text "Select a destination for this file"
                    , Html.select
                        [ Html.Events.on "change" changeDecoder ]
                        (Html.option [ Html.Attributes.value "root" ]
                            [ Html.text "/root" ]
                            :: (List.map (dirSelect model.session.dirs) <|
                                    Dict.toList <|
                                        Dict.filter
                                            (rejectCurrentDir model.file.dirId)
                                            model.session.dirs
                               )
                        )
                    ]
                , Html.div [ Html.Attributes.id "modal-move-item-actions" ]
                    [ Html.button [ Html.Events.onClick ClickCancel ]
                        [ Html.text "Cancel" ]
                    , Html.button
                        [ Html.Attributes.id "modal-move-confirm-action"
                        , Html.Events.onClick ClickConfirm
                        ]
                        [ Html.text "Update" ]
                    ]
                ]
            ]


changeDecoder : Json.Decode.Decoder Msg
changeDecoder =
    Json.Decode.andThen
        (\value ->
            case value of
                "root" ->
                    Json.Decode.succeed <| ChangeDir Data.Dir.initId

                _ ->
                    Json.Decode.succeed <|
                        ChangeDir <|
                            Maybe.withDefault Data.Dir.initId <|
                                Maybe.andThen Data.Dir.idFromInt <|
                                    String.toInt value
        )
        Html.Events.targetValue


dirSelect : Data.Dir.Data -> ( String, Data.Dir.Dir ) -> Html.Html Msg
dirSelect data ( id, dir ) =
    Html.option [ Html.Attributes.value id ]
        [ Html.text <| Data.Dir.dirPath dir.id data ]


rejectCurrentDir : Data.Dir.Id -> String -> Data.Dir.Dir -> Bool
rejectCurrentDir currentDirId id _ =
    id /= Data.Dir.idToString currentDirId
