package ima

import (
	"context"
	"github.com/osquery/osquery-go/plugin/table"
	"strings"
)

const (
	_PCR                  = "PCR"
	_IMA_HASH             = "IMA_HASH"
	_TEMPLATE             = "Template"
	_HASH_TYPE            = "HashType"
	_HASH_VALUE           = "FileHash"
	_FILENAME             = "FileName"
	_IMA_SIG              = "IMASignature"
	_MEASUREMENT_BASEPATH = "/sys/kernel/security/ima/"
	_ASCII_RM             = "ascii_runtime_measurements"
)

func (m *Measurements) osCompat() error {
	return nil
}

func (m *Measurements) osColumns() []table.ColumnDefinition {
	return []table.ColumnDefinition{
		table.BigIntColumn(_PCR),
		table.TextColumn(_IMA_HASH),
		table.TextColumn(_TEMPLATE),
		table.TextColumn(_HASH_TYPE),
		table.TextColumn(_HASH_VALUE),
		table.TextColumn(_FILENAME),
	}
}

func (m *Measurements) osGenerate(ctx context.Context, queryContext table.QueryContext) (ret []map[string]string, err error) {
	ascii_runtime_measurements := readFile(_MEASUREMENT_BASEPATH, _ASCII_RM)
	for _, line := range strings.Split(strings.TrimSuffix(ascii_runtime_measurements, "\n"), "\n") {

		elem := strings.Split(line, " ")

		current := map[string]string{
			_PCR: elem[0],
			_IMA_HASH: elem[1],
			_TEMPLATE: elem[2],
			_HASH_TYPE: strings.Split(elem[3], ":")[0],
			_HASH_VALUE: strings.Split(elem[3], ":")[1],
			_FILENAME: elem[4],
		}

		ret = append(ret, current)

	}

	return
}
