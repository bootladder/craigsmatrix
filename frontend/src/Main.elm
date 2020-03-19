module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Http
import Json.Decode exposing (..)
import Json.Encode 

import String


-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias Model =
    { debugBreadcrumb : String
    , currentUrl : String
    , tableModel : TableModel
    , allTableNamesAndIds : List(TableNameAndId)
    , craigslistPageHtmlString : String
    , editingFieldInputValue : String
    , editingFieldIndex : Int
    , editingFieldType : FieldType
    , tableNameEditorValue : String
    }

type FieldType = TopField | SideField

fieldTypeToString : FieldType -> String
fieldTypeToString ft = case ft of
    TopField -> "top"
    SideField -> "side"


type alias CellViewModel =
    {
      pageUrl : String
    , feedUrl : String
    , hits : Int
    }

type alias TableModel =
    { name : String
    , id : Int
    , topHeadings : List (String)
    , sideHeadings : List (String)
    , rows : List (List (CellViewModel))
    }

type alias TableNameAndId =
    { name : String
    , id : Int
    }


-- INIT


initialTableModel : TableModel
initialTableModel = 
        TableModel "dummy uninitted" 1 [] [] [[]] 

initialUrl = "https://nothingrequestedyet"

init : () -> ( Model, Cmd Msg )
init _ =
    -- The initial model comes from a Request, now it is hard coded
    ( Model
        "dummy debug"
        initialUrl
        initialTableModel
        []
        "no craigslist page requested yet"
        ""
        0
        TopField
        ""
    , Cmd.batch [(httpRequestActiveTableModel), httpRequestAllTableNamesAndIds]
    )



-- UPDATE


type Msg
    = ReceivedCraigslistPage (Result Http.Error String)
    | ReceivedTableModel  (Result Http.Error TableModel)
    | ReceivedAllTableNamesAndIds  (Result Http.Error (List (TableNameAndId)))
    | NOOPHTTPResult (Result Http.Error ())
    | CellClicked CellViewModel
    | SelectTableClicked Int
    | AddTableClicked
    | DeleteTableClicked
    | UpdateTableNameClicked
    | TableNameEditorChanged String
    | FieldEditorChanged String
    | FieldEditorSubmit
    | TableTopFieldClicked String Int
    | TableSideFieldClicked String Int
    | TableTopFieldAddClicked
    | TableTopFieldDeleteClicked
    | TableSideFieldAddClicked
    | TableSideFieldDeleteClicked
    | UpdateTableData
    | SelectCategoryClicked String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CellClicked cellViewModel -> 
            ( {model 
                | currentUrl = cellViewModel.pageUrl
                }
            , httpRequestCraigslistSearchPage cellViewModel.pageUrl
            )

        ReceivedCraigslistPage result ->
            case result of
                Ok fullText ->
                    ( {model 
                        | craigslistPageHtmlString = fullText}
                    , Cmd.none
                    )

                Err e ->
                    ( {model 
                        | craigslistPageHtmlString = "FAIL"}
                    , Cmd.none
                    )

        ReceivedTableModel result ->
            case result of
                Ok resultTableModel ->
                    ( {model 
                        | tableModel = resultTableModel}
                    , Cmd.none
                    )

                Err (Http.BadBody s) ->
                    ( {model 
                        | craigslistPageHtmlString = s}
                    , Cmd.none
                    )
                Err _ ->
                    ( {model 
                        | craigslistPageHtmlString = "SOME OTHER HTTP ERROR"}
                    , Cmd.none
                    )

        ReceivedAllTableNamesAndIds  result ->
            case result of
                Ok names ->
                    ( {model | allTableNamesAndIds = names}, httpRequestActiveTableModel)

                Err e -> ({model
                        | craigslistPageHtmlString = "FAIL: ReceivedAllTableNamesAndIds"
                                        ++ (httpErrorToString e)
                        
                        }
                        , Cmd.none)


        NOOPHTTPResult  result ->
            case result of
                Ok _ ->
                    ( model, Cmd.none)

                Err e -> ({model
                        | craigslistPageHtmlString = "FAIL: ReceivedAllTableNamesAndIds"
                                        ++ (httpErrorToString e)
                        
                        }
                        , Cmd.none)

        SelectTableClicked tableId -> 
            ( model 
            , httpRequestTableModel tableId
            )

        AddTableClicked -> (model, 
                    httpAddTable)

        DeleteTableClicked -> (model, httpDeleteTable)

        UpdateTableNameClicked -> (model, httpUpdateTableName <| model.tableNameEditorValue)

        TableNameEditorChanged input -> 
            ( {model| tableNameEditorValue = input}, Cmd.none)

        FieldEditorChanged input ->
            ( {model| editingFieldInputValue = input}, Cmd.none)

        FieldEditorSubmit ->
            ( model, 
                httpSubmitFieldEdit model.editingFieldInputValue 
                                    model.editingFieldType
                                    model.tableModel.id 
                                    model.editingFieldIndex)

        TableTopFieldClicked fieldName fieldIndex ->
            ( {model | editingFieldInputValue = fieldName
                       ,editingFieldType = TopField
                       ,editingFieldIndex = fieldIndex
            }, Cmd.none)

        TableSideFieldClicked fieldName fieldIndex ->
            ( {model | editingFieldInputValue = fieldName
                       ,editingFieldType = SideField
                       ,editingFieldIndex = fieldIndex
            }, Cmd.none)


        TableTopFieldAddClicked  ->
            (model,
            httpAddTopField model.tableModel.id)

        TableTopFieldDeleteClicked  ->
            (model,
            httpDeleteTopField model.tableModel.id)

        TableSideFieldAddClicked  ->
            (model,
            httpAddSideField model.tableModel.id)

        TableSideFieldDeleteClicked  ->
            (model,
            httpDeleteSideField model.tableModel.id)


        UpdateTableData ->
            ( model, httpUpdateTableData model.tableModel.id)

        SelectCategoryClicked category -> 
            (model, httpUpdateCategory category)



httpErrorToString : Http.Error -> String
httpErrorToString e =
    case e of
        Http.BadBody s -> s
        Http.Timeout -> "Timeout"
        Http.NetworkError -> "Network Error"
        Http.BadStatus i -> "Bad status"
        Http.BadUrl s -> s

-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div [id "container"] 
    [ pageHeader
    , tableSelectionWidget model
    , constantsLabel
    , fieldEditor model.editingFieldInputValue
    , div [id "myTable"] [renderTable model.tableModel]
    , div [id "urlView"] [text model.currentUrl]
    , craigslistSearchPage  model.craigslistPageHtmlString
    ]

pageHeader : Html Msg
pageHeader =
    div [id "pageHeader"] [ 
        h1 [] [text "CraigslistMatrix."]
        , h2 [] [text "Take your search to the next dimension...  the second dimension."]
        ]

tableSelectionWidget : Model -> Html Msg
tableSelectionWidget model =
        div [id "tableNameLabel"]
            [ text <| model.tableModel.name
            , tableSelect model
            , button [ onClick AddTableClicked ] [ text "Add New Table"]
            , button [ onClick DeleteTableClicked ] [ text "Delete This Table"]
            , input [ onInput TableNameEditorChanged
                , Html.Attributes.value model.tableNameEditorValue 
                , placeholder "Update Table Name"] []
            , button [ onClick <| UpdateTableNameClicked] [ text "Update Table Name"]
            ]

tableSelect : Model -> Html Msg
tableSelect model =
        select [] 
            (List.indexedMap 
            (\i tablenameandid -> 
                option 
                [ onClick <| SelectTableClicked tablenameandid.id 
                , selected (if tablenameandid.id == model.tableModel.id then True else False)] 
                [text tablenameandid.name]
            ) 
            model.allTableNamesAndIds)

constantsLabel : Html Msg
constantsLabel = 
        div [id "constantsLabel"] 
            [ text "category label" 
            , select [] (

                List.map (\category -> option [ onClick <| SelectCategoryClicked category] [text category])
                [
                "community"
                ,"events"
                ,"for sale"
                ,"gigs"
                ,"housing"
                ,"jobs"
                ,"resumes"
                ,"services"
                ]
                  
            )

            ]


fieldEditor : String -> Html Msg
fieldEditor editorValue =
        div [id "fieldEditor"] 
        [ text "Field Editor" 
        , input [ onInput FieldEditorChanged
                , Html.Attributes.value editorValue 
                , placeholder "Click a row or column header"
                ] []
        , button [ onClick FieldEditorSubmit ] [text "Submit"]
        ]

renderTable : TableModel -> Html Msg
renderTable tableModel =
    let
        pairs = List.map2 Tuple.pair tableModel.sideHeadings tableModel.rows

        renderedRows = List.indexedMap 
                        (\i (heading, cells) -> renderRow i heading cells)
                        pairs
    in
    table [] (
        [renderTableHeadersRow tableModel.topHeadings]
        ++
        renderedRows
        ++
        [tr [id "myRow"] [button [onClick TableSideFieldAddClicked] [text "add"]]]
        ++
        [tr [id "myRow"] [button [onClick TableSideFieldDeleteClicked] [text "del"]]]
    )

renderTableHeadersRow : List (String) -> Html Msg
renderTableHeadersRow headings  =
    tr [] (
            [ th [] [button [onClick UpdateTableData] [text "UPDATE"]] ]
            ++
            List.indexedMap (\i heading -> th [ onClick (TableTopFieldClicked heading i)] [text heading]) headings
            ++
            [ th [] [button [onClick TableTopFieldAddClicked] [text "add"]]]
            ++
            [ th [] [button [onClick TableTopFieldDeleteClicked] [text "del"]]]
    )

renderRow : Int -> String -> List (CellViewModel) ->  Html Msg
renderRow index heading cellViewModels =
        tr [id "myRow"] ( 
                th [onClick (TableSideFieldClicked heading index)] [text heading]
                ::
                  List.map renderCellViewModel cellViewModels
            )

renderCellViewModel : CellViewModel -> Html Msg
renderCellViewModel cellViewModel =
    td [class "blueCell", onClick (CellClicked cellViewModel)] [text <| String.fromInt cellViewModel.hits]


craigslistSearchPage : String -> Html msg
craigslistSearchPage html =
    Html.node "rendered-html"
        [ Html.Attributes.property "content" (Json.Encode.string html) ]
        []

-- HTTP

httpRequestCraigslistSearchPage : String -> Cmd Msg
httpRequestCraigslistSearchPage url =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "searchURL", Json.Encode.string url )
                    ]
        , url = "http://localhost:8080/api/"
        , expect = Http.expectJson (\jsonResult -> ReceivedCraigslistPage jsonResult) craigslistPageDecoder
        }

httpRequestTableModel : Int -> Cmd Msg
httpRequestTableModel id =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "tableId", Json.Encode.int id )
                    ]
        , url = "http://localhost:8080/api/table"
        , expect = Http.expectJson (\jsonResult -> ReceivedTableModel jsonResult) tableModelDecoder
        }

httpRequestAllTableNamesAndIds : Cmd Msg
httpRequestAllTableNamesAndIds =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "nothing here", Json.Encode.int 99 )
                    ]
        , url = "http://localhost:8080/api/alltablenamesandids"
        , expect = Http.expectJson (\jsonResult -> ReceivedAllTableNamesAndIds jsonResult) allTableNamesAndIdsDecoder
        }


httpSubmitFieldEdit : String -> FieldType -> Int -> Int -> Cmd Msg
httpSubmitFieldEdit fieldValue fieldType tableId fieldIndex =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "tableId", Json.Encode.int tableId )
                    , ( "fieldType", Json.Encode.string <| fieldTypeToString fieldType )
                    , ( "fieldIndex", Json.Encode.int fieldIndex)
                    , ( "fieldValue", Json.Encode.string fieldValue)
                    ]
        , url = "http://localhost:8080/api/fieldedit"
        , expect = Http.expectJson (\jsonResult -> ReceivedTableModel jsonResult) tableModelDecoder
        }


httpAddTopField : Int -> Cmd Msg
httpAddTopField tableId =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "tableId", Json.Encode.int tableId )
                    ]
        , url = "http://localhost:8080/api/addtopfield"
        , expect = Http.expectJson (\jsonResult -> ReceivedTableModel jsonResult) tableModelDecoder
        }

httpAddSideField : Int -> Cmd Msg
httpAddSideField tableId =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "tableId", Json.Encode.int tableId )
                    ]
        , url = "http://localhost:8080/api/addsidefield"
        , expect = Http.expectJson (\jsonResult -> ReceivedTableModel jsonResult) tableModelDecoder
        }


httpDeleteTopField : Int -> Cmd Msg
httpDeleteTopField tableId =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "tableId", Json.Encode.int tableId )
                    ]
        , url = "http://localhost:8080/api/deletetopfield"
        , expect = Http.expectJson (\jsonResult -> ReceivedTableModel jsonResult) tableModelDecoder
        }

httpDeleteSideField : Int -> Cmd Msg
httpDeleteSideField tableId =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "tableId", Json.Encode.int tableId )
                    ]
        , url = "http://localhost:8080/api/deletesidefield"
        , expect = Http.expectJson (\jsonResult -> ReceivedTableModel jsonResult) tableModelDecoder
        }


 
httpAddTable : Cmd Msg
httpAddTable =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "nothing", Json.Encode.int 99 )
                    ]
        , url = "http://localhost:8080/api/addtable"
        , expect = Http.expectJson (\jsonResult -> ReceivedAllTableNamesAndIds jsonResult) allTableNamesAndIdsDecoder
        }
 
httpDeleteTable : Cmd Msg
httpDeleteTable =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "nothing", Json.Encode.int 99 )
                    ]
        , url = "http://localhost:8080/api/deletetable"
        , expect = Http.expectJson (\jsonResult -> ReceivedAllTableNamesAndIds jsonResult) allTableNamesAndIdsDecoder
        }


httpUpdateTableData : Int -> Cmd Msg
httpUpdateTableData tableId =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "tableId", Json.Encode.int tableId )
                    ]
        , url = "http://localhost:8080/api/updatetabledata"
        , expect = Http.expectJson (\jsonResult -> ReceivedTableModel jsonResult) tableModelDecoder
        }

httpRequestActiveTableModel : Cmd Msg
httpRequestActiveTableModel =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "dontcare", Json.Encode.int 99 )
                    ]
        , url = "http://localhost:8080/api/activetable"
        , expect = Http.expectJson (\jsonResult -> ReceivedTableModel jsonResult) tableModelDecoder
        }


httpUpdateTableName : String -> Cmd Msg
httpUpdateTableName name =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "name", Json.Encode.string name )
                    ]
        , url = "http://localhost:8080/api/updatetablename"
        , expect = Http.expectJson (\jsonResult -> ReceivedAllTableNamesAndIds jsonResult) allTableNamesAndIdsDecoder
        }



httpUpdateCategory : String -> Cmd Msg
httpUpdateCategory category =
    Http.post
        { body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "category", Json.Encode.string category )
                    ]
        , url = "http://localhost:8080/api/updatecategory"
        , expect = Http.expectWhatever NOOPHTTPResult
        }


-- DECODER

craigslistPageDecoder : Decoder String
craigslistPageDecoder =
    field "response" Json.Decode.string

tableModelDecoder : Decoder TableModel
tableModelDecoder = 
    Json.Decode.map5 TableModel
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "id" (Json.Decode.int))
        (Json.Decode.field "topHeadings" (Json.Decode.list string))
        (Json.Decode.field "sideHeadings" (Json.Decode.list string))
        rowsDecoder 
  

rowsDecoder : Decoder (List (List (CellViewModel)))
rowsDecoder =
  Json.Decode.field "rows" (Json.Decode.list ((Json.Decode.list cellViewModelDecoder)))

cellViewModelDecoder : Decoder CellViewModel
cellViewModelDecoder =
    Json.Decode.map3 CellViewModel
        (Json.Decode.field "pageUrl" Json.Decode.string)
        (Json.Decode.field "feedUrl" Json.Decode.string)


        (Json.Decode.field "hits" Json.Decode.int)

allTableNamesAndIdsDecoder : Decoder (List (TableNameAndId))
allTableNamesAndIdsDecoder =
    (Json.Decode.list tableNameAndIdDecoder)


tableNameAndIdDecoder : Decoder TableNameAndId
tableNameAndIdDecoder =
    Json.Decode.map2 TableNameAndId (Json.Decode.field "name" Json.Decode.string) (Json.Decode.field "id" Json.Decode.int) 