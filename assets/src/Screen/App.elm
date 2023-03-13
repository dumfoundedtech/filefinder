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
import Screen.App.NewFileModal
import Screen.App.WelcomeModal
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
    | NewFileModal Screen.App.NewFileModal.Model
    | WelcomeModal Screen.App.WelcomeModal.Model


init : Session.Session -> ( Model, Cmd Msg )
init session =
    if session.showWelcome then
        routeWelcomeModal { session = session, modal = InitModal }
            (Screen.App.WelcomeModal.init session)

    else
        ( { session = session
          , modal = InitModal
          }
        , Cmd.none
        )



-- UPDATE


type Msg
    = ClickBreadcrumb Data.Dir.Dir
    | ClickNewFolder
    | ClickUploadFile
    | ClickDir Data.Dir.Dir
    | DoubleClickDir Data.Dir.Dir
    | ClickFile Data.File.File
    | ClickCloseModal
    | DirModalMsg Screen.App.DirModal.Msg
    | FileModalMsg Screen.App.FileModal.Msg
    | NewFileModalMsg Screen.App.NewFileModal.Msg
    | WelcomeModalMsg Screen.App.WelcomeModal.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ session } as model) =
    case msg of
        ClickBreadcrumb dir ->
            ( { model | session = Session.updateDirId dir.id session }
            , Cmd.none
            )

        ClickNewFolder ->
            routeDirModal model
                (Screen.App.DirModal.init session Nothing)

        ClickUploadFile ->
            routeNewFileModal model
                (Screen.App.NewFileModal.init session)

        ClickDir dir ->
            routeDirModal model
                (Screen.App.DirModal.init session <| Just dir)

        DoubleClickDir dir ->
            ( { model | session = Session.updateDirId dir.id session }
            , Cmd.none
            )

        ClickFile file ->
            Tuple.mapBoth (\model_ -> { model | modal = FileModal model_ })
                (Cmd.map FileModalMsg)
                (Screen.App.FileModal.init session file)

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

        NewFileModalMsg msg_ ->
            case model.modal of
                NewFileModal model_ ->
                    routeNewFileModal model
                        (Screen.App.NewFileModal.update msg_ model_)

                _ ->
                    ( model, Cmd.none )

        WelcomeModalMsg msg_ ->
            case model.modal of
                WelcomeModal model_ ->
                    routeWelcomeModal model
                        (Screen.App.WelcomeModal.update msg_ model_)

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


routeNewFileModal :
    Model
    -> ( Screen.App.NewFileModal.Model, Cmd Screen.App.NewFileModal.Msg )
    -> ( Model, Cmd Msg )
routeNewFileModal model =
    Tuple.mapBoth
        (\model_ ->
            { model | modal = NewFileModal model_, session = model_.session }
        )
        (Cmd.map NewFileModalMsg)


routeWelcomeModal :
    Model
    -> ( Screen.App.WelcomeModal.Model, Cmd Screen.App.WelcomeModal.Msg )
    -> ( Model, Cmd Msg )
routeWelcomeModal model =
    Tuple.mapBoth
        (\model_ ->
            { model | modal = WelcomeModal model_, session = model_.session }
        )
        (Cmd.map WelcomeModalMsg)



-- VIEW


view : Model -> Html.Html Msg
view model =
    Html.section [ Html.Attributes.id "app", Html.Attributes.class "fade-in" ]
        [ viewHeader model
        , viewMain model
        , viewFooter
        , viewModal model
        ]


viewHeader : Model -> Html.Html msg
viewHeader model =
    Html.header [ Html.Attributes.id "header" ]
        [ Html.h1 []
            [ Html.a [ Html.Attributes.href "/" ] [ Html.text "File Finder" ] ]
        , Html.a
            [ Html.Attributes.id "shop-link"
            , Html.Attributes.href <|
                "https://"
                    ++ model.session.shopName
                    ++ "/admin"
            , Html.Attributes.target "_blank"
            ]
            [ Html.text model.session.shopName
            , Icons.externalLink [ "external-link" ]
            ]
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

        items =
            List.map viewDir dirs ++ List.map viewFile files
    in
    Html.main_ [ Html.Attributes.id "main" ]
        (viewInfoBar model
            :: (if List.isEmpty items then
                    [ Html.div [ Html.Attributes.id "empty-items" ]
                        [ Html.p [ Html.Attributes.id "empty-items-message" ]
                            [ Html.text "Let's get started!" ]
                        , Html.div [ Html.Attributes.id "empty-items-actions" ]
                            [ Html.button [ Html.Events.onClick ClickNewFolder ]
                                [ Icons.add [ "button-icon" ]
                                , Html.text "New Folder"
                                ]
                            , Html.button
                                [ Html.Events.onClick ClickUploadFile ]
                                [ Icons.cloud [ "button-icon" ]
                                , Html.text "Upload File"
                                ]
                            ]
                        ]
                    ]

                else
                    List.map viewItem items
               )
        )


viewInfoBar : Model -> Html.Html Msg
viewInfoBar model =
    let
        dirs =
            Data.Dir.lineage model.session.dirId model.session.dirs

        seperator =
            Html.text "/"

        toBreadcrumb dir =
            Html.a
                [ Html.Attributes.class "breadcrumb"
                , Html.Attributes.href "#"
                , Html.Events.preventDefaultOn "click" <|
                    Json.Decode.succeed ( ClickBreadcrumb dir, True )
                ]
                [ Html.text dir.name ]

        breadCrumbs =
            case List.reverse dirs of
                h :: t ->
                    List.intersperse seperator <|
                        List.reverse <|
                            Html.span [ Html.Attributes.class "breadcrumb" ]
                                [ Html.text h.name ]
                                :: List.map toBreadcrumb t

                [] ->
                    []
    in
    Html.div [ Html.Attributes.id "info-bar" ] (seperator :: breadCrumbs)


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
                , Html.Attributes.href "https://airtable.com/shrgO1BM953fSeUcA"
                , Html.Attributes.target "_blank"
                ]
                [ Html.text "feedback"
                , Icons.externalLink [ "external-link" ]
                ]
            , Html.a
                [ Html.Attributes.class "footer-link"
                , Html.Attributes.href "https://airtable.com/shrBOnyZE2bORcTJy"
                , Html.Attributes.target "_blank"
                ]
                [ Html.text "support"
                , Icons.externalLink [ "external-link" ]
                ]
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

        NewFileModal model_ ->
            [ Html.map NewFileModalMsg <| Screen.App.NewFileModal.view model_ ]

        WelcomeModal model_ ->
            [ Html.map WelcomeModalMsg <| Screen.App.WelcomeModal.view model_ ]
