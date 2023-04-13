module Screen.App.DirModal exposing (Model, Msg, init, update, view)

import Browser.Dom
import Data.Dir
import Dict
import Html
import Html.Attributes
import Html.Events
import Http
import Icons
import Json.Decode
import Ports
import Screen.App.Modal
import Session
import Task



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
    | NewDir String
    | Error Http.Error


init : Session.Session -> Maybe Data.Dir.Dir -> ( Model, Cmd Msg )
init session dir =
    case dir of
        Just dir_ ->
            ( { session = session
              , dir = dir_
              , state = Init
              , message = ""
              }
            , Ports.toggleModal ()
            )

        Nothing ->
            ( { session = session
              , dir =
                    { id = Data.Dir.initId
                    , name = ""
                    , dirId = session.dirId
                    }
              , state = NewDir ""
              , message = ""
              }
            , Ports.toggleModal ()
            )



-- UPDATE


type Msg
    = ClickOpen
    | ClickRename
    | InputName String
    | ClickMove
    | ClickOk
    | ChangeDir Data.Dir.Id
    | ClickDelete
    | ClickCancel
    | ClickConfirm
    | GotDir (Result Http.Error Data.Dir.Dir)
    | DeletedDir (Result Http.Error Data.Dir.Dir)
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ session, dir } as model) =
    case msg of
        ClickOpen ->
            case model.state of
                Init ->
                    ( { model | session = Session.updateDirId dir.id session }
                    , Ports.toggleModal ()
                    )

                _ ->
                    ( model, Cmd.none )

        ClickRename ->
            case model.state of
                Init ->
                    ( { model | message = "", state = RenameDir dir.name }
                    , Task.attempt (\_ -> NoOp)
                        (Browser.Dom.focus "modal-rename-item-input-name")
                    )

                _ ->
                    ( model, Cmd.none )

        InputName name ->
            case model.state of
                RenameDir _ ->
                    ( { model | state = RenameDir name }, Cmd.none )

                NewDir _ ->
                    ( { model | state = NewDir name }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ClickMove ->
            case model.state of
                Init ->
                    ( { model | message = "", state = MoveDir Data.Dir.initId }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        ClickOk ->
            case model.state of
                MoveDir _ ->
                    ( { model | state = Init }, Cmd.none )

                ConfirmDelete ->
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
            case model.state of
                Init ->
                    ( { model | message = "", state = ConfirmDelete }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        ClickCancel ->
            case model.state of
                RenameDir _ ->
                    ( { model | state = Init }, Cmd.none )

                MoveDir _ ->
                    ( { model | state = Init }, Cmd.none )

                ConfirmDelete ->
                    ( { model | state = Init }, Cmd.none )

                NewDir _ ->
                    ( { model | state = Init }, Ports.toggleModal () )

                _ ->
                    ( model, Cmd.none )

        ClickConfirm ->
            case model.state of
                RenameDir name ->
                    ( model
                    , Data.Dir.update session.token { dir | name = name } GotDir
                    )

                MoveDir dirId ->
                    ( model
                    , Data.Dir.update session.token
                        { dir | dirId = dirId }
                        GotDir
                    )

                ConfirmDelete ->
                    ( model
                    , Data.Dir.delete session.token dir DeletedDir
                    )

                NewDir name ->
                    ( model
                    , Data.Dir.create
                        { dirId = session.dirId
                        , name = name
                        , shopId = session.shopId
                        , token = session.token
                        }
                        GotDir
                    )

                _ ->
                    ( model, Cmd.none )

        GotDir result ->
            case result of
                Ok dir_ ->
                    ( { model
                        | session =
                            Session.loadDirs
                                (Data.Dir.appendDir dir_ session.dirs)
                                session
                        , dir = dir_
                        , state = Init
                      }
                    , Ports.toggleModal ()
                    )

                Err err ->
                    ( { model | state = Error err }, Cmd.none )

        DeletedDir result ->
            case result of
                Ok dir_ ->
                    ( { model
                        | session =
                            Session.loadDirs
                                (Data.Dir.removeDir dir_ session.dirs)
                                session
                        , state = Init
                      }
                    , Ports.toggleModal ()
                    )

                Err err ->
                    case err of
                        Http.BadStatus code ->
                            if code == 404 then
                                ( { model
                                    | session =
                                        Session.loadDirs
                                            (Data.Dir.removeDir model.dir
                                                session.dirs
                                            )
                                            session
                                    , state = Init
                                  }
                                , Ports.toggleModal ()
                                )

                            else
                                ( { model | state = Error err }, Cmd.none )

                        _ ->
                            ( { model | state = Error err }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Html.Html Msg
view model =
    case model.state of
        Init ->
            viewInit model

        RenameDir name ->
            viewRenameDir name model

        MoveDir _ ->
            viewMoveDir model

        ConfirmDelete ->
            viewConfirmDelete model

        NewDir name ->
            viewNewDir name

        Error err ->
            Screen.App.Modal.viewError err


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


viewRenameDir : String -> Model -> Html.Html Msg
viewRenameDir name model =
    Html.div
        [ Html.Attributes.id "modal-content" ]
        [ Html.div [ Html.Attributes.id "modal-banner" ] []
        , Html.div
            [ Html.Attributes.id "modal-rename-item" ]
            [ Html.div [ Html.Attributes.id "modal-rename-item-input-field" ]
                [ Html.label []
                    [ Html.text <| "Rename \"" ++ model.dir.name ++ "\"" ]
                , Html.input
                    [ Html.Attributes.id "modal-rename-item-input-name"
                    , Html.Attributes.placeholder "Enter new name"
                    , Html.Attributes.value name
                    , Html.Events.onInput InputName
                    ]
                    []
                ]
            , Html.div [ Html.Attributes.id "modal-rename-item-actions" ]
                [ Html.button [ Html.Events.onClick ClickCancel ]
                    [ Html.text "Cancel" ]
                , Html.button
                    [ Html.Attributes.id "modal-rename-item-confirm-action"
                    , Html.Events.onClick ClickConfirm
                    ]
                    [ Html.text "Update" ]
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
                            [ Html.text "/root" ]
                            :: (List.map (dirSelect model.session.dirs) <|
                                    Dict.toList <|
                                        Dict.filter
                                            (rejectCurrentDir model.dir.id)
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


viewConfirmDelete : Model -> Html.Html Msg
viewConfirmDelete model =
    let
        hasNestedDirs =
            not <|
                Dict.isEmpty <|
                    Dict.filter (\_ dir -> dir.dirId == model.dir.id) <|
                        model.session.dirs

        hasFiles =
            not <|
                Dict.isEmpty <|
                    Dict.filter (\_ file -> file.dirId == model.dir.id) <|
                        model.session.files
    in
    if hasNestedDirs || hasFiles then
        Html.div
            [ Html.Attributes.id "modal-content" ]
            [ Html.div [ Html.Attributes.id "modal-banner" ] []
            , Html.div
                [ Html.Attributes.id "modal-move-item" ]
                [ Html.div [ Html.Attributes.id "modal-move-item-select" ]
                    [ Html.text <|
                        "Warning! This folder is not empty."
                            ++ " Please first move or delete the contents of"
                            ++ " this folder."
                    ]
                , Html.div [ Html.Attributes.id "modal-move-item-actions" ]
                    [ Html.button [ Html.Events.onClick ClickOk ]
                        [ Html.text "Ok" ]
                    ]
                ]
            ]

    else
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
                        , Html.Events.onClick ClickConfirm
                        ]
                        [ Html.text "Delete" ]
                    ]
                ]
            ]


viewNewDir : String -> Html.Html Msg
viewNewDir name =
    Html.div
        [ Html.Attributes.id "modal-content" ]
        [ Html.div [ Html.Attributes.id "modal-banner" ] []
        , Html.div
            [ Html.Attributes.id "modal-create-item" ]
            [ Html.div [ Html.Attributes.id "modal-create-item-input-field" ]
                [ Html.label []
                    [ Html.text <| "Create new folder" ]
                , Html.input
                    [ Html.Attributes.id "modal-create-item-input-name"
                    , Html.Attributes.placeholder "New folder name"
                    , Html.Attributes.value name
                    , Html.Events.onInput InputName
                    ]
                    []
                ]
            , Html.div [ Html.Attributes.id "modal-create-item-actions" ]
                [ Html.button [ Html.Events.onClick ClickCancel ]
                    [ Html.text "Cancel" ]
                , Html.button
                    [ Html.Attributes.id "modal-create-item-confirm-action"
                    , Html.Events.onClick ClickConfirm
                    ]
                    [ Html.text "Create" ]
                ]
            ]
        ]


rejectCurrentDir : Data.Dir.Id -> String -> Data.Dir.Dir -> Bool
rejectCurrentDir currentDirId id _ =
    id /= Data.Dir.idToString currentDirId
