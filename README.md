# SQL-Based-Banking-Fraud-Detection
A SQL-based banking fraud detection and transaction monitoring system using relational database design, fraud detection rules, SQL views, and alert generation.
SQL-Based Banking Fraud Detection and Transaction Monitoring System

Overview

This project demonstrates a SQL-based banking fraud detection and transaction monitoring system developed as part of the Database Systems course (BCSE302L).

The system analyses banking transactions using predefined SQL rules to identify potentially suspicious activities and generate fraud alerts.

Features

* Relational database design with six tables.
* SQL constraints and indexes for data integrity and query performance.
* Six rule-based fraud detection mechanisms.
* SQL views for identifying suspicious transactions.
* Automated fraud alert generation.
* Duplicate prevention during alert generation.
* Audit logging and transaction monitoring.
* PL/SQL procedures and triggers.

Fraud Detection Rules

1. High-value debit transactions.
2. Rapid transaction velocity.
3. Cash deposit structuring.
4. Rapid country changes.
5. Dormant account reactivation.
6. Unusual transaction amount deviation.

Database Tables

* customer
* account
* bank_txn
* fraud_rule
* fraud_alert
* audit_log

Sample Dataset

The project uses synthetic banking data:

* 6 sample customers
* 7 bank accounts
* 37 sample transactions
* 6 fraud detection rules

No real customer or banking information is used.

Technologies

* SQL
* Oracle SQL / PL/SQL
* SQLite for adapted validation
* Python validation harness

Validation

The adapted SQLite cross-check generated 7 fraud alerts. Re-running alert generation did not create duplicates, and balance reconciliation reported zero mismatches.

Note: The SQL scripts were syntax-checked, and selected logic was cross-checked using an adapted SQLite validation harness. The project was not executed on an Oracle server; Oracle PL/SQL procedures and triggers have not been fully runtime-tested.

Project Structure

* sql/ – SQL scripts
* report/ – Project report
* screenshots/ – Execution and output screenshots

Academic Context

Developed as a Database Systems course case study (BCSE302L).

Disclaimer

This is an academic demonstration using synthetic data. It is not a production banking or fraud detection system.
