package ima

import (
	"context"
	"errors"

	"github.com/osquery/osquery-go/plugin/table"
)

func (m *Measurements) osCompat() error {
	return errors.New(_MEASUREMENT_NOT_COMPATIBLE)
}

func (m *Measurements) osColumns() []table.ColumnDefinition {
	return []table.ColumnDefinition{}
}

func (m *Measurements) osGenerate(ctx context.Context, queryContext table.QueryContext) ([]map[string]string, error) {
	return []map[string]string{{}}, errors.New(_MEASUREMENT_NOT_COMPATIBLE)
}
