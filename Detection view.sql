-- 03_detection_views.sql : one view per rule, plus a union view and reporting views
-- R01: high-value debit
CREATE OR REPLACE VIEW v_hit_r01 AS
SELECT account_id, txn_id,
'Debit of ' || amount || ' INR (threshold 200000)' AS detail
FROM bank_txn
WHERE txn_type = 'DEBIT'
AND status = 'SUCCESS'
AND amount >= 200000;
-- R02: velocity burst. The third debit within 10 minutes is flagged (10/1440.0 day = 10 min)
CREATE OR REPLACE VIEW v_hit_r02 AS
SELECT account_id, txn_id,
'Third debit within 10 minutes; amount ' || amount AS detail
FROM (SELECT t.account_id, t.txn_id, t.amount, t.txn_ts,
LAG(t.txn_ts, 2) OVER (PARTITION BY t.account_id
ORDER BY t.txn_ts, t.txn_id) AS ts_two_back
FROM bank_txn t
WHERE t.txn_type = 'DEBIT' AND t.status = 'SUCCESS')
WHERE ts_two_back IS NOT NULL
AND txn_ts - ts_two_back <= 10/1440.0;
-- R03: structuring of branch cash deposits just under an illustrative 50000 threshold
CREATE OR REPLACE VIEW v_hit_r03 AS
SELECT account_id,
MAX(txn_id) AS txn_id,
COUNT(*) || ' branch deposits of 45000-49999 on '
|| TO_CHAR(TRUNC(txn_ts), 'YYYY-MM-DD')
|| ', total ' || SUM(amount) AS detail
FROM bank_txn
WHERE txn_type = 'CREDIT'
AND channel = 'BRANCH'
AND status = 'SUCCESS'
AND amount BETWEEN 45000 AND 49999.99
GROUP BY account_id, TRUNC(txn_ts)
HAVING COUNT(*) >= 3;
-- R04: card/ATM use in two different countries within 60 minutes
CREATE OR REPLACE VIEW v_hit_r04 AS
SELECT b.account_id, b.txn_id,
'Card/ATM use in ' || a.country_code || ' then ' || b.country_code
9
|| ' ' || ROUND((b.txn_ts - a.txn_ts) * 1440) || ' minutes apart' AS detail
FROM bank_txn a
JOIN bank_txn b
ON b.account_id = a.account_id
AND b.txn_ts > a.txn_ts
AND b.txn_ts - a.txn_ts <= 60/1440.0
AND b.country_code <> a.country_code
WHERE a.channel IN ('CARD','ATM') AND b.channel IN ('CARD','ATM')
AND a.status = 'SUCCESS' AND b.status = 'SUCCESS';
-- R05: large transaction after more than 180 idle days
CREATE OR REPLACE VIEW v_hit_r05 AS
SELECT account_id, txn_id,
'Activity after ' || ROUND(txn_ts - prev_ts) || ' idle days; amount ' || amount AS detail
FROM (SELECT t.account_id, t.txn_id, t.amount, t.txn_ts,
LAG(t.txn_ts) OVER (PARTITION BY t.account_id
ORDER BY t.txn_ts, t.txn_id) AS prev_ts
FROM bank_txn t
WHERE t.status = 'SUCCESS')
WHERE prev_ts IS NOT NULL
AND txn_ts - prev_ts > 180
AND amount >= 50000;
-- R06: debit more than 5 times the running average of earlier debits (needs 3+ earlier debits)
CREATE OR REPLACE VIEW v_hit_r06 AS
SELECT account_id, txn_id,
'Debit ' || amount || ' vs earlier average ' || ROUND(avg_prior, 2) AS detail
FROM (SELECT t.account_id, t.txn_id, t.amount,
AVG(t.amount) OVER (PARTITION BY t.account_id
ORDER BY t.txn_ts, t.txn_id
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS avg_prior,
COUNT(t.amount) OVER (PARTITION BY t.account_id
ORDER BY t.txn_ts, t.txn_id
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS prior_cnt
FROM bank_txn t
WHERE t.txn_type = 'DEBIT' AND t.status = 'SUCCESS')
WHERE prior_cnt >= 3
AND amount > 5 * avg_prior;
CREATE OR REPLACE VIEW v_rule_hits AS
SELECT 'R01' AS rule_code, account_id, txn_id, detail FROM v_hit_r01
UNION ALL SELECT 'R02', account_id, txn_id, detail FROM v_hit_r02
UNION ALL SELECT 'R03', account_id, txn_id, detail FROM v_hit_r03
UNION ALL SELECT 'R04', account_id, txn_id, detail FROM v_hit_r04
UNION ALL SELECT 'R05', account_id, txn_id, detail FROM v_hit_r05
UNION ALL SELECT 'R06', account_id, txn_id, detail FROM v_hit_r06;
-- Daily debit total above the account limit (reported, not turned into an alert)
CREATE OR REPLACE VIEW v_daily_limit_breach AS
SELECT t.account_id,
TO_CHAR(TRUNC(t.txn_ts), 'YYYY-MM-DD') AS txn_day,
SUM(t.amount) AS day_total,
a.daily_limit
FROM bank_txn t
JOIN account a ON a.account_id = t.account_id
WHERE t.txn_type = 'DEBIT' AND t.status = 'SUCCESS'
GROUP BY t.account_id, TRUNC(t.txn_ts), a.daily_limit
HAVING SUM(t.amount) > a.daily_limit;
-- Alert workload by rule and status
CREATE OR REPLACE VIEW v_alert_summary AS
SELECT r.rule_code, r.rule_name, r.severity, a.status, COUNT(*) AS alert_count
FROM fraud_alert a
JOIN fraud_rule r ON r.rule_id = a.rule_id
GROUP BY r.rule_code, r.rule_name, r.severity, a.status;
-- Alerts per customer, including customers with none
CREATE OR REPLACE VIEW v_customer_alert_load AS
SELECT c.customer_id, c.full_name, c.risk_rating,
COUNT(a.alert_id) AS total_alerts,
COUNT(CASE WHEN a.status = 'OPEN' THEN 1 END) AS open_alerts
FROM customer c
LEFT JOIN account ac ON ac.customer_id = c.customer_id
LEFT JOIN fraud_alert a ON a.account_id = ac.account_id
GROUP BY c.customer_id, c.full_name, c.risk_ratin
