module Screen.App.DirModal exposing (Model, Msg, init, update, view)

import Data.Dir
import Dict
import Html
import Html.Attributes
import Html.Events
import Http
import Icons
import Json.Decode
import Ports
import Session



-- MODEL


type alias Model =
    { session : Session.Session
    , dir : Data.Dir.Dir
    , state : State
    , message : String
    }


type State
    = Init
    | RenameDir String
    | MoveDir Data.Dir.Id
    | ConfirmDelete
    | Error Http.Error


init : Session.Session -> Data.Dir.Dir -> ( Model, Cmd Msg )
init session dir =
    ( { session = session
      , dir = dir
      , state = Init
      , message = ""
      }
    , Ports.toggleModal ()
    )



-- UPDATE


type Msg
    = ClickOpen
    | ClickRename
    | ClickMove
    | ClickOk
    | ChangeDir Data.Dir.Id
    | ClickDelete
    | ClickCancel
    | ClickConfirm


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickOpen ->
            ( { model
                | session = Session.updateDirId model.dir.id model.session
              }
            , Ports.toggleModal ()
            )

        ClickRename ->
            ( { model | message = "", state = RenameDir "" }, Cmd.none )

        ClickMove ->
            ( { model | message = "", state = MoveDir Data.Dir.initId }
            , Cmd.none
            )

        ClickOk ->
            case model.state of
                MoveDir _ ->
                    ( { model | state = Init }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ChangeDir dirId ->
            case model.state of
                MoveDir _ ->
                    ( { model | state = MoveDir dirId }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ClickDelete ->
            ( { model | message = "", state = ConfirmDelete }, Cmd.none )

        ClickCancel ->
            case model.state of
                RenameDir _ ->
                    ( { model | state = Init }, Cmd.none )

                MoveDir _ ->
                    ( { model | state = Init }, Cmd.none )

                ConfirmDelete ->
                    ( { model | state = Init }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ClickConfirm ->
            case model.state of
                RenameDir _ ->
                    -- TODO
                    ( { model | state = Init }, Cmd.none )

                MoveDir _ ->
                    -- TODO
                    ( { model | state = Init }, Cmd.none )

                ConfirmDelete ->
                    -- TODO
                    ( { model | state = Init }, Cmd.none )

                _ ->
                    ( model, Cmd.none )



-- VIEW


view : Model -> Html.Html Msg
view model =
    case model.state of
        Init ->
            viewInit model

        RenameDir _ ->
            Html.div [] []

        MoveDir _ ->
            viewMoveDir model

        ConfirmDelete ->
            viewConfirmDelete

        Error err ->
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
                [ Html.div [ Html.Attributes.class "dir" ]
                    [ Icons.dir [ "dir-icon" ] ]
                , Html.div [ Html.Attributes.class "dir-name" ]
                    [ Html.text <|
                        String.join "/"
                            [ Data.Dir.dirPath model.dir.dirId
                                model.session.dirs
                            , model.dir.name
                            ]
                    ]
                ]
            , Html.div [ Html.Attributes.id "modal-item-actions" ]
                [ Html.button [ Html.Events.onClick ClickOpen ]
                    [ Html.text "Open" ]
                , Html.button [ Html.Events.onClick ClickRename ]
                    [ Html.text "Rename" ]
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


viewMoveDir : Model -> Html.Html Msg
viewMoveDir model =
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
                    [ Html.text "Select a destination for this folder"
                    , Html.select
                        [ Html.Events.on "change" changeDecoder ]
                        (Html.option [ Html.Attributes.value "root" ]
                            -- TODO: remove self from list
                            [ Html.text "/root" ]
                            :: (List.map (dirSelect model.session.dirs) <|
                                    Dict.toList model.session.dirs
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


viewConfirmDelete : Html.Html Msg
viewConfirmDelete =
    -- TODO: only delete on empty
    Html.div [ Html.Attributes.id "modal-content" ]
        [ Html.div [ Html.Attributes.id "modal-banner" ] []
        , Html.div
            [ Html.Attributes.id "modal-confirm" ]
            [ Html.div [ Html.Attributes.id "modal-confirm-message" ]
                [ Html.text
                    "Are you sure you want to delete this folder?"
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
