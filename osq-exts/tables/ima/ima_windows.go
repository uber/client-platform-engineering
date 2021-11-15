package ima

import (
	"context"
	"errors"

	"github.com/osquery/osquery-go/plugin/table"
)

func (m *IMA) osCompat() error {
	return errors.New(_IMA_NOT_COMPATIBLE)
}

func (m *IMA) osColumns() []table.ColumnDefinition {
	return []table.ColumnDefinition{}
}

func (m *IMA) osGenerate(ctx context.Context, queryContext table.QueryContext) ([]map[string]string, error) {
	return []map[string]string{{}}, errors.New(_IMA_NOT_COMPATIBLE)
}
