port module Ports exposing (clearPath, copyToClipboard, toggleModal)

-- PORTS


port clearPath : () -> Cmd msg


port copyToClipboard : String -> Cmd msg


port toggleModal : () -> Cmd msg
