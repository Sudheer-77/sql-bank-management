# Banking Transaction Management System

A database-driven Banking Transaction Management System developed using **MySQL** to manage customers, bank accounts, transactions, fund transfers, and account auditing.

## 🛠️ Technologies Used

* MySQL
* SQL
* Stored Procedures
* Stored Functions
* Cursors
* Triggers
* Views
* Transactions
* COMMIT / ROLLBACK
* Exception Handling
* Joins
* Constraints

## 📌 Project Features

* Customer management
* Bank account management
* Deposit money
* Withdraw money
* Fund transfer between accounts
* Account balance checking
* Transaction history
* Account statements
* Audit logging
* Invalid account validation
* Insufficient balance validation
* Active/blocked/closed account validation
* Transaction rollback on errors

## 🗄️ Database Tables

### 1. `bank_customers`

Stores customer information.

**Columns:**

* `customer_id`
* `customer_name`
* `email`
* `phone`

### 2. `bank_accounts`

Stores bank account details and current balances.

**Columns:**

* `account_id`
* `customer_id`
* `account_type`
* `balance`
* `status`

### 3. `bank_transactions`

Stores deposit, withdrawal, and transfer transactions.

**Columns:**

* `transaction_id`
* `account_id`
* `transaction_type`
* `amount`
* `transaction_date`
* `description`

### 4. `bank_account_audit`

Stores account balance and status changes for auditing.

**Columns:**

* `audit_id`
* `account_id`
* `old_balance`
* `new_balance`
* `old_status`
* `new_status`
* `action_time`

## ⚙️ Stored Procedures

### `deposit_money()`

Deposits money into an active bank account and records the transaction.

### `withdraw_money()`

Withdraws money after checking account status and available balance.

### `transfer_money()`

Transfers money between two accounts using a database transaction.

The procedure uses:

* `START TRANSACTION`
* `COMMIT`
* `ROLLBACK`
* Account validation
* Balance validation
* Error handling

## 🔧 Stored Function

### `get_account_balance()`

Returns the current balance of a specified bank account.

## 🔄 Cursor

### `account_balance_report()`

Uses a MySQL cursor to process bank accounts and generate an account balance report.

## 🔔 Trigger

### `trg_bank_account_audit`

Automatically records old and new account balances whenever an account is updated.

## 👁️ View

### `account_statement`

Provides a combined account statement containing:

* Customer details
* Account details
* Transaction details
* Transaction amount
* Transaction date
* Transaction description

## 🔐 Data Validation

The project handles several invalid scenarios:

* Account does not exist
* Account is not active
* Invalid transaction amount
* Insufficient balance
* Same sender and receiver account
* Invalid fund transfer

## 🔄 Transaction Management

Fund transfers use transaction control to maintain data consistency.

```sql
START TRANSACTION;

-- Deduct amount from sender
-- Add amount to receiver
-- Record transactions

COMMIT;
```

If an error occurs:

```sql
ROLLBACK;
```

This ensures that a transfer is completed completely or not performed at all.

## 📊 Sample Operations

### Deposit

```sql
CALL deposit_money(1, 5000);
```

### Withdrawal

```sql
CALL withdraw_money(1, 2000);
```

### Fund Transfer

```sql
CALL transfer_money(1, 2, 5000);
```

### Check Balance

```sql
SELECT get_account_balance(1);
```

### Account Statement

```sql
SELECT *
FROM account_statement;
```

## 🎯 Learning Outcomes

Through this project, I practiced:

* Relational database design
* Primary and foreign keys
* Constraints
* SQL CRUD operations
* Joins
* Stored procedures
* Stored functions
* Cursors
* Triggers
* Views
* Transaction management
* COMMIT and ROLLBACK
* Exception handling
* Database auditing

## 👨‍💻 Author

**Sudheer Kumar Dash**

GitHub: [Sudheer-77](https://github.com/Sudheer-77)

## 📄 Project

This project was developed as a hands-on SQL project to demonstrate practical database development and SQL programming skills for an entry-level **SQL Developer / Database Developer** role.
