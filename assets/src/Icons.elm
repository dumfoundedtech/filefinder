module Icons exposing (add, check, close, cloud, dir, externalLink, left, right)

import Html
import Svg exposing (..)
import Svg.Attributes exposing (..)



-- ADD


add : List String -> Html.Html msg
add classes =
    svg [ class <| String.join " " classes, viewBox "0 0 24 24" ]
        [ Svg.path
            [ d <|
                String.join " "
                    [ "M17"
                    , "11a1"
                    , "1"
                    , "0"
                    , "0"
                    , "1"
                    , "0"
                    , "2h-4v4a1"
                    , "1"
                    , "0"
                    , "0"
                    , "1-2"
                    , "0v-4H7a1"
                    , "1"
                    , "0"
                    , "0"
                    , "1"
                    , "0-2h4V7a1"
                    , "1"
                    , "0"
                    , "0"
                    , "1"
                    , "2"
                    , "0v4h4z"
                    ]
            ]
            []
        ]



-- CHECK


check : List String -> Html.Html msg
check classes =
    svg [ class <| String.join " " classes, viewBox "0 0 24 24" ]
        [ Svg.path
            [ d <|
                String.join " " <|
                    [ "M10"
                    , "14.59l6.3-6.3a1"
                    , "1"
                    , "0"
                    , "0"
                    , "1"
                    , "1.4"
                    , "1.42l-7"
                    , "7a1"
                    , "1"
                    , "0"
                    , "0"
                    , "1-1.4"
                    , "0l-3-3a1"
                    , "1"
                    , "0"
                    , "0"
                    , "1"
                    , "1.4-1.42l2.3"
                    , "2.3z"
                    ]
            ]
            []
        ]



-- CLOSE


close : List String -> Html.Html msg
close classes =
    svg [ class <| String.join " " classes, viewBox "0 0 24 24" ]
        [ Svg.path
            [ d <|
                String.join " "
                    [ "M15.78"
                    , "14.36a1"
                    , "1"
                    , "0"
                    , "0"
                    , "1-1.42"
                    , "1.42l-2.82-2.83-2.83"
                    , "2.83a1"
                    , "1"
                    , "0"
                    , "1"
                    , "1-1.42-1.42l2.83-2.82L7.3"
                    , "8.7a1"
                    , "1"
                    , "0"
                    , "0"
                    , "1"
                    , "1.42-1.42l2.83"
                    , "2.83"
                    , "2.82-2.83a1"
                    , "1"
                    , "0"
                    , "0"
                    , "1"
                    , "1.42"
                    , "1.42l-2.83"
                    , "2.83"
                    , "2.83"
                    , "2.82z"
                    ]
            ]
            []
        ]



-- CLOUD


cloud : List String -> Html.Html msg
cloud classes =
    svg [ class <| String.join " " classes, viewBox "0 0 24 24" ]
        [ Svg.path
            [ d <|
                String.join " "
                    [ "M5.03"
                    , "12.12A5.5"
                    , "5.5"
                    , "0"
                    , "0"
                    , "1"
                    , "16"
                    , "11.26"
                    , "4.5"
                    , "4.5"
                    , "0"
                    , "1"
                    , "1"
                    , "17.5"
                    , "20H6a4"
                    , "4"
                    , "0"
                    , "0"
                    , "1-.97-7.88z"
                    ]
            ]
            []
        ]



-- DIR


dir : List String -> Html.Html msg
dir classes =
    svg [ class <| String.join " " classes, viewBox "0 0 24 24" ]
        [ g []
            [ Svg.path [ d "M22 10H2V6c0-1.1.9-2 2-2h7l2 2h7a2 2 0 0 1 2 2v2z" ]
                []
            , rect [ height "12", rx "2", width "20", x "2", y "8" ] []
            ]
        ]



-- LEFT


left : List String -> Html.Html msg
left classes =
    svg [ class <| String.join " " classes, viewBox "0 0 24 24" ]
        [ Svg.path
            [ d <|
                String.join " "
                    [ "M13.7"
                    , "15.3a1"
                    , "1"
                    , "0"
                    , "0"
                    , "1-1.4"
                    , "1.4l-4-4a1"
                    , "1"
                    , "0"
                    , "0"
                    , "1"
                    , "0-1.4l4-4a1"
                    , "1"
                    , "0"
                    , "0"
                    , "1"
                    , "1.4"
                    , "1.4L10.42"
                    , "12l3.3"
                    , "3.3z"
                    ]
            ]
            []
        ]



-- RIGHT


right : List String -> Html.Html msg
right classes =
    svg [ class <| String.join " " classes, viewBox "0 0 24 24" ]
        [ Svg.path
            [ d <|
                String.join " "
                    [ "M10.3"
                    , "8.7a1"
                    , "1"
                    , "0"
                    , "0"
                    , "1"
                    , "1.4-1.4l4"
                    , "4a1"
                    , "1"
                    , "0"
                    , "0"
                    , "1"
                    , "0"
                    , "1.4l-4"
                    , "4a1"
                    , "1"
                    , "0"
                    , "0"
                    , "1-1.4-1.4l3.29-3.3-3.3-3.3z"
                    ]
            ]
            []
        ]



-- EXTERNAL LINK


externalLink : List String -> Html.Html msg
externalLink classes =
    svg [ class <| String.join " " classes, viewBox "0 0 24 24" ]
        [ Svg.path
            [ d "M10 4L7 4C4 4 4 7 4 7L4 17C4 17 4 20 7 20L17 20C20 20 20 17 20 17L20 14M14 4L20 4L20 10M8 16L20 4"
            , fill "none"
            , stroke "currentColor"
            , strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "2"
            ]
            []
        ]
