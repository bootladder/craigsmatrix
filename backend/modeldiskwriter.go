package main

import (
)


type ModelDiskWriter interface {
	writeModelToDisk()
}


type RealModelDiskWriter struct {
}
func (r RealModelDiskWriter) writeModelToDisk() {

}
