# Analysis decisions

| Decision | Rationale | Implication |
| --- | --- | --- |
| Preserve repeated rows in the primary ledger | The source contains no unique invoice-line key | Report sensitivity after exact-row deduplication separately |
| Retain anonymous purchases in sales | A missing customer ID does not invalidate an invoice | Customer findings cover only identified buyers |
| Separate merchandise and administrative entries | Codes such as postage and manual adjustments are not directly comparable to products | Merchandise sales differ from full-ledger turnover |
| Treat negative lines as recorded credits or adjustments | Original invoices are not reliably linked | Credit value is not a matched product return rate |
| Use gross purchase value for RFM monetary score | Credit timing and invoice matching remain unresolved | RFM is a purchase-behaviour segmentation, not customer profitability |
| Score equal values equally | Arbitrary customer-ID sorting should not change segments | Score bins may have unequal sizes |
| Mark December 2011 as partial | Source ends on 9 December | Do not interpret its monthly total as a full-month fall |
| Keep benefits as testable recommendations | No intervention or campaign results are available | No claim of realised revenue uplift or savings |

Merchandise candidates match five leading digits followed by optional letters. This is an explicit heuristic, not an official product master. Review the exported excluded-code table before using product findings operationally.
