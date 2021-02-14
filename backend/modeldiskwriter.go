package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
)


type ModelDiskWriter interface {
	writeModelToDisk()
}


type RealModelDiskWriter struct {
}

func (r RealModelDiskWriter) writeModelToDisk() {
	filename := fmt.Sprintf(defaultmodelpath)
	jsonBytes, _ := json.MarshalIndent(model, "", "  ")
	ioutil.WriteFile(filename, jsonBytes, 666)
}
