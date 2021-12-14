package ima

import (
	"context"
	"github.com/osquery/osquery-go/plugin/table"
)

const (
	_IMA_PLUGIN_NAME    = "ima"
	_IMA_NOT_COMPATIBLE = "Not compatible with current OS."
)

type IMA struct{}

func NewIMA() (ima *IMA, err error) {
	err = ima.osCompat()
	return
}

func (m *IMA) Columns() []table.ColumnDefinition {
	return m.osColumns()
}

func (m *IMA) Register() (string, []table.ColumnDefinition, table.GenerateFunc) {
	return _IMA_PLUGIN_NAME, m.Columns(), m.Generate
}

func (m *IMA) Generate(ctx context.Context, queryContext table.QueryContext) ([]map[string]string, error) {
	return m.osGenerate(ctx, queryContext)
}
