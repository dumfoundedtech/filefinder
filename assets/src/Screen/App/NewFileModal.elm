module Screen.App.NewFileModal exposing (Model, Msg, init, update, view)

import Data.File
import File
import File.Select
import Html
import Html.Attributes
import Html.Events
import Http
import Json.Decode
import Ports
import Session
import Task



-- MODEL


type alias Model =
    { session : Session.Session
    , file : Maybe File.File
    , fileUrl : Maybe String
    , state : State
    }


type State
    = Init
    | Waiting
    | Error Http.Error


init : Session.Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , file = Nothing
      , fileUrl = Nothing
      , state = Init
      }
    , Ports.toggleModal ()
    )



-- UPDATE


type Msg
    = ClickSelectFile
    | GotFile File.File
    | GotFileUrl String
    | ClickCancel
    | ClickUpload
    | GotUpload (Result Http.Error Data.File.File)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickSelectFile ->
            case model.state of
                Init ->
                    ( model, File.Select.file [ "*/*" ] GotFile )

                _ ->
                    ( model, Cmd.none )

        GotFile file ->
            case model.state of
                Init ->
                    ( { model | file = Just file }
                    , Task.perform GotFileUrl <| File.toUrl file
                    )

                _ ->
                    ( model, Cmd.none )

        GotFileUrl url ->
            ( { model | fileUrl = Just url }, Cmd.none )

        ClickCancel ->
            case model.state of
                Init ->
                    ( model, Ports.toggleModal () )

                _ ->
                    ( model, Cmd.none )

        ClickUpload ->
            case model.state of
                Init ->
                    case model.file of
                        Just file ->
                            ( { model | state = Waiting }
                            , Data.File.create
                                model.session.token
                                model.session.dirId
                                file
                                GotUpload
                            )

                        Nothing ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        GotUpload result ->
            case result of
                Ok file ->
                    let
                        session =
                            model.session
                    in
                    ( { model
                        | session =
                            Session.loadFiles
                                (Data.File.addFile file session.files)
                                session
                      }
                    , Ports.toggleModal ()
                    )

                Err err ->
                    ( { model | state = Error err }, Cmd.none )



-- VIEW


view : Model -> Html.Html Msg
view model =
    case model.state of
        Init ->
            let
                maybeBackgroundImage =
                    case model.fileUrl of
                        Just fileUrl ->
                            [ Html.Attributes.style "background-image" <|
                                "url("
                                    ++ fileUrl
                                    ++ ")"
                            ]

                        Nothing ->
                            []
            in
            Html.div [ Html.Attributes.id "modal-content" ]
                [ Html.div [ Html.Attributes.id "modal-banner" ] []
                , Html.div
                    [ Html.Attributes.id "modal-upload" ]
                    [ Html.div [ Html.Attributes.id "modal-upload-input" ]
                        [ Html.text "Upload file"
                        , Html.div
                            (Html.Attributes.id "modal-upload-input-select-file"
                                :: maybeBackgroundImage
                            )
                            [ Html.button
                                [ Html.Attributes.id
                                    "modal-upload-input-select-file-action"
                                , Html.Events.preventDefaultOn "click" <|
                                    Json.Decode.succeed
                                        ( ClickSelectFile, True )
                                ]
                                [ Html.text "Select file" ]
                            ]
                        ]
                    , Html.div [ Html.Attributes.id "modal-upload-actions" ]
                        [ Html.button [ Html.Events.onClick ClickCancel ]
                            [ Html.text "Cancel" ]
                        , Html.button
                            [ Html.Attributes.id
                                "modal-upload-upload-action"
                            , Html.Events.onClick ClickUpload
                            ]
                            [ Html.text "Upload" ]
                        ]
                    ]
                ]

        Waiting ->
            Html.div [ Html.Attributes.id "modal-content" ]
                [ Html.div [ Html.Attributes.id "modal-banner" ] []
                , Html.div
                    [ Html.Attributes.id "modal-upload" ]
                    [ Html.div
                        [ Html.Attributes.id "modal-upload-waiting-message"
                        , Html.Attributes.class "pulsate"
                        ]
                        [ Html.text "Uploading..." ]
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
