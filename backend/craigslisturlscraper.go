package main

import (
	"fmt"

	"github.com/gocolly/colly"
)

// This represents a single search result from a URL
type CraigslistSearchResult struct {
	Title string
	Url   string
}

func getResultsFromCraigslistUrl(url string) []CraigslistSearchResult {
	results := make([]CraigslistSearchResult, 1)

	c := colly.NewCollector()

	// Find and visit all links
	c.OnHTML(".result-title", func(e *colly.HTMLElement) {
		//e.Request.Visit(e.Attr("href"))
		//fmt.Printf("%v\n", e)
		fmt.Printf("Result Title: %v\n", e.Text)
		url := e.DOM.Nodes[0].Attr[0].Val
		fmt.Printf("Result URL: %v\n", url)

		temp := CraigslistSearchResult{}
		temp.Title = e.Text
		temp.Url = url

		results = append(results, temp)
	})

	c.OnRequest(func(r *colly.Request) {
		fmt.Println("Visiting", r.URL)
	})

	//c.Visit("https://sfbay.craigslist.org/search/eby/tfr?")
	c.Visit(url)
	fmt.Println("done")
	fmt.Printf("There are: %v", len(results))
	return results
}
