module Screen.App.WelcomeModal exposing (Model, Msg, init, update, view)

import Html
import Html.Attributes
import Html.Events
import Ports
import Session



-- MODEL


type alias Model =
    { session : Session.Session }


init : Session.Session -> ( Model, Cmd Msg )
init session =
    ( Model session, Ports.toggleModal () )



-- UPDATE


type Msg
    = ClickContinue


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickContinue ->
            ( model, Cmd.batch [ Ports.clearPath (), Ports.toggleModal () ] )



-- VIEW


view : Model -> Html.Html Msg
view _ =
    let
        introText =
            "We've put some instructions to help you get started..."
    in
    Html.div [ Html.Attributes.id "modal-content" ]
        [ Html.div
            [ Html.Attributes.id "modal-banner"
            , Html.Attributes.class "modal-welcome-banner"
            ]
            [ Html.text "Welcome to File Finder! 🎉" ]
        , Html.div [ Html.Attributes.id "modal-welcome" ]
            [ Html.div [ Html.Attributes.id "welcome-getting-started" ]
                [ Html.p [ Html.Attributes.id "welcome-intro" ]
                    [ Html.text introText ]
                , Html.div [ Html.Attributes.id "welcome-steps" ] viewSteps
                ]
            , Html.div [ Html.Attributes.id "welcome-actions" ]
                [ Html.button [ Html.Events.onClick ClickContinue ]
                    [ Html.text "Get Started" ]
                ]
            ]
        ]


viewSteps : List (Html.Html msg)
viewSteps =
    let
        stepOneText =
            [ Html.text <|
                """The upload button is in the bottom right corner, and if your
                store already had files, you'll see that we dropped them in
                the """
            , Html.span [ Html.Attributes.class "dir-ref" ]
                [ Html.text <| "/root" ]
            , Html.text <|
                """ folder. To upload a file into a different folder, click on
                that folder. Speaking of folders..."""
            ]

        stepTwoText =
            [ Html.text <|
                """The add new folder button is also in the bottom right corner,
                and """
            , Html.span [ Html.Attributes.class "dir-ref" ]
                [ Html.text "/root" ]
            , Html.text <| " is the top-level folder. Create folders in "
            , Html.span [ Html.Attributes.class "dir-ref" ]
                [ Html.text "/root" ]
            , Html.text <|
                """ then create folders within those folders until satisfied.
                Don't worry about mistakes; you can rename or delete a folder
                anytime by clicking on the folder."""
            ]

        stepThreeText =
            [ Html.text <|
                """Move files and folders by clicking on them until you have a
                structure that gives you optimum sanity and efficiency."""
            ]
    in
    [ Html.div [ Html.Attributes.class "welcome-step" ]
        [ Html.h3 [] [ Html.text "Step 1: Upload files" ]
        , Html.p [] stepOneText
        ]
    , Html.div [ Html.Attributes.class "welcome-step" ]
        [ Html.h3 [] [ Html.text "Step 2: Add new folders" ]
        , Html.p [] stepTwoText
        ]
    , Html.div [ Html.Attributes.class "welcome-step" ]
        [ Html.h3 [] [ Html.text "Step 3: Organize!" ]
        , Html.p [] stepThreeText
        ]
    ]
