#!/usr/bin/env bash
set -euo pipefail

sqlcmd=/opt/mssql-tools18/bin/sqlcmd

if [[ ! "${APP_DB_PASSWORD:-}" =~ ^[A-Za-z0-9@#%+=._!-]{12,64}$ ]]; then
  echo 'APP_DB_PASSWORD must have 12-64 letters, digits or @#%+=._!- characters.' >&2
  exit 1
fi

database_state=$("$sqlcmd" -S db -U sa -C -b -h -1 -W \
  -Q "SET NOCOUNT ON; SELECT CASE WHEN DB_ID(N'BlueStock') IS NULL THEN 'missing' ELSE 'present' END;")
database_state=$(printf '%s' "$database_state" | tr -d '\r')

if [[ "$database_state" == 'missing' ]]; then
  "$sqlcmd" -S db -U sa -C -b -i database/init.sql
elif [[ "$database_state" == 'present' ]]; then
  "$sqlcmd" -S db -U sa -C -b -d BlueStock -Q \
    "IF OBJECT_ID(N'dbo.sp_HoanTatTraHang', N'P') IS NULL THROW 51000, N'BlueStock schema is incomplete.', 1;"
else
  echo 'Cannot determine BlueStock database state.' >&2
  exit 1
fi

# CREATE OR ALTER keeps existing Compose volumes current after a code update.
# A new database already has these triggers from init.sql.
"$sqlcmd" -S db -U sa -C -b -d BlueStock \
  -i database/migrations/027_inventory_guard_triggers.sql

# Add the accountant reconciliation table and refresh role grants for existing volumes.
"$sqlcmd" -S db -U sa -C -b -d BlueStock \
  -i database/migrations/028_accounting_reconciliation.sql

# Inbound completion delegates the lot upper bound to the table trigger.
"$sqlcmd" -S db -U sa -C -b -d BlueStock \
  -i database/migrations/029_inbound_trigger_boundary.sql

# Replace the draft-line guard with the category storage-history guard.
"$sqlcmd" -S db -U sa -C -b -d BlueStock \
  -i database/migrations/030_category_storage_guard.sql

# Keep the shorter inbound procedure last so older migrations cannot overwrite it.
"$sqlcmd" -S db -U sa -C -b -d BlueStock \
  -i database/migrations/031_simplify_inbound_completion.sql

"$sqlcmd" -S db -U sa -C -b -d BlueStock -i database/seed/demo.sql
"$sqlcmd" -S db -U sa -C -b -i database/docker-app-login.sql
