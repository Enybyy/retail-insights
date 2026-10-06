# Methodology

## Source and unit of observation

The input is `Online Retail.xlsx`, retrieved from the official UCI repository. The source manifest records its download URL, attribution, byte count and SHA-256. Every pipeline run verifies the file against this checksum before reading it. The original file is retained locally without modification.

One observation is an invoice line. Orders are distinct purchase invoice identifiers within the relevant scope. Customer IDs and invoice numbers are imported as text. Dates are read as their recorded wall-clock calendar date without assigning a business timezone that the source does not document.

## Ledger partition

The classification is evaluated in this order. It assigns exactly one class to each row; quality flags themselves can overlap.

1. Invalid core fields: missing invoice, stock code, timestamp, quantity or price, or nonfinite quantity/price.
2. Negative unit price.
3. Zero unit price.
4. Zero quantity.
5. Cancellation invoice with positive quantity.
6. Codes outside the merchandise heuristic.
7. Negative merchandise quantities: credits and adjustments.
8. Remaining positive merchandise lines: purchases.

Merchandise candidates match `^[0-9]{5}[A-Za-z]*$`. This excludes explicit service and administrative codes but can also exclude legitimate specialty items. The excluded-code table makes the boundary reviewable. A production analysis would replace the heuristic with a maintained product master.

Line value is signed quantity multiplied by recorded unit price. Values are calculated without rounding every line; presentation rounds GBP totals to two decimal places. Some administrative entries use more than two decimal places in their source price.

## Repetitions and anonymous purchases

Exact repetitions are detected across all eight original source fields before derived fields are added. The first occurrence is preserved in both views. The primary ledger keeps all repeated rows because the file has no unique invoice-line key. The sensitivity view removes later exact repeats. Neither policy establishes what the retailer actually intended to bill.

Missing customer IDs remain eligible for sales. RFM and customer concentration use only identified merchandise purchases. Identification coverage is identified purchase value divided by total merchandise purchase value. This separates a sales question from a customer-attribution question.

## Purchase sales and credits

Gross merchandise purchase sales are the sum of positive purchase line values. Recorded credit value is the absolute total of negative merchandise credit/adjustment values. Sales less recorded credits subtracts these two amounts within the observation window. It is not profit, an accounting revenue reconciliation or a matched return rate.

Product tables rank codes with observed purchases and show their recorded credits separately. Credits for a code with no purchase in the observed window are not used to invent purchases. The full ledger remains authoritative for aggregate merchandise credit totals.

The large-line review searches for credits sharing customer ID, product code, calendar day, absolute quantity and unit price. Customer ID must be present. The result is a candidate count, not a one-to-one match or a netting rule. Multiple purchases can share one candidate credit.

## Period coverage

Each month records its observed first and last day. A month is complete within the source coverage when these equal its calendar boundaries. This assumes the file represents the available history inside its documented start/end window; it does not prove that the originating ledger had no omitted invoices. December 2011 is incomplete and is marked separately in charts and tables.

## Customer scoring

For each identified buyer:

- Recency: snapshot date minus latest observed merchandise purchase day.
- Frequency: distinct merchandise purchase invoices.
- Monetary: gross merchandise purchase value, including exact repeats in the primary policy.

The snapshot date is one day after the final source date. For a vector of length `n`, the ascending score is `min(5, floor((rank_min - 1) / n * 5) + 1)`. `rank_min` assigns the minimum rank to tied observations. Recency reverses this score as `6 - ascending_score`. This keeps equal values together, so quintile sizes may differ.

Rules are applied sequentially:

| Segment | Condition |
| --- | --- |
| Champions | R >= 4, F >= 4 and M >= 4 |
| At risk repeat buyers | R <= 2 and F >= 3 |
| Loyal buyers | F >= 4, after earlier rules |
| Recent low-frequency buyers | R >= 4 and F <= 2, after earlier rules |
| Other buyers | Remaining identified buyers |

The labels are deterministic business hypotheses. They have not been calibrated against future purchases, customer lifetime value or churn outcomes.

Customer concentration ranks identified buyers by purchase value descending. The top-10% count is rounded up to the next whole buyer. The share denominator is identified purchase sales, not total sales including anonymous purchases.

## Verification and recommended follow-up

The pipeline asserts complete ledger partitioning and signed value reconciliation. Monthly, country and product purchase totals must reconcile to the same purchase amount. Segment counts and amounts reconcile to the identified customer view. RFM dates and frequency must be valid, and removing repeated positive purchases cannot increase gross purchase sales.

An Excel fixture checks classification, repeated rows, anonymous sales coverage and monetary sensitivity. Separate scoring checks verify monotonicity and equal treatment of ties. The report consumes the saved R results instead of manually copied values.

Before operational use, obtain original invoice links, verified return reasons, product eligibility, complete recent history, margin/fulfilment costs and customer contact permissions. Measure proposed campaign benefits against a holdout group. The present analysis makes no causal or realised-benefit claims.
