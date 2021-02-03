package main

import (
	"fmt"
	"testing"
)

func Test_makeRequest_experiments(t *testing.T) {
	if true {  //skip
		return
	}
	res, _ := makeRequest("https://longisland.craigslist.org/search/?query=2x4+lumber")

	fmt.Println(res)
}
