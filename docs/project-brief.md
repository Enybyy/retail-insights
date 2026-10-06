# Retail Insights

An independent portfolio study of sales quality and customer purchasing patterns in a UK online retailer, using the public UCI Online Retail dataset. The historical window runs from December 2010 to December 2011; it does not describe current trading conditions.

## Decisions the study supports

1. Identify which data issues change reported sales and which records require investigation.
2. Separate merchandise purchases, credit notes and administrative entries before comparing products and markets.
3. Describe customer concentration and prioritise retention hypotheses using observed purchasing history.

The study produces evidence for decisions. It does not measure the effect of a campaign, prove causes of customer inactivity or estimate profit without cost data.

## Deliverables

- A reproducible RStudio project with an immutable source file and verified checksum.
- A line-level audit, reconciled sales tables and documented inclusion rules.
- Monthly sales, market concentration, product rankings and RFM customer segments.
- A report with charts and an Excel workbook containing aggregate results.
- A detailed methodology, data dictionary, decision log and portfolio summary.

## Publication sequence

Complete and review the analysis locally first. Review charts, source attribution and all benefit claims before publication. GitHub and the external portfolio publication are later milestones. Customer-level extracts remain local by default; aggregate tables and figures are sufficient to explain the public study.

## Completion criteria

The pipeline runs from a fresh R session. Every source row has one ledger classification. Category counts and amounts reconcile to the source. Primary results and duplicate sensitivity are labelled separately. The partial final month is marked. RFM excludes unidentified customers without removing their sales from sales totals. All reported figures are generated from saved analysis results.
