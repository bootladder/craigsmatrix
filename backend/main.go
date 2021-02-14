package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	//"net/url"

	"github.com/julienschmidt/httprouter"
	"github.com/pkg/errors"
)

var debug = false

var err error

type tableModelRequest struct {
	TableID int `json:"tableId"`
}

type allTableNamesAndIDsRequest struct {
	//dont care
}

type activeTableRequest struct {
	//dont care
}

type addTopFieldRequest struct {
	TableID int `json:"tableId"`
}

type addSideFieldRequest struct {
	TableID int `json:"tableId"`
}

type deleteTopFieldRequest struct {
	TableID int `json:"tableId"`
}

type deleteSideFieldRequest struct {
	TableID int `json:"tableId"`
}

type updateTableDataRequest struct {
	TableID int `json:"tableId"`
}

type updateTableNameRequest struct {
	Name string `json:"name"`
}

type updateCategoryRequest struct {
	Category string `json:"category"`
}

type fieldEditRequest struct {
	TableID    int    `json:"tableId"`
	FieldIndex int    `json:"fieldIndex"`
	FieldValue string `json:"fieldValue"`
	FieldType  string `json:"fieldType"`
}

type requestCraigslistPageRequest struct {
	SearchURL string `json:"searchURL"`
}
type requestCraigslistPageResponse struct {
	ResponseHTML string `json:"response"`
}

func main() {

	setModelDiskWriter(RealModelDiskWriter{})
	setModel(loadModelDataFile())

	router := httprouter.New()
	router.ServeFiles("/*filepath", http.Dir("./"))

	router.POST("/api/", requestCraigslistPageHandler)
	router.POST("/api/table", tableModelHandler)
	router.POST("/api/alltablenamesandids", allTableNamesAndIDsHandler)
	router.POST("/api/fieldedit", fieldEditHandler)
	router.POST("/api/addtopfield", addTopFieldHandler)
	router.POST("/api/addsidefield", addSideFieldHandler)
	router.POST("/api/deletetopfield", deleteTopFieldHandler)
	router.POST("/api/deletesidefield", deleteSideFieldHandler)
	router.POST("/api/updatetabledata", updateTableDataHandler)
	router.POST("/api/addtable", addTableHandler)
	router.POST("/api/deletetable", deleteTableHandler)
	router.POST("/api/activetable", activeTableRequestHandler)
	router.POST("/api/updatetablename", updateTableNameHandler)
	router.POST("/api/updatecategory", updateCategoryHandler)

	//browser.OpenURL("http://localhost:8080/frontend/index.html")

	fmt.Println("serving on 8080")
	http.ListenAndServe(":8080", router)
}

// Handler
func tableModelHandler(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	req := parseTableModelRequest(r.Body)

	contents := modelToJSONBytes(req.TableID)
	setActiveTableModelID(req.TableID)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(contents)
}

func parseTableModelRequest(requestBody io.Reader) tableModelRequest {
	var req tableModelRequest
	err := json.NewDecoder(requestBody).Decode(&req)
	fatal(err)
	return req
}

// Handler
func allTableNamesAndIDsHandler(w http.ResponseWriter, r *http.Request, p httprouter.Params) {

	contents := listOfTableNamesAndIDsAsJSONBytes()

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(contents)
}

// Handler
func fieldEditHandler(w http.ResponseWriter, r *http.Request, p httprouter.Params) {

	req := parseFieldEditRequestBody(r.Body)

	editTableModelField(req.TableID, req.FieldIndex, req.FieldValue, req.FieldType)
	contents := modelToJSONBytes(req.TableID)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(contents)
}

func parseFieldEditRequestBody(requestBody io.Reader) fieldEditRequest {
	var req fieldEditRequest
	err := json.NewDecoder(requestBody).Decode(&req)
	fatal(err)
	return req
}

// Handler
func addTopFieldHandler(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	req := parseAddTopFieldRequestBody(r.Body)

	addTopField(req.TableID)

	contents := modelToJSONBytes(req.TableID)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(contents)
}

func parseAddTopFieldRequestBody(requestBody io.Reader) addTopFieldRequest {
	var req addTopFieldRequest
	err := json.NewDecoder(requestBody).Decode(&req)
	fatal(err)
	return req
}

// Handler
func addSideFieldHandler(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	req := parseAddSideFieldRequestBody(r.Body)

	addSideField(req.TableID)

	contents := modelToJSONBytes(req.TableID)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(contents)
}

func parseAddSideFieldRequestBody(requestBody io.Reader) addSideFieldRequest {
	var req addSideFieldRequest
	err := json.NewDecoder(requestBody).Decode(&req)
	fatal(err)
	return req
}

// Handler
func deleteTopFieldHandler(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	req := parseDeleteTopFieldRequestBody(r.Body)

	deleteTopField(req.TableID)

	contents := modelToJSONBytes(req.TableID)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(contents)
}

func parseDeleteTopFieldRequestBody(requestBody io.Reader) deleteTopFieldRequest {
	var req deleteTopFieldRequest
	err := json.NewDecoder(requestBody).Decode(&req)
	fatal(err)
	return req
}

// Handler
func deleteSideFieldHandler(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	req := parseDeleteSideFieldRequestBody(r.Body)

	deleteSideField(req.TableID)

	contents := modelToJSONBytes(req.TableID)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(contents)
}

func parseDeleteSideFieldRequestBody(requestBody io.Reader) deleteSideFieldRequest {
	var req deleteSideFieldRequest
	err := json.NewDecoder(requestBody).Decode(&req)
	fatal(err)
	return req
}

// Handler
func updateTableNameHandler(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	req := parseUpdateTableNameRequestBody(r.Body)
	updateTableName(req.Name)

	contents := listOfTableNamesAndIDsAsJSONBytes()

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(contents)
}

func parseUpdateTableNameRequestBody(requestBody io.Reader) updateTableNameRequest {
	var req updateTableNameRequest
	err := json.NewDecoder(requestBody).Decode(&req)
	fatal(err)
	return req
}

// Handler
func updateTableDataHandler(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	req := parseUpdateTableDataRequestBody(r.Body)

	fmt.Printf("updateTableDataHandler: TableID: %v\n", req.TableID)
	updateTableData(req.TableID)

	contents := modelToJSONBytes(req.TableID)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(contents)
}

func parseUpdateTableDataRequestBody(requestBody io.Reader) updateTableDataRequest {
	var req updateTableDataRequest
	err := json.NewDecoder(requestBody).Decode(&req)
	fatal(err)
	return req
}

func updateCategoryHandler(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	req := parseUpdateCategoryRequestBody(r.Body)
	updateTableCategory(req.Category)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("DONT CARE"))
}

func parseUpdateCategoryRequestBody(requestBody io.Reader) updateCategoryRequest {
	var req updateCategoryRequest
	err := json.NewDecoder(requestBody).Decode(&req)
	fatal(err)
	return req
}

// Handler
func requestCraigslistPageHandler(w http.ResponseWriter, r *http.Request, p httprouter.Params) {

	req := parseRequestCraigslistPageRequestBody(r.Body)

	var resp requestCraigslistPageResponse
	resp.ResponseHTML = fetchCraigslistQuery(req.SearchURL)

	jsonOut, err := json.Marshal(resp)
	fatal(err)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(jsonOut)
}

func parseRequestCraigslistPageRequestBody(requestBody io.Reader) requestCraigslistPageRequest {
	var req requestCraigslistPageRequest
	err := json.NewDecoder(requestBody).Decode(&req)
	fatal(err)

	// do I need this or not?
	//req.SearchURL, err = url.QueryUnescape(req.SearchURL)
	//fatal(err)

	return req
}

// Handler
func addTableHandler(w http.ResponseWriter, r *http.Request, p httprouter.Params) {

	addTable()
	contents := listOfTableNamesAndIDsAsJSONBytes()

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(contents)
}

// Handler
func deleteTableHandler(w http.ResponseWriter, r *http.Request, p httprouter.Params) {

	deleteTable()
	contents := listOfTableNamesAndIDsAsJSONBytes()

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(contents)
}

// Handler
func activeTableRequestHandler(w http.ResponseWriter, r *http.Request, p httprouter.Params) {

	activeTableID := getActiveTableID()

	fmt.Printf("ACTIVE TABVLEID IS : %d", activeTableID)
	contents := modelToJSONBytes(activeTableID)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(contents)
}


func fatal(err error, msgs ...string) {
	if err != nil {
		var str string
		for _, msg := range msgs {
			str = msg
			break
		}
		panic(errors.Wrap(err, str))
	}
}

func printf(s string, a ...interface{}) {
	fmt.Printf(s, a...)
}
