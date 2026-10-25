#!/usr/bin/env bash
# Start SQL Server, then apply schemas/rentmaster.sql on the first boot of a data volume.
set -euo pipefail

sql_pid=""

shutdown() {
    if [[ -n "${sql_pid}" ]]; then
        kill -TERM "${sql_pid}" 2>/dev/null || true
        wait "${sql_pid}" 2>/dev/null || true
    fi
}
trap shutdown SIGTERM SIGINT

/opt/mssql/bin/sqlservr &
sql_pid=$!

echo "Waiting for SQL Server..."
ready=0
for _ in $(seq 1 90); do
    if /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -C -Q "SELECT 1" >/dev/null 2>&1; then
        ready=1
        break
    fi
    sleep 2
done

if [[ "${ready}" -ne 1 ]]; then
    echo "SQL Server did not become ready in time." >&2
    exit 1
fi

marker="/var/opt/mssql/.rentmaster_schema_applied"
if [[ ! -f "${marker}" ]]; then
    echo "Applying RentMaster schema..."
    /opt/mssql-tools18/bin/sqlcmd \
        -S localhost \
        -U sa \
        -P "${MSSQL_SA_PASSWORD}" \
        -C \
        -b \
        -i /usr/src/rentmaster/rentmaster.sql
    touch "${marker}"
    echo "RentMaster schema applied."
else
    echo "RentMaster schema already applied."
fi

wait "${sql_pid}"
