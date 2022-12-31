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



-- MODEL


type alias Model =
    { session : Session.Session
    , state : State
    }


type State
    = Init Bool
    | Waiting
    | Error Http.Error


init : Session.Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , state = Init False
      }
    , Ports.toggleModal ()
    )



-- UPDATE


type Msg
    = ClickSelectFiles
    | DragEnter
    | DragLeave
    | GotFiles File.File (List File.File)
    | ClickCancel
    | ClickUpload
    | GotUpload (Result Http.Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickSelectFiles ->
            case model.state of
                Init _ ->
                    ( model, File.Select.files [ "*/*" ] GotFiles )

                _ ->
                    ( model, Cmd.none )

        DragEnter ->
            case model.state of
                Init _ ->
                    ( { model | state = Init True }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        DragLeave ->
            case model.state of
                Init _ ->
                    ( { model | state = Init False }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        GotFiles file files ->
            case model.state of
                Init _ ->
                    ( model
                    , Data.File.create
                        model.session.token
                        model.session.dirId
                        file
                        GotUpload
                    )

                _ ->
                    ( model, Cmd.none )

        ClickCancel ->
            case model.state of
                Init _ ->
                    ( model, Ports.toggleModal () )

                _ ->
                    ( model, Cmd.none )

        ClickUpload ->
            case model.state of
                Init _ ->
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        GotUpload result ->
            case result of
                Ok _ ->
                    -- TODO: handle result
                    ( model, Cmd.none )

                Err err ->
                    ( { model | state = Error err }, Cmd.none )



-- VIEW


view : Model -> Html.Html Msg
view model =
    case model.state of
        Init hover ->
            Html.div [ Html.Attributes.id "modal-content" ]
                [ Html.div [ Html.Attributes.id "modal-banner" ] []
                , Html.form
                    [ Html.Attributes.id "modal-upload" ]
                    [ Html.div [ Html.Attributes.id "modal-upload-input" ]
                        [ Html.text "Upload files"
                        , Html.div
                            [ Html.Attributes.id
                                "modal-upload-input-select-files"
                            , Html.Attributes.class
                                (if hover then
                                    "modal-upload-input-select-files-hover"

                                 else
                                    ""
                                )
                            , Html.Events.preventDefaultOn "dragenter" <|
                                Json.Decode.succeed ( DragEnter, True )
                            , Html.Events.preventDefaultOn "dragover" <|
                                Json.Decode.succeed ( DragEnter, True )
                            , Html.Events.preventDefaultOn "dragleave" <|
                                Json.Decode.succeed ( DragLeave, True )
                            , Html.Events.preventDefaultOn "drop" <|
                                Json.Decode.map (\msg -> ( msg, True )) <|
                                    Json.Decode.at [ "dataTransfer", "files" ]
                                        (Json.Decode.oneOrMore GotFiles
                                            File.decoder
                                        )
                            ]
                            [ Html.button
                                [ Html.Attributes.id
                                    "modal-upload-input-select-files-action"
                                , Html.Events.preventDefaultOn "click" <|
                                    Json.Decode.succeed
                                        ( ClickSelectFiles, True )
                                ]
                                [ Html.text "Select files" ]
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
            Html.div [] []

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
