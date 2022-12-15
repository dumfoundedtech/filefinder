module Screen.App.NewDirModal exposing (Model, Msg, init, update, view)

import Html
import Html.Attributes
import Html.Events
import Http
import Ports
import Session



-- MODEL


type alias Model =
    { session : Session.Session
    , name : String
    , state : State
    }


type State
    = Init
    | Waiting
    | Error Http.Error


init : Session.Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , name = ""
      , state = Init
      }
    , Ports.toggleModal ()
    )



-- UPDATE


type Msg
    = InputName String
    | ClickCancel
    | ClickCreate
    | GotCreate (Result Http.Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputName name ->
            ( { model | name = name }, Cmd.none )

        ClickCancel ->
            ( model, Ports.toggleModal () )

        ClickCreate ->
            -- TODO: create dir
            ( model, Cmd.none )

        GotCreate result ->
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
        Init ->
            Html.div [ Html.Attributes.id "modal-content" ]
                [ Html.div [ Html.Attributes.id "modal-banner" ] []
                , Html.form
                    [ Html.Attributes.id "modal-new-folder" ]
                    [ Html.form [ Html.Attributes.id "modal-new-folder-form" ]
                        [ Html.input
                            [ Html.Attributes.placeholder "Name"
                            , Html.Attributes.type_ "text"
                            , Html.Events.onInput <| InputName
                            ]
                            []
                        ]
                    , Html.div [ Html.Attributes.id "modal-new-folder-actions" ]
                        [ Html.button [ Html.Events.onClick ClickCancel ]
                            [ Html.text "Cancel" ]
                        , Html.button
                            [ Html.Attributes.id
                                "modal-new-folder-create-action"
                            , Html.Events.onClick ClickCreate
                            ]
                            [ Html.text "Create" ]
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
