package main

import (
	"encoding/json"
	"fmt"
	"testing"
)

func TestHello(t *testing.T) {
	var model Model = Model{}
	model.TableModels = make([]TableModel, 1)
	model.TableModels[0].TopHeadings = make([]string, 0)
	model.TableModels[0].SideHeadings = make([]string, 0)
	model.TableModels[0].Rows = make([][]CellModel, 0)
	jsonBytes, _ := json.MarshalIndent(model, "", "  ")
	fmt.Printf("%v", string(jsonBytes))
	t.Fatalf("blah")
}
