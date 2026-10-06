# Data dictionary

| Source field | Meaning | Handling |
| --- | --- | --- |
| InvoiceNo | Invoice identifier; a C prefix indicates cancellation | Import as text; preserve leading letters |
| StockCode | Item identifier | Import as text; classify merchandise candidates separately from service and adjustment codes |
| Description | Recorded item description | Keep the original text; allow missing descriptions |
| Quantity | Signed quantity on the invoice line | Positive for purchases; negative lines require separate credit/adjustment classification |
| InvoiceDate | Recorded invoice date and time | Import as a wall-clock time; source timezone is undocumented |
| UnitPrice | Recorded unit price in GBP | Flag nonpositive values; multiply by signed quantity for line value |
| CustomerID | Customer identifier | Import as text; retain missing IDs for sales, exclude them from customer segmentation |
| Country | Recorded country | Retain source value; do not treat this as verified customer residence |

The file is a line-item ledger: 541,909 rows do not mean 541,909 orders. Exact repeated rows cannot be confirmed as accidental duplicates without a line identifier. The primary analysis preserves them and a separate sensitivity view removes repetitions.
