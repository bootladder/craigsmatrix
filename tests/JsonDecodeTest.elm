module JsonDecodeTest exposing (..)

import Main exposing (..)
import Json.Decode

import Expect exposing (Expectation)
import Test exposing (..)

testJson : String
testJson =
    """
    {
    "name": "myname",
    "topHeadings": ["sfbay","boston","portland","seattle","austin"],    
    "sideHeadings": ["carpentry","masonry","welding"],    
    "rows":
        [
            [
                {
                    "url":"https://sfbay.craigslist.org/d/jobs/search/jjj?query= Welding",
                    "hits":1,
                    "color":"blueCell",
                    "label": "label"
                },
                {
                    "url":"https://seattle.craigslist.org/d/jobs/search/jjj?query= Carpenter",
                    "hits":1,
                    "color":"blueCell",
                    "label": "label"
                }
            ],
            [
                {
                    "url":"https://sfbay.craigslist.org/d/jobs/search/jjj?query= Welding",
                    "hits":1,
                    "color":"blueCell",
                    "label": "label"
                },
                {
                    "url":"https://sfbay.craigslist.org/d/jobs/search/jjj?query= Welding",
                    "hits":1,
                    "color":"blueCell",
                    "label": "label"
                }
            ]
        ]
        
}
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