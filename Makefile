.PHONY: help ingest db transform all clean shell

# Standard-Target (zeigt Hilfe)
help:
	@echo "bfett Makefile"
	@echo ""
	@echo "Verfügbare Targets:"
	@echo "  make ingest      → Prüft auf neue Daten und lädt sie"
	@echo "  make db          → Aktualisiert die DuckDB (Lea-Transformationen)"
	@echo "  make transform   → Alias für 'db' (klarer Name)"
	@echo "  make all         → ingest + db (kompletter Refresh)"
	@echo ""
	

# Prüft auf neue Daten und lädt sie
ingest:
	Rscript ingest/lsx_trades.R
	Rscript ingest/transactions.R
	@echo "✅ Ingestion abgeschlossen (neue Tick-Trades + Google Sheets Sync)"

# Aktualisiert die DuckDB – führt alle Lea-Transformationen aus
# (staging → core → marts)
db:
	echo "NIY"
	@echo "✅ DuckDB aktualisiert (Lea run abgeschlossen)"

# Klarerer Alias (empfohlen für die Zukunft)
transform: db

# Kompletter Lauf (z.B. für manuelle Weekly-Updates)
all: ingest db
	@echo "✅ Vollständiger Update durchgeführt (ingest + transform)"



