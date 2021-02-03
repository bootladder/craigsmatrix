package main

import (
	"bytes"
	"errors"
	"io"
	"io/ioutil"
	"log"
	"math/rand"
	"net/http"
	"strings"
	"time"

	"golang.org/x/net/html"
)


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
