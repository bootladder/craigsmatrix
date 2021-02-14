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
    "id": 1,
    "topHeadings": ["sfbay","boston","sacramento","seattle","austin"],    
    "sideHeadings": ["carpentry","masonry","welding","asdf lkj woerewggdsj sdfds"],    
    "rows":
        [
            [
                {
                    "pageUrl":"https://sfbay.craigslist.org/d/jobs/search/jjj?query=Welding",
                    "feedUrl":"https://sfbay.craigslist.org/d/jobs/search/jjj?format=rss&query=Welding",
                    "hits":1
                },
                {
                    "pageUrl":"https://sfbay.craigslist.org/d/jobs/search/jjj?query=Electrical",
                    "feedUrl":"https://sfbay.craigslist.org/d/jobs/search/jjj?format=rss&query=Welding",
                    "hits":1
                },
                {
                    "pageUrl":"https://seattle.craigslist.org/d/jobs/search/jjj?query=Carpenter",
                    "feedUrl":"https://sfbay.craigslist.org/d/jobs/search/jjj?format=rss&query=Welding",
                    "hits":1
                }
            ],
            [
                {
                    "pageUrl":"https://sfbay.craigslist.org/d/jobs/search/jjj?query=Welding",
                    "feedUrl":"https://sfbay.craigslist.org/d/jobs/search/jjj?format=rss&query=Welding",
                    "hits":1
                },
                {
                    "pageUrl":"https://sfbay.craigslist.org/d/jobs/search/jjj?query=Welding",
                    "feedUrl":"https://sfbay.craigslist.org/d/jobs/search/jjj?format=rss&query=Welding",
                    "hits":1
                }
            ],
            [
                {
                    "pageUrl":"https://sfbay.craigslist.org/d/jobs/search/jjj?query=Welding",
                    "feedUrl":"https://sfbay.craigslist.org/d/jobs/search/jjj?format=rss&query=Welding",
                    "hits":1
                },
                {
                    "pageUrl":"https://sfbay.craigslist.org/d/jobs/search/jjj?query=Welding",
                    "feedUrl":"https://sfbay.craigslist.org/d/jobs/search/jjj?format=rss&query=Welding",
                    "hits":1
                }
            ],
            [
                {
                    "pageUrl":"https://sfbay.craigslist.org/d/jobs/search/jjj?query=Welding",
                    "feedUrl":"https://sfbay.craigslist.org/d/jobs/search/jjj?format=rss&query=Welding",
                    "hits":1
                },
                {
                    "pageUrl":"https://sfbay.craigslist.org/d/jobs/search/jjj?query=Welding",
                    "feedUrl":"https://sfbay.craigslist.org/d/jobs/search/jjj?format=rss&query=Welding",
                    "hits":1
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
                            tableModelDecoder testJson
                    result = case decodedOutput of
                        Err msg -> Main.TableModel (Json.Decode.errorToString msg) 1 [] [] [[]] 
                        Ok a -> a
                in
                    Expect.equal result.name "myname"
        ]