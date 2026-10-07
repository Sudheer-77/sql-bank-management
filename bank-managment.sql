-- ============================================================
-- BANKING TRANSACTION MANAGEMENT SYSTEM
-- ============================================================
-- Technology: MySQL
-- Project Type: SQL Developer / Database Project
--
-- Main Features:
-- 1. Customer Management
-- 2. Account Management
-- 3. Transaction Management
-- 4. Deposit
-- 5. Withdrawal
-- 6. Fund Transfer
-- 7. Stored Procedures
-- 8. Stored Function
-- 9. Cursor
-- 10. Transactions / COMMIT / ROLLBACK
-- 11. Error Handling using SIGNAL
-- 12. Account Statement View
-- 13. Audit Trigger
-- ============================================================


-- ============================================================
-- 1. CREATE DATABASE
-- ============================================================

CREATE DATABASE IF NOT EXISTS sql_projects;

-- Select the database
USE sql_projects;


-- ============================================================
-- 2. CUSTOMER TABLE
-- ============================================================
-- Stores customer personal information
-- ============================================================

CREATE TABLE bank_customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,

    -- Customer full name
    customer_name VARCHAR(100) NOT NULL,

    -- Customer email address
    email VARCHAR(100) UNIQUE,

    -- Customer phone number
    phone VARCHAR(15) UNIQUE
);


-- ============================================================
-- 3. INSERT SAMPLE CUSTOMERS
-- ============================================================

INSERT INTO bank_customers
(customer_name, email, phone)
VALUES
('Virat Kohli', 'virat@gmail.com', '9876543210'),
('Rohit Sharma', 'rohit@gmail.com', '9876543211'),
('MS Dhoni', 'dhoni@gmail.com', '9876543212'),
('Jasprit Bumrah', 'bumrah@gmail.com', '9876543213'),
('Hardik Pandya', 'hardik@gmail.com', '9876543214');


-- Display all customers
SELECT *
FROM bank_customers;


-- ============================================================
-- 4. BANK ACCOUNT TABLE
-- ============================================================
-- Stores customer bank account information
-- ============================================================

CREATE TABLE bank_accounts (
    account_id INT PRIMARY KEY AUTO_INCREMENT,

    -- Customer who owns the account
    customer_id INT NOT NULL,

    -- Account type
    account_type VARCHAR(20) NOT NULL,

    -- Current account balance
    balance DECIMAL(12,2) DEFAULT 0.00,

    -- Account status
    status VARCHAR(20) DEFAULT 'ACTIVE',

    -- Connect account with customer
    CONSTRAINT fk_bank_account_customer
        FOREIGN KEY (customer_id)
        REFERENCES bank_customers(customer_id),

    -- Allow only SAVINGS or CURRENT
    CONSTRAINT chk_bank_account_type
        CHECK (account_type IN ('SAVINGS', 'CURRENT')),

    -- Balance cannot be negative
    CONSTRAINT chk_bank_balance
        CHECK (balance >= 0),

    -- Valid account statuses
    CONSTRAINT chk_bank_account_status
        CHECK (status IN ('ACTIVE', 'BLOCKED', 'CLOSED'))
);


-- ============================================================
-- 5. INSERT SAMPLE ACCOUNTS
-- ============================================================

INSERT INTO bank_accounts
(customer_id, account_type, balance, status)
VALUES
(1, 'SAVINGS', 50000.00, 'ACTIVE'),
(2, 'CURRENT', 85000.00, 'ACTIVE'),
(3, 'SAVINGS', 35000.00, 'ACTIVE'),
(4, 'SAVINGS', 62000.00, 'ACTIVE'),
(5, 'CURRENT', 95000.00, 'ACTIVE');


-- Display all accounts
SELECT *
FROM bank_accounts;


-- ============================================================
-- 6. BANK TRANSACTION TABLE
-- ============================================================
-- Stores deposit, withdrawal and transfer transactions
-- ============================================================

CREATE TABLE bank_transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,

    -- Account involved in transaction
    account_id INT NOT NULL,

    -- Type of transaction
    transaction_type VARCHAR(20) NOT NULL,

    -- Transaction amount
    amount DECIMAL(12,2) NOT NULL,

    -- Automatically stores date and time
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Transaction description
    description VARCHAR(200),

    -- Connect transaction with account
    CONSTRAINT fk_bank_transaction_account
        FOREIGN KEY (account_id)
        REFERENCES bank_accounts(account_id),

    -- Valid transaction types
    CONSTRAINT chk_bank_transaction_type
        CHECK (
            transaction_type IN
            ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER')
        ),

    -- Amount must be greater than zero
    CONSTRAINT chk_bank_transaction_amount
        CHECK (amount > 0)
);


-- ============================================================
-- 7. INSERT SAMPLE TRANSACTIONS
-- ============================================================

INSERT INTO bank_transactions
(account_id, transaction_type, amount, description)
VALUES
(1, 'DEPOSIT', 10000.00, 'Salary credit'),
(2, 'DEPOSIT', 15000.00, 'Business income'),
(3, 'WITHDRAWAL', 5000.00, 'ATM withdrawal'),
(4, 'DEPOSIT', 8000.00, 'Cash deposit'),
(5, 'WITHDRAWAL', 3000.00, 'ATM withdrawal');


-- Display transactions
SELECT *
FROM bank_transactions;


-- ============================================================
-- 8. CUSTOMER + ACCOUNT JOIN
-- ============================================================
-- Displays customer and account details together
-- ============================================================

SELECT
    c.customer_id,
    c.customer_name,
    a.account_id,
    a.account_type,
    a.balance,
    a.status
FROM bank_customers c
JOIN bank_accounts a
    ON c.customer_id = a.customer_id;


-- ============================================================
-- 9. CUSTOMER + ACCOUNT + TRANSACTION JOIN
-- ============================================================

SELECT
    c.customer_name,
    a.account_id,
    a.account_type,
    t.transaction_id,
    t.transaction_type,
    t.amount,
    t.transaction_date,
    t.description
FROM bank_customers c
JOIN bank_accounts a
    ON c.customer_id = a.customer_id
JOIN bank_transactions t
    ON a.account_id = t.account_id;


-- ============================================================
-- 10. BASIC TRANSACTION REPORTS
-- ============================================================

-- Display all deposits
SELECT *
FROM bank_transactions
WHERE transaction_type = 'DEPOSIT';


-- Display withdrawals greater than 3000
SELECT *
FROM bank_transactions
WHERE transaction_type = 'WITHDRAWAL'
AND amount > 3000;


-- Calculate total deposits
SELECT
    SUM(amount) AS total_deposits
FROM bank_transactions
WHERE transaction_type = 'DEPOSIT';


-- Calculate total withdrawals
SELECT
    SUM(amount) AS total_withdrawals
FROM bank_transactions
WHERE transaction_type = 'WITHDRAWAL';


-- ============================================================
-- 11. DEPOSIT PROCEDURE
-- ============================================================
-- Adds money to an account
-- Validates account and amount
-- Records transaction
-- ============================================================

DROP PROCEDURE IF EXISTS deposit_money;

DELIMITER $$

CREATE PROCEDURE deposit_money(
    IN p_account_id INT,
    IN p_amount DECIMAL(12,2)
)
BEGIN

    -- Stores account status
    DECLARE v_status VARCHAR(20);

    -- Stores account existence count
    DECLARE v_count INT DEFAULT 0;


    -- Check whether account exists
    SELECT COUNT(*)
    INTO v_count
    FROM bank_accounts
    WHERE account_id = p_account_id;


    -- Account does not exist
    IF v_count = 0 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Account does not exist';


    ELSE

        -- Get account status
        SELECT status
        INTO v_status
        FROM bank_accounts
        WHERE account_id = p_account_id;


        -- Check account status
        IF v_status <> 'ACTIVE' THEN

            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Account is not active';


        -- Check deposit amount
        ELSEIF p_amount <= 0 THEN

            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
            'Deposit amount must be greater than zero';


        ELSE

            -- Add money to account
            UPDATE bank_accounts
            SET balance = balance + p_amount
            WHERE account_id = p_account_id;


            -- Record deposit transaction
            INSERT INTO bank_transactions
            (
                account_id,
                transaction_type,
                amount,
                description
            )
            VALUES
            (
                p_account_id,
                'DEPOSIT',
                p_amount,
                'Money deposited'
            );


            -- Save changes
            COMMIT;

        END IF;

    END IF;

END $$

DELIMITER ;


-- ============================================================
-- 12. TEST DEPOSIT PROCEDURE
-- ============================================================

CALL deposit_money(1, 5000);


-- Check updated balance
SELECT
    account_id,
    balance
FROM bank_accounts
WHERE account_id = 1;


-- Check latest transactions
SELECT *
FROM bank_transactions
WHERE account_id = 1
ORDER BY transaction_id DESC;


-- ============================================================
-- 13. WITHDRAWAL PROCEDURE
-- ============================================================
-- Withdraws money from account
-- Checks account status and available balance
-- ============================================================

DROP PROCEDURE IF EXISTS withdraw_money;

DELIMITER $$

CREATE PROCEDURE withdraw_money(
    IN p_account_id INT,
    IN p_amount DECIMAL(12,2)
)
BEGIN

    -- Stores current balance
    DECLARE v_balance DECIMAL(12,2);

    -- Stores account status
    DECLARE v_status VARCHAR(20);

    -- Stores account existence count
    DECLARE v_count INT DEFAULT 0;


    -- Check account existence
    SELECT COUNT(*)
    INTO v_count
    FROM bank_accounts
    WHERE account_id = p_account_id;


    IF v_count = 0 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Account does not exist';


    ELSE

        -- Get account balance and status
        SELECT balance, status
        INTO v_balance, v_status
        FROM bank_accounts
        WHERE account_id = p_account_id;


        -- Check account status
        IF v_status <> 'ACTIVE' THEN

            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Account is not active';


        -- Check withdrawal amount
        ELSEIF p_amount <= 0 THEN

            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
            'Withdrawal amount must be greater than zero';


        -- Check available balance
        ELSEIF p_amount > v_balance THEN

            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient balance';


        ELSE

            -- Deduct money
            UPDATE bank_accounts
            SET balance = balance - p_amount
            WHERE account_id = p_account_id;


            -- Record withdrawal
            INSERT INTO bank_transactions
            (
                account_id,
                transaction_type,
                amount,
                description
            )
            VALUES
            (
                p_account_id,
                'WITHDRAWAL',
                p_amount,
                'Money withdrawn'
            );


            -- Save changes
            COMMIT;

        END IF;

    END IF;

END $$

DELIMITER ;


-- ============================================================
-- 14. TEST WITHDRAWAL PROCEDURE
-- ============================================================

CALL withdraw_money(1, 5000);


-- Check updated balance
SELECT
    account_id,
    balance
FROM bank_accounts
WHERE account_id = 1;


-- Test insufficient balance
-- This should generate an error
-- CALL withdraw_money(1, 100000);


-- ============================================================
-- 15. FUND TRANSFER PROCEDURE
-- ============================================================
-- Transfers money from one account to another
--
-- Uses:
-- START TRANSACTION
-- COMMIT
-- ROLLBACK
-- SIGNAL
--
-- If any validation fails, the transaction is rolled back.
-- ============================================================

DROP PROCEDURE IF EXISTS transfer_money;

DELIMITER $$

CREATE PROCEDURE transfer_money(
    IN p_from_account INT,
    IN p_to_account INT,
    IN p_amount DECIMAL(12,2)
)
BEGIN

    -- Sender balance
    DECLARE v_from_balance DECIMAL(12,2);

    -- Sender status
    DECLARE v_from_status VARCHAR(20);

    -- Receiver status
    DECLARE v_to_status VARCHAR(20);

    -- Sender existence count
    DECLARE v_from_count INT DEFAULT 0;

    -- Receiver existence count
    DECLARE v_to_count INT DEFAULT 0;


    -- Start transaction
    START TRANSACTION;


    -- Check sender account
    SELECT COUNT(*)
    INTO v_from_count
    FROM bank_accounts
    WHERE account_id = p_from_account;


    -- Check receiver account
    SELECT COUNT(*)
    INTO v_to_count
    FROM bank_accounts
    WHERE account_id = p_to_account;


    -- Sender does not exist
    IF v_from_count = 0 THEN

        ROLLBACK;

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Sender account does not exist';


    -- Receiver does not exist
    ELSEIF v_to_count = 0 THEN

        ROLLBACK;

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Receiver account does not exist';


    -- Same account
    ELSEIF p_from_account = p_to_account THEN

        ROLLBACK;

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Sender and receiver cannot be same';


    -- Invalid amount
    ELSEIF p_amount <= 0 THEN

        ROLLBACK;

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Transfer amount must be greater than zero';


    ELSE

        -- Get sender balance and status
        SELECT
            balance,
            status
        INTO
            v_from_balance,
            v_from_status
        FROM bank_accounts
        WHERE account_id = p_from_account;


        -- Get receiver status
        SELECT status
        INTO v_to_status
        FROM bank_accounts
        WHERE account_id = p_to_account;


        -- Sender must be active
        IF v_from_status <> 'ACTIVE' THEN

            ROLLBACK;

            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
            'Sender account is not active';


        -- Receiver must be active
        ELSEIF v_to_status <> 'ACTIVE' THEN

            ROLLBACK;

            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
            'Receiver account is not active';


        -- Check sender balance
        ELSEIF p_amount > v_from_balance THEN

            ROLLBACK;

            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
            'Insufficient balance';


        ELSE

            -- Deduct money from sender
            UPDATE bank_accounts
            SET balance = balance - p_amount
            WHERE account_id = p_from_account;


            -- Add money to receiver
            UPDATE bank_accounts
            SET balance = balance + p_amount
            WHERE account_id = p_to_account;


            -- Record sender transfer
            INSERT INTO bank_transactions
            (
                account_id,
                transaction_type,
                amount,
                description
            )
            VALUES
            (
                p_from_account,
                'TRANSFER',
                p_amount,
                CONCAT(
                    'Transfer to account ',
                    p_to_account
                )
            );


            -- Record receiver transfer
            INSERT INTO bank_transactions
            (
                account_id,
                transaction_type,
                amount,
                description
            )
            VALUES
            (
                p_to_account,
                'TRANSFER',
                p_amount,
                CONCAT(
                    'Transfer from account ',
                    p_from_account
                )
            );


            -- Save complete transfer
            COMMIT;

        END IF;

    END IF;

END $$

DELIMITER ;


-- ============================================================
-- 16. TEST FUND TRANSFER
-- ============================================================

-- Transfer 5000 from account 1 to account 2
CALL transfer_money(1, 2, 5000);


-- Check both balances
SELECT
    account_id,
    balance
FROM bank_accounts
WHERE account_id IN (1,2);


-- Check transfer transactions
SELECT
    transaction_id,
    account_id,
    transaction_type,
    amount,
    description
FROM bank_transactions
WHERE account_id IN (1,2)
ORDER BY transaction_id DESC
LIMIT 5;


-- ============================================================
-- 17. BALANCE FUNCTION
-- ============================================================
-- Returns the current balance of an account
-- ============================================================

DROP FUNCTION IF EXISTS get_account_balance;

DELIMITER $$

CREATE FUNCTION get_account_balance(
    p_account_id INT
)
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN

    -- Variable to store balance
    DECLARE v_balance DECIMAL(12,2);


    -- Retrieve account balance
    SELECT balance
    INTO v_balance
    FROM bank_accounts
    WHERE account_id = p_account_id;


    -- Return zero when account does not exist
    RETURN IFNULL(v_balance, 0);

END $$

DELIMITER ;


-- ============================================================
-- 18. TEST BALANCE FUNCTION
-- ============================================================

SELECT
    get_account_balance(1)
    AS current_balance;


-- ============================================================
-- 19. CURSOR PROCEDURE
-- ============================================================
-- Reads every account and displays its balance
-- ============================================================

DROP PROCEDURE IF EXISTS account_balance_report;

DELIMITER $$

CREATE PROCEDURE account_balance_report()
BEGIN

    -- Used to detect end of cursor
    DECLARE done INT DEFAULT 0;

    -- Stores account ID
    DECLARE v_account_id INT;

    -- Stores account balance
    DECLARE v_balance DECIMAL(12,2);


    -- Create cursor
    DECLARE account_cursor CURSOR FOR

        SELECT
            account_id,
            balance
        FROM bank_accounts;


    -- Handler executes when no more rows exist
    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET done = 1;


    -- Open cursor
    OPEN account_cursor;


    -- Read accounts one by one
    read_loop: LOOP

        -- Fetch one account
        FETCH account_cursor
        INTO v_account_id, v_balance;


        -- Stop when all records are processed
        IF done = 1 THEN
            LEAVE read_loop;
        END IF;


        -- Display current account
        SELECT
            v_account_id AS account_id,
            v_balance AS balance;

    END LOOP;


    -- Close cursor
    CLOSE account_cursor;

END $$

DELIMITER ;


-- ============================================================
-- 20. TEST CURSOR
-- ============================================================

CALL account_balance_report();


-- ============================================================
-- 21. ACCOUNT STATEMENT VIEW
-- ============================================================
-- Provides a combined customer/account/transaction report
-- ============================================================

CREATE OR REPLACE VIEW account_statement AS

SELECT
    c.customer_id,
    c.customer_name,

    a.account_id,
    a.account_type,
    a.balance,

    t.transaction_id,
    t.transaction_type,
    t.amount,
    t.transaction_date,
    t.description

FROM bank_customers c

JOIN bank_accounts a
    ON c.customer_id = a.customer_id

JOIN bank_transactions t
    ON a.account_id = t.account_id;


-- ============================================================
-- 22. TEST ACCOUNT STATEMENT VIEW
-- ============================================================

SELECT *
FROM account_statement;


-- ============================================================
-- 23. ACCOUNT AUDIT TABLE
-- ============================================================
-- Stores old and new account information whenever
-- the account table is updated.
-- ============================================================

CREATE TABLE bank_account_audit (
    audit_id INT PRIMARY KEY AUTO_INCREMENT,

    -- Account that was modified
    account_id INT NOT NULL,

    -- Balance before update
    old_balance DECIMAL(12,2),

    -- Balance after update
    new_balance DECIMAL(12,2),

    -- Status before update
    old_status VARCHAR(20),

    -- Status after update
    new_status VARCHAR(20),

    -- Time of modification
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================
-- 24. AUDIT TRIGGER
-- ============================================================
-- Automatically creates an audit record whenever
-- bank_accounts is updated.
-- ============================================================

DROP TRIGGER IF EXISTS trg_bank_account_audit;

DELIMITER $$

CREATE TRIGGER trg_bank_account_audit

AFTER UPDATE ON bank_accounts

FOR EACH ROW

BEGIN

    -- Store old and new account values
    INSERT INTO bank_account_audit
    (
        account_id,
        old_balance,
        new_balance,
        old_status,
        new_status
    )
    VALUES
    (
        OLD.account_id,
        OLD.balance,
        NEW.balance,
        OLD.status,
        NEW.status
    );

END $$

DELIMITER ;


-- ============================================================
-- 25. TEST AUDIT TRIGGER
-- ============================================================

-- This update will automatically create an audit record
CALL deposit_money(1, 1000);


-- Display audit records
SELECT *
FROM bank_account_audit
ORDER BY audit_id DESC;


-- ============================================================
-- 26. FINAL BANKING REPORTS
-- ============================================================

-- ------------------------------------------------------------
-- Report 1: All customers and accounts
-- ------------------------------------------------------------

SELECT
    c.customer_name,
    a.account_id,
    a.account_type,
    a.balance,
    a.status
FROM bank_customers c
JOIN bank_accounts a
    ON c.customer_id = a.customer_id;


-- ------------------------------------------------------------
-- Report 2: Total active bank balance
-- ------------------------------------------------------------

SELECT
    SUM(balance) AS total_bank_balance
FROM bank_accounts
WHERE status = 'ACTIVE';


-- ------------------------------------------------------------
-- Report 3: Total deposits
-- ------------------------------------------------------------

SELECT
    SUM(amount) AS total_deposits
FROM bank_transactions
WHERE transaction_type = 'DEPOSIT';


-- ------------------------------------------------------------
-- Report 4: Total withdrawals
-- ------------------------------------------------------------

SELECT
    SUM(amount) AS total_withdrawals
FROM bank_transactions
WHERE transaction_type = 'WITHDRAWAL';


-- ------------------------------------------------------------
-- Report 5: Transaction count by type
-- ------------------------------------------------------------

SELECT
    transaction_type,
    COUNT(*) AS total_transactions
FROM bank_transactions
GROUP BY transaction_type;


-- ------------------------------------------------------------
-- Report 6: Account with highest balance
-- ------------------------------------------------------------

SELECT
    c.customer_name,
    a.account_id,
    a.balance
FROM bank_customers c
JOIN bank_accounts a
    ON c.customer_id = a.customer_id
ORDER BY a.balance DESC
LIMIT 1;


-- ============================================================
-- 27. FINAL PROJECT VERIFICATION
-- ============================================================

-- Check customers
SELECT * FROM bank_customers;

-- Check accounts
SELECT * FROM bank_accounts;

-- Check transactions
SELECT * FROM bank_transactions;

-- Check audit records
SELECT * FROM bank_account_audit;

-- Check procedures
SHOW PROCEDURE STATUS
WHERE Db = 'sql_projects';

-- Check functions
SHOW FUNCTION STATUS
WHERE Db = 'sql_projects';

-- Check views
SHOW FULL TABLES
WHERE Table_type = 'VIEW';


-- ============================================================
-- END OF BANKING TRANSACTION MANAGEMENT SYSTEM
-- ============================================================