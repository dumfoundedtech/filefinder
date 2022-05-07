port module Main exposing (main)

import Browser
import Browser.Events
import Dict
import Html
import Html.Attributes
import Html.Events
import Http
import Icons
import Json.Decode



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- PORTS


port copyToClipboard : String -> Cmd msg



-- MODEL


type alias Model =
    { dirId : DirId
    , dirs : Dict.Dict Int Dir
    , files : Dict.Dict String File
    , action : Action
    }


type DirId
    = Root
    | Sub Int


type alias Dir =
    { id : DirId
    , name : String
    , dirId : DirId
    }


type FileId
    = FileId String


type alias File =
    { id : FileId
    , name : String
    , preview : String
    , url : String
    , dirId : DirId
    }


type Action
    = NewFolder String
    | Upload
    | Select Content
    | CopyUrl String
    | Rename Content String
    | Move Content DirId
    | NoAction


type Content
    = DirContent Dir
    | FileContent File


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model Root
        (Dict.fromList [ ( 1, Dir (Sub 1) "Images" Root ) ])
        (Dict.fromList
            [ ( "gid://shopify/File/1"
              , File (FileId "gid://shopify/File/1") "test.txt" "https://cdn.shopify.com/shopifycloud/web/assets/v1/ca92d373afb727d826d4ad514094e4c9c7537d49c6268ac407506b17b0723dd8.svg" "" Root
              )
            , ( "gid://shopify/File/2"
              , File (FileId "gid://shopify/File/2") "image.png" "https://cdn.fstoppers.com/styles/full/s3/media/2019/12/04/nando-jpeg-quality-006-too-much.jpg" "" (Sub 1)
              )
            , ( "gid://shopify/File/3"
              , File (FileId "gid://shopify/File/3") "image2.png" "https://cdn.shopify.com/s/files/1/0591/9093/5706/files/Photo_on_3-17-21_at_16.18_2.jpg?v=1646359388" "" Root
              )
            ]
        )
        NoAction
    , Cmd.none
    )



-- UPDATE


type Msg
    = ClickPathLink DirId
    | ClickNewFolder
    | ClickUpload
    | ClickContent Content
    | ClickOpen Dir
    | ClickCopyUrl File
    | ClickRename Content
    | ClickMove Content
    | ClickSave Content
    | ClickCancel
    | GotDirSave (Result Http.Error DirId)
    | GotFileSave (Result Http.Error FileId)
    | InputName String
    | PressEnter
    | PressEscape
    | DoubleClickDir DirId
    | ClickOut
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickPathLink dirId ->
            ( { model | dirId = dirId }, Cmd.none )

        ClickNewFolder ->
            ( { model | action = NewFolder "" }, Cmd.none )

        ClickUpload ->
            ( { model | action = Upload }, Cmd.none )

        ClickContent content ->
            ( { model | action = Select content }, Cmd.none )

        ClickOpen { id } ->
            ( { model | dirId = id }, Cmd.none )

        ClickCopyUrl { url } ->
            ( { model | action = CopyUrl url }, copyToClipboard url )

        ClickRename content ->
            case content of
                DirContent { name } ->
                    ( { model | action = Rename content name }, Cmd.none )

                FileContent { name } ->
                    ( { model | action = Rename content name }, Cmd.none )

        ClickMove content ->
            ( { model | action = Move content model.dirId }, Cmd.none )

        ClickSave _ ->
            case model.action of
                NewFolder name ->
                    -- TODO: send to server
                    ( model, Cmd.none )

                Rename content name ->
                    case content of
                        DirContent { id } ->
                            renameDir id name model

                        FileContent { id } ->
                            renameFile id name model

                Move content dirId ->
                    -- TODO: send to server
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ClickCancel ->
            ( { model | action = NoAction }, Cmd.none )

        GotDirSave _ ->
            ( model, Cmd.none )

        GotFileSave _ ->
            ( model, Cmd.none )

        InputName name ->
            case model.action of
                Rename content _ ->
                    ( { model | action = Rename content name }, Cmd.none )

                NewFolder _ ->
                    ( { model | action = NewFolder name }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        PressEnter ->
            -- TODO: PressEnter
            ( model, Cmd.none )

        PressEscape ->
            -- TODO: PressEscape
            ( model, Cmd.none )

        DoubleClickDir id ->
            ( { model | dirId = id }, Cmd.none )

        ClickOut ->
            -- TODO: ClickOut
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


renameDir : DirId -> String -> Model -> ( Model, Cmd Msg )
renameDir id name model =
    case id of
        Sub id_ ->
            -- TODO: send to server
            ( { model
                | action = NoAction
                , dirs =
                    Dict.update id_
                        (Maybe.map (\dir -> { dir | name = name }))
                        model.dirs
              }
            , Cmd.none
            )

        _ ->
            ( model, Cmd.none )


renameFile : FileId -> String -> Model -> ( Model, Cmd Msg )
renameFile (FileId id) name model =
    -- TODO: send to server
    ( { model
        | action = NoAction
        , files =
            Dict.update id
                (Maybe.map (\file -> { file | name = name }))
                model.files
      }
    , Cmd.none
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        bodyClick =
            case model.action of
                NoAction ->
                    Sub.none

                _ ->
                    Browser.Events.onClick (Json.Decode.succeed ClickOut)

        keyDown =
            Browser.Events.onKeyDown <|
                Json.Decode.andThen
                    (\key ->
                        case key of
                            "Enter" ->
                                Json.Decode.succeed PressEnter

                            "Escape" ->
                                Json.Decode.succeed PressEscape

                            "Esc" ->
                                Json.Decode.succeed PressEscape

                            _ ->
                                Json.Decode.succeed NoOp
                    )
                    (Json.Decode.field "key" Json.Decode.string)
    in
    Sub.batch [ bodyClick, keyDown ]



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title =
        String.join " / " <|
            "file finder"
                :: (List.map (String.toLower << Tuple.second) <|
                        path model.dirId model.dirs
                   )
    , body =
        [ viewHeader model
        , viewMain model
        ]
            ++ maybeModal model
            ++ [ viewFooter ]
    }



-- VIEW HEADER


viewHeader : Model -> Html.Html Msg
viewHeader model =
    Html.node "header"
        [ Html.Attributes.class
            "border-b-2 border-sky-600 flex h-20 items-center px-8"
        ]
        (viewHeaderLinks model)


viewHeaderLinks : Model -> List (Html.Html Msg)
viewHeaderLinks model =
    let
        baseClass =
            "font-bold lowercase mr-2 text-xl tracking-wider"

        linkClass =
            baseClass ++ " cursor-pointer text-sky-600"

        textClass =
            baseClass ++ " text-slate-500"

        rootLink =
            Html.h1
                [ Html.Attributes.class linkClass
                , Html.Events.onClick <| ClickPathLink Root
                ]
                [ Html.text "File Finder" ]

        parentLink ( id, dir ) =
            Html.h2
                [ Html.Attributes.class linkClass
                , Html.Events.onClick <| ClickPathLink id
                ]
                [ Html.text dir ]

        separator =
            Html.span
                [ Html.Attributes.class "font-bold mr-2 text-sky-600 text-xl" ]
                [ Html.text "/" ]
    in
    case List.reverse <| path model.dirId model.dirs of
        current :: parents ->
            List.intersperse separator <|
                rootLink
                    :: (List.map parentLink <| List.reverse parents)
                    ++ [ Html.h2
                            [ Html.Attributes.class textClass ]
                            [ Html.text <| Tuple.second current ]
                       ]

        _ ->
            [ rootLink ]


path : DirId -> Dict.Dict Int Dir -> List ( DirId, String )
path dirId dirs =
    case dirId of
        Root ->
            []

        Sub id ->
            case Dict.get id dirs of
                Just dir ->
                    path dir.dirId dirs ++ [ ( dir.id, dir.name ) ]

                Nothing ->
                    []



-- VIEW MAIN


viewMain : Model -> Html.Html Msg
viewMain model =
    Html.node "main"
        [ Html.Attributes.class
            "flex justify-between"
        , Html.Attributes.style "min-height" "calc(100vh - 176px)"
        ]
        [ Html.div [ Html.Attributes.class "flex flex-wrap select-none" ]
            (List.map (viewContent model) <| contents model)
        , viewSidebar model
        ]


viewContent : Model -> Content -> Html.Html Msg
viewContent model content =
    let
        ( contentClass, nameClass ) =
            contentClasses model content
    in
    Html.div [ Html.Attributes.class "p-4" ]
        [ Html.div
            [ Html.Attributes.class contentClass
            , Html.Events.stopPropagationOn "click" <|
                Json.Decode.succeed ( ClickContent content, True )
            ]
            [ viewContentPreview content
            , Html.div [ Html.Attributes.class nameClass ]
                [ viewContentName model content ]
            ]
        ]


contentClasses : Model -> Content -> ( String, String )
contentClasses { action } content =
    let
        baseContentClass =
            "flex flex-col items-center justify-end p-4 rounded-lg"

        defaultClasses =
            ( baseContentClass, "text-slate-900" )

        activeClasses =
            ( "bg-sky-600 " ++ baseContentClass, "text-white" )

        mapClasses content_ id =
            if id == content_.id then
                activeClasses

            else
                defaultClasses
    in
    case ( content, action ) of
        ( DirContent dir, Select (DirContent { id }) ) ->
            mapClasses dir id

        ( DirContent dir, Rename (DirContent { id }) _ ) ->
            mapClasses dir id

        ( FileContent dir, Select (FileContent { id }) ) ->
            mapClasses dir id

        ( FileContent dir, Rename (FileContent { id }) _ ) ->
            mapClasses dir id

        _ ->
            defaultClasses


viewContentPreview : Content -> Html.Html Msg
viewContentPreview content =
    case content of
        DirContent dir ->
            Html.div
                [ Html.Attributes.class "h-60 w-60"
                , Html.Events.onDoubleClick <| DoubleClickDir dir.id
                ]
                [ Icons.dir [ "fill-sky-400" ] ]

        FileContent file ->
            Html.div [ Html.Attributes.class "h-60 p-8 w-60" ]
                [ Html.img
                    [ Html.Attributes.alt file.name
                    , Html.Attributes.class "h-full object-contain w-full"
                    , Html.Attributes.draggable "false"
                    , Html.Attributes.src file.preview
                    ]
                    []
                ]


viewContentName : Model -> Content -> Html.Html Msg
viewContentName { action } content =
    case ( content, action ) of
        ( DirContent dir, Rename (DirContent { id }) name ) ->
            if id == dir.id then
                viewNameInput name

            else
                Html.text dir.name

        ( DirContent dir, _ ) ->
            Html.text dir.name

        ( FileContent file, Rename (FileContent { id }) name ) ->
            if id == file.id then
                viewNameInput name

            else
                Html.text file.name

        ( FileContent file, _ ) ->
            Html.text file.name


viewNameInput : String -> Html.Html Msg
viewNameInput name =
    Html.input
        [ Html.Attributes.autofocus True
        , Html.Attributes.class "text-slate-900"
        , Html.Attributes.type_ "text"
        , Html.Attributes.value name
        , Html.Events.onInput InputName
        ]
        []


contents : Model -> List Content
contents model =
    let
        dirs =
            List.map DirContent <|
                Dict.values <|
                    Dict.filter (\_ dir -> inDirectory model.dirId dir)
                        model.dirs

        files =
            List.map FileContent <|
                Dict.values <|
                    Dict.filter (\_ file -> inDirectory model.dirId file)
                        model.files
    in
    dirs ++ files


inDirectory : DirId -> { a | dirId : DirId } -> Bool
inDirectory dirId content =
    case ( dirId, content.dirId ) of
        ( Root, Root ) ->
            True

        ( Sub a, Sub b ) ->
            a == b

        _ ->
            False


viewSidebar : Model -> Html.Html Msg
viewSidebar model =
    let
        baseClass =
            "bg-gray-100 duration-100 overflow-y-hidden transition-all"

        class =
            case model.action of
                NoAction ->
                    baseClass ++ " w-0"

                _ ->
                    baseClass ++ " w-96"
    in
    Html.div
        [ Html.Attributes.class class
        , Html.Attributes.style "max-height" "calc(100vh - 176px)"
        ]
        (case model.action of
            Select content ->
                [ viewSidebarContent content ]

            Rename content name ->
                [ viewSidebarContent content ]

            _ ->
                []
        )


viewSidebarContent : Content -> Html.Html Msg
viewSidebarContent content =
    let
        ( contentName, contentPreview ) =
            case content of
                DirContent { name } ->
                    ( name
                    , Html.div [ Html.Attributes.class "h-52 my-4 w-52" ]
                        [ Icons.dir [ "fill-sky-400" ] ]
                    )

                FileContent { name, preview } ->
                    ( name
                    , Html.div [ Html.Attributes.class "h-52 my-4 w-52" ]
                        [ Html.img
                            [ Html.Attributes.alt name
                            , Html.Attributes.class
                                "h-full object-contain w-full"
                            , Html.Attributes.draggable "false"
                            , Html.Attributes.src preview
                            ]
                            []
                        ]
                    )

        buttonBaseClass =
            "border-2 font-bold mb-2 p-2 rounded"

        buttonClass =
            "border-sky-600 text-sky-600 " ++ buttonBaseClass

        deleteButtonClass =
            "border-rose-400 text-rose-400 " ++ buttonBaseClass

        firstButton =
            case content of
                DirContent _ ->
                    Html.button [ Html.Attributes.class buttonClass ] [ Html.text "Open" ]

                FileContent _ ->
                    Html.button [ Html.Attributes.class buttonClass ] [ Html.text "Copy URL" ]
    in
    Html.div [ Html.Attributes.class "flex flex-col px-8 py-12" ]
        [ Html.h2
            [ Html.Attributes.class
                "font-bold text-sky-600 tracking-wide w-full"
            ]
            [ Html.text contentName ]
        , contentPreview
        , Html.div [ Html.Attributes.class "flex flex-col" ]
            [ firstButton
            , Html.button
                [ Html.Attributes.class buttonClass
                , Html.Events.stopPropagationOn "click" <|
                    Json.Decode.succeed ( ClickRename content, True )
                ]
                [ Html.text "Rename" ]
            , Html.button [ Html.Attributes.class buttonClass ]
                [ Html.text "Move" ]
            , Html.button [ Html.Attributes.class deleteButtonClass ]
                [ Html.text "Delete" ]
            ]
        ]



-- MAYBE MODAL


maybeModal : Model -> List (Html.Html Msg)
maybeModal model =
    case model.action of
        NewFolder name ->
            [ Html.div
                [ Html.Attributes.class
                    "absolute bg-sky-600/50 flex h-full items-center justify-center left-0 top-0 w-full z-10"
                ]
                [ Html.div
                    [ Html.Attributes.class
                        "bg-gray-100 h-3/4 m-auto p-8 rounded-lg w-2/5"
                    ]
                    [ Html.div
                        [ Html.Attributes.class
                            "flex justify-center items-center h-full w-full"
                        ]
                        [ Html.div [ Html.Attributes.class "flex flex-col justify-between h-full w-full" ]
                            [ Html.div [ Html.Attributes.class "font-bold text-center text-2xl" ] [ Html.text "New Folder" ]
                            , Html.div [ Html.Attributes.class "m-auto w-48" ] [ Icons.dir [ "fill-sky-400" ] ]
                            , Html.div [ Html.Attributes.class "mb-8 mx-auto" ]
                                [ Html.input
                                    [ Html.Attributes.class "p-2 rounded w-full"
                                    , Html.Attributes.type_ "text"
                                    , Html.Attributes.value name
                                    , Html.Events.onInput InputName
                                    ]
                                    []
                                ]
                            , Html.div [ Html.Attributes.class "flex h-12 justify-around mx-auto w-1/2" ]
                                [ Html.button [ Html.Attributes.class "border-2 border-sky-600 bg-sky-600 flex justify-center p-2 rounded-lg w-12" ]
                                    [ Icons.check [ "fill-white w-6" ] ]
                                , Html.button [ Html.Attributes.class "border-2 border-rose-400 flex justify-center p-2 rounded w-12" ]
                                    [ Icons.close [ "fill-rose-400 font-bold w-6" ] ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]

        _ ->
            []



-- VIEW FOOTER


viewFooter : Html.Html Msg
viewFooter =
    let
        iconClasses =
            [ "align-bottom"
            , "fill-sky-600"
            , "inline"
            , "mr-2"
            , "w-6"
            ]
    in
    Html.node "footer"
        [ Html.Attributes.class
            "bg-sky-600 fixed flex h-24 justify-end w-full"
        ]
        [ Html.div
            [ Html.Attributes.class
                "flex my-auto justify-between px-8 w-96"
            ]
            [ footerButton
                (Html.Events.stopPropagationOn "click" <|
                    Json.Decode.succeed ( ClickNewFolder, True )
                )
                [ Icons.add iconClasses, Html.text "New Folder" ]
            , footerButton (Html.Events.onClick NoOp)
                [ Icons.cloud iconClasses, Html.text "Upload File" ]
            ]
        ]


footerButton : Html.Attribute Msg -> List (Html.Html Msg) -> Html.Html Msg
footerButton event children =
    Html.button
        [ Html.Attributes.class <|
            String.join " "
                [ "bg-white"
                , "font-bold"
                , "leading-6"
                , "lowercase"
                , "p-4"
                , "rounded-lg"
                , "text-lg"
                , "text-sky-600"
                ]
        , event
        ]
        children
