module JsonDecodeTest exposing (..)

import Main exposing (..)
import Json.Decode

import Expect exposing (Expectation)
import Test exposing (..)

testJson : String
testJson =
    """
    %s
    """

suite : Test
suite =
    describe "Backend JSON Response Decoder"
        [ test "doesn't fail" <|
            \_ ->
                let
                    decodedOutput =
                        Json.Decode.decodeString
                            backendResponseDecoder testJson
                    result = case decodedOutput of
                        Err msg -> Main.TableModel (Json.Decode.errorToString msg) [] [] [[]] 
                        Ok a -> a
                in
                    Expect.equal result.name "myname"
        ]
