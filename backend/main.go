package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"math/rand"
	"net/http"
	"net/url"
	"strings"
	"time"

	"golang.org/x/net/html"

	"github.com/julienschmidt/httprouter"
	"github.com/pkg/errors"
)

var debug = false

var err error

type tableModelRequest struct {
	TableId int `json:"tableId"`
}

type requestCraigslistPageRequest struct {
	SearchURL string `json:"searchURL"`
}
type requestCraigslistPageResponse struct {
	ResponseHTML string `json:"response"`
}

func main() {

	router := httprouter.New()
	router.ServeFiles("/frontend/*filepath", http.Dir("../frontend"))

	router.POST("/api/", requestCraigslistPageHandler)
	router.POST("/api/table", tableModelHandler)

	//browser.OpenURL("http://localhost:8080/frontend/index.html")

	fmt.Println("serving on 8080")
	http.ListenAndServe(":8080", router)
}

func tableModelHandler(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	req := parseTableModelRequest(r.Body)

	var contents []byte
	if 0 == req.TableId {
		fmt.Print("\n\nWTF 0")
		contents, err = ioutil.ReadFile("../data/table1.json")
		fatal(err)
	}
	if 1 == req.TableId {
		fmt.Print("\n\nWTF 1")
		contents, err = ioutil.ReadFile("../data/table2.json")
		fatal(err)
	}

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

	req.SearchURL, err = url.QueryUnescape(req.SearchURL)
	fatal(err)

	return req
}

func fetchCraigslistQuery(url string) string {
	if debug == true {
		return `<html><body><ul><li class="result-row" data-pid="6744258112">` +
			` Wow cool ` + url + ` </li></ul></body></html>`
	}
	rawHTML, err := makeRequest(url)
	if err != nil {
		return `<html><body><ul><li class="result-row" data-pid="6744258112">` +
			` ERROR: ` + err.Error() + ` : ` + url + ` </li></ul></body></html>`
	}

	return extractCraigslistResultRows(rawHTML)
}

func extractCraigslistResultRows(rawHTML string) string {

	doc, _ := html.Parse(strings.NewReader(rawHTML))
	resultRows, _ := getResultRows(doc)
	return renderNode(resultRows)
}

func getResultRows(doc *html.Node) (*html.Node, error) {
	var b *html.Node
	var f func(*html.Node)
	f = func(n *html.Node) {
		if n.Type == html.ElementNode && n.Data == "li" {
			for _, attr := range n.Attr {
				if attr.Key == "class" && attr.Val == "result-row" {
					b = n.Parent
				}
			}
		}
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			f(c)
		}
	}
	f(doc)
	if b != nil {
		return b, nil
	}
	return nil, errors.New("Missing <result rows> in the node tree")
}

func renderNode(n *html.Node) string {
	var buf bytes.Buffer
	w := io.Writer(&buf)
	html.Render(w, n)
	return buf.String()
}

func makeRequest(url string) (string, error) {

	log.Print("makeRequest: sleep ... ")
	r := rand.Intn(1000)
	time.Sleep(time.Duration(r) * time.Millisecond)

	log.Printf("makeRequest: %s\n", url)

	client := http.Client{
		Timeout: time.Duration(3 * time.Second),
	}
	resp, err := client.Get(url) //"https://httpbin.org/get"

	//gracefully handle error with invalid craigslist URL
	if err != nil {
		log.Println("    TIMEOUT: " + url)
		return "TIMEOUT", errors.New("TIMEOUT")
	}

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Fatalln(err)
	}

	return string(body), nil
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
