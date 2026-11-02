Listing A: 01_schema.sql
Exact file contents, 103 lines. Oracle-compatible; identity columns need 12c or later.
-- 01_schema.sql : Oracle-compatible DDL (identity columns need Oracle 12c or later)
CREATE TABLE customer (
customer_id VARCHAR2(10) NOT NULL,
full_name VARCHAR2(60) NOT NULL,
city VARCHAR2(40),
kyc_status VARCHAR2(10) DEFAULT 'PENDING' NOT NULL,
risk_rating VARCHAR2(10) DEFAULT 'LOW' NOT NULL,
created_on DATE NOT NULL,
CONSTRAINT pk_customer PRIMARY KEY (customer_id),
CONSTRAINT ck_customer_kyc CHECK (kyc_status IN ('VERIFIED','PENDING','EXPIRED')),
CONSTRAINT ck_customer_risk CHECK (risk_rating IN ('LOW','MEDIUM','HIGH'))
);
CREATE TABLE account (
account_id VARCHAR2(10) NOT NULL,
customer_id VARCHAR2(10) NOT NULL,
account_type VARCHAR2(10) NOT NULL,
status VARCHAR2(10) DEFAULT 'ACTIVE' NOT NULL,
opened_on DATE NOT NULL,
balance NUMBER(14,2) DEFAULT 0 NOT NULL,
daily_limit NUMBER(14,2) NOT NULL,
CONSTRAINT pk_account PRIMARY KEY (account_id),
CONSTRAINT fk_account_customer FOREIGN KEY (customer_id)
REFERENCES customer (customer_id),
CONSTRAINT ck_account_type CHECK (account_type IN ('SAVINGS','CURRENT')),
CONSTRAINT ck_account_status CHECK (status IN ('ACTIVE','DORMANT','FROZEN','CLOSED')),
CONSTRAINT ck_account_balance CHECK (balance >= 0),
CONSTRAINT ck_account_limit CHECK (daily_limit > 0)
);
CREATE TABLE bank_txn (
txn_id NUMBER(10) NOT NULL,
account_id VARCHAR2(10) NOT NULL,
txn_type VARCHAR2(6) NOT NULL,
amount NUMBER(14,2) NOT NULL,
txn_ts DATE NOT NULL, -- Oracle DATE stores date and time to the second
channel VARCHAR2(10) NOT NULL,
country_code CHAR(2) DEFAULT 'IN' NOT NULL,
status VARCHAR2(10) DEFAULT 'SUCCESS' NOT NULL,
CONSTRAINT pk_bank_txn PRIMARY KEY (txn_id),
CONSTRAINT fk_txn_account FOREIGN KEY (account_id)
REFERENCES account (account_id),
CONSTRAINT ck_txn_type CONSTRAINT ck_txn_amount CONSTRAINT ck_txn_channel CONSTRAINT ck_txn_status CONSTRAINT ck_txn_country CHECK (txn_type IN ('DEBIT','CREDIT')),
CHECK (amount > 0),
CHECK (channel IN ('UPI','NEFT','CARD','ATM','BRANCH')),
CHECK (status IN ('SUCCESS','FAILED','REVERSED')),
CHECK (country_code = UPPER(country_code))
);
CREATE TABLE fraud_rule (
rule_id NUMBER(4) NOT NULL,
rule_code VARCHAR2(6) NOT NULL,
rule_name VARCHAR2(40) NOT NULL,
severity VARCHAR2(6) NOT NULL,
description VARCHAR2(200),
is_active CHAR(1) DEFAULT 'Y' NOT NULL,
CONSTRAINT pk_fraud_rule PRIMARY KEY (rule_id),
CONSTRAINT uq_fraud_rule_cd UNIQUE (rule_code),
CONSTRAINT ck_rule_severity CHECK (severity IN ('LOW','MEDIUM','HIGH')),
CONSTRAINT ck_rule_active CHECK (is_active IN ('Y','N'))
);
CREATE TABLE fraud_alert (
alert_id NUMBER(10) GENERATED ALWAYS AS IDENTITY,
rule_id NUMBER(4) NOT NULL,
account_id VARCHAR2(10) NOT NULL,
txn_id NUMBER(10) NOT NULL,
raised_at DATE DEFAULT SYSDATE NOT NULL,
status VARCHAR2(15) DEFAULT 'OPEN' NOT NULL,
details VARCHAR2(200),
reviewed_by VARCHAR2(30),
reviewed_at DATE,
CONSTRAINT pk_fraud_alert PRIMARY KEY (alert_id),
6
CONSTRAINT uq_alert_rule_txn UNIQUE (rule_id, txn_id),
CONSTRAINT fk_alert_rule FOREIGN KEY (rule_id) REFERENCES fraud_rule (rule_id),
CONSTRAINT fk_alert_account FOREIGN KEY (account_id) REFERENCES account (account_id),
CONSTRAINT fk_alert_txn FOREIGN KEY (txn_id) REFERENCES bank_txn (txn_id),
CONSTRAINT ck_alert_status CHECK (status IN
('OPEN','UNDER_REVIEW','CONFIRMED_FRAUD','FALSE_POSITIVE')),
CONSTRAINT ck_alert_reviewer CHECK (status IN ('OPEN','UNDER_REVIEW')
OR reviewed_by IS NOT NULL)
);
CREATE TABLE audit_log (
audit_id NUMBER(10) GENERATED ALWAYS AS IDENTITY,
table_name VARCHAR2(30) NOT NULL,
record_id VARCHAR2(30) NOT NULL,
action VARCHAR2(20) NOT NULL,
old_value VARCHAR2(100),
new_value VARCHAR2(100),
changed_by VARCHAR2(30) NOT NULL,
changed_at DATE DEFAULT SYSDATE NOT NULL,
CONSTRAINT pk_audit_log PRIMARY KEY (audit_id)
);
-- Indexes. Oracle indexes PRIMARY KEY / UNIQUE columns automatically but NOT foreign keys.
CREATE INDEX ix_txn_acct_ts ON bank_txn (account_id, txn_ts);
CREATE INDEX ix_txn_ts ON bank_txn (txn_ts);
CREATE INDEX ix_account_cust ON account (customer_id);
CREATE INDEX ix_alert_status ON fraud_alert (status);
CREATE INDEX ix_alert_account ON fraud_alert (account_id);
CREATE INDEX ix_alert_txn ON fraud_alert (txn_id);
