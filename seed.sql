CREATE TABLE branches (
    branch_id SERIAL PRIMARY KEY,
    branch_name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE customers (
    customer_id BIGSERIAL PRIMARY KEY,
    branch_id INT NOT NULL REFERENCES branches(branch_id),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE customer_credentials (
    credential_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL UNIQUE REFERENCES customers(customer_id),
    email VARCHAR(255) NOT NULL UNIQUE,
    login VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE accounts (
    account_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(customer_id),
    branch_id INT NOT NULL REFERENCES branches(branch_id),
    account_number VARCHAR(20) NOT NULL UNIQUE,
    account_type VARCHAR(30) NOT NULL CHECK (account_type IN ('CHECKING', 'SAVINGS', 'BUSINESS')),
    balance NUMERIC(14,2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'CLOSED', 'FROZEN')),
    opened_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE transaction_logs (
    transaction_id BIGSERIAL PRIMARY KEY,
    from_account_id BIGINT REFERENCES accounts(account_id),
    to_account_id BIGINT REFERENCES accounts(account_id),
    amount NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    transaction_type VARCHAR(30) NOT NULL CHECK (transaction_type IN ('TRANSFER', 'DEPOSIT', 'WITHDRAWAL')),
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'COMPLETED' CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_customers_branch_id ON customers(branch_id);
CREATE INDEX idx_accounts_customer_id ON accounts(customer_id);
CREATE INDEX idx_accounts_branch_id ON accounts(branch_id);
CREATE INDEX idx_transaction_logs_from_account ON transaction_logs(from_account_id);
CREATE INDEX idx_transaction_logs_to_account ON transaction_logs(to_account_id);
CREATE INDEX idx_transaction_logs_created_at ON transaction_logs(created_at);

CREATE OR REPLACE FUNCTION transfer_money(
    p_from_account_id BIGINT,
    p_to_account_id BIGINT,
    p_amount NUMERIC(14,2),
    p_description TEXT
)
RETURNS TABLE (
    transaction_id BIGINT,
    from_balance NUMERIC(14,2),
    to_balance NUMERIC(14,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_from_branch_id INT;
    v_to_branch_id INT;
    v_from_balance NUMERIC(14,2);
    v_to_balance NUMERIC(14,2);
    v_transaction_id BIGINT;
BEGIN
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Amount must be greater than zero';
    END IF;

    SELECT branch_id, balance INTO v_from_branch_id, v_from_balance
    FROM accounts
    WHERE account_id = p_from_account_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source account not found';
    END IF;

    SELECT branch_id, balance INTO v_to_branch_id, v_to_balance
    FROM accounts
    WHERE account_id = p_to_account_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Destination account not found';
    END IF;

    IF v_from_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient funds';
    END IF;

    UPDATE accounts
    SET balance = balance - p_amount
    WHERE account_id = p_from_account_id;

    UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_id = p_to_account_id;

    INSERT INTO transaction_logs (
        from_account_id,
        to_account_id,
        amount,
        transaction_type,
        description,
        status
    )
    VALUES (
        p_from_account_id,
        p_to_account_id,
        p_amount,
        'TRANSFER',
        p_description,
        'COMPLETED'
    )
    RETURNING transaction_id INTO v_transaction_id;

    SELECT balance INTO v_from_balance
    FROM accounts
    WHERE account_id = p_from_account_id;

    SELECT balance INTO v_to_balance
    FROM accounts
    WHERE account_id = p_to_account_id;

    RETURN QUERY
    SELECT v_transaction_id, v_from_balance, v_to_balance;
END;
$$;

CREATE VIEW customer_summary AS
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    b.branch_name,
    b.city,
    cc.email,
    cc.login
FROM customers c
JOIN branches b ON b.branch_id = c.branch_id
LEFT JOIN customer_credentials cc ON cc.customer_id = c.customer_id;

CREATE VIEW branch_account_summary AS
SELECT
    b.branch_id,
    b.branch_name,
    COUNT(a.account_id) AS total_accounts,
    SUM(a.balance) AS total_balance
FROM branches b
LEFT JOIN accounts a ON a.branch_id = b.branch_id
GROUP BY b.branch_id, b.branch_name;
