package ima

import (
	"context"
	"github.com/osquery/osquery-go/plugin/table"
)

const (
	_ENABLED      = "enabled"
	_COUNT        = "runtime_measurements_count"
	_VIOLATIONS   = "violations"
	_IMA_BASEPATH = "/sys/kernel/security/ima/"
)

func (m *IMA) osCompat() error {
	return nil
}

func (m *IMA) osColumns() []table.ColumnDefinition {
	return []table.ColumnDefinition{
		table.TextColumn(_ENABLED),
		table.BigIntColumn(_COUNT),
		table.BigIntColumn(_VIOLATIONS),
	}
}

func (m *IMA) osGenerate(ctx context.Context, queryContext table.QueryContext) ([]map[string]string, error) {
	return []map[string]string{
		{
			_ENABLED:    pathExists(_IMA_BASEPATH),
			_COUNT:      readFile(_IMA_BASEPATH, _COUNT),
			_VIOLATIONS: readFile(_IMA_BASEPATH, _VIOLATIONS),
		},
	}, nil
}
