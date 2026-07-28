---
name: hledger-finance
description: Manage a personal hledger finance journal: validate entries, safely import and categorise bank/card exports, reconcile accounts, and create expense, income, and balance reports or visualisations. Use when working with hledger journals or personal-finance imports.
---

# Hledger Finance

## Start safely

1. Read the repository's `AGENTS.md` or equivalent instructions before editing.
2. Validate before and after changes:

```sh
hledger -f 2026.journal check
hledger -f 2026.journal check accounts payees
```

Do not add commodity symbols, balance assertions, or new account names unless the user requests the accounting change.

## Import workflow

Keep raw bank/card exports ignored by git. If this journal has `rules/` and `imports/`, use the review-first workflow:

```sh
./test/test_imports.sh
hledger -f rules/revolut.rules -f rules/bbva.rules -f rules/amex.rules print | less
hledger -f 2026.journal import \
  rules/revolut.rules rules/bbva.rules rules/amex.rules --dry
```

Append only after the dry run has been reviewed:

```sh
hledger -f 2026.journal import \
  rules/revolut.rules rules/bbva.rules rules/amex.rules
hledger -f 2026.journal check
```

Use all import rules in one command so transactions are appended in chronological order. `hledger import` keeps local `.latest.*` state to skip previously imported records; do not delete it without understanding the duplicate-import effect.

## Categorisation

Inspect fallback classifications before importing:

```sh
hledger -f rules/revolut.rules -f rules/bbva.rules -f rules/amex.rules \
  print acct:expenses:miscellaneous
```

Add merchant patterns to the appropriate `rules/*.rules` file, then rerun the importer test and dry run. Prefer existing account names. Ask before guessing ambiguous transfers, refunds, loan repayments, or income.

## Reports

Useful built-in reports:

```sh
hledger -f 2026.journal bal --tree
hledger -f 2026.journal bal -M expenses
hledger -f 2026.journal is -M
hledger -f 2026.journal reg assets:bbva
hledger -f 2026.journal bal -M assets liabilities
```

For graphs, export machine-readable monthly data instead of scraping terminal output:

```sh
hledger -f 2026.journal bal -M expenses --output-format=csv
hledger -f 2026.journal is -M --output-format=csv
```

If the journal provides `bin/finance-dashboard`, generate its self-contained local dashboard with:

```sh
./bin/finance-dashboard 2026.journal reports/finance-dashboard.html
```

Keep generated charts out of version control unless the user explicitly wants them committed. Confirm the desired period, metrics, and output format before creating a dashboard or image.
