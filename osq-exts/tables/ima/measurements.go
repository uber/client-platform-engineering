package ima

import (
	"context"
	"github.com/osquery/osquery-go/plugin/table"
)

const (
	_MEASUREMENT_PLUGIN_NAME    = "ima_measurements"
	_MEASUREMENT_NOT_COMPATIBLE = "Not compatible with current OS."
)

type Measurements struct{}

func NewMeasurements() (m *Measurements, err error) {
	err = m.osCompat()
	return
}

func (m *Measurements) Columns() []table.ColumnDefinition {
	return m.osColumns()
}

func (m *Measurements) Register() (string, []table.ColumnDefinition, table.GenerateFunc) {
	return _MEASUREMENT_PLUGIN_NAME, m.Columns(), m.Generate
}

func (m *Measurements) Generate(ctx context.Context, queryContext table.QueryContext) ([]map[string]string, error) {
	return m.osGenerate(ctx, queryContext)
}
