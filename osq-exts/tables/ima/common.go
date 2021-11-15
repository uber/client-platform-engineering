package ima

import (
	"bytes"
	"os"
)

func pathExists(path string) string {

	_, err := os.Stat(path)
	if err != nil {
		return "false"
	}

	return "true"
}

func readFile(path, name string) (ret string) {
	file, err := os.Open(path + name)
	if err != nil {
		return
	}
	defer file.Close()

	buf := new(bytes.Buffer)
	buf.ReadFrom(file)
	ret = buf.String()

	return
}
