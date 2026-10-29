INSERT INTO branches (branch_name, city) VALUES
    ('Tunis Central', 'Tunis'),
    ('Sousse Branch', 'Sousse'),
    ('Sfax Branch', 'Sfax');

INSERT INTO customers (branch_id, first_name, last_name, phone) VALUES
    (1, 'Ahmed', 'Ben Ali', '+21611111111'),
    (1, 'Salma', 'Trabelsi', '+21611111112'),
    (2, 'Nabil', 'Haddad', '+21621111111'),
    (3, 'Leila', 'Khemiri', '+21631111111');

INSERT INTO customer_credentials (customer_id, email, login, password_hash) VALUES
    (1, 'ahmed.tunis@email.com', 'ahmed_tunis', 'hashed_password_1'),
    (2, 'salma.tunis@email.com', 'salma_tunis', 'hashed_password_2'),
    (3, 'nabil.sousse@email.com', 'nabil_sousse', 'hashed_password_3'),
    (4, 'leila.sfax@email.com', 'leila_sfax', 'hashed_password_4');

INSERT INTO accounts (customer_id, branch_id, account_number, account_type, balance, status) VALUES
    (1, 1, 'TN0010001', 'CHECKING', 1200.00, 'ACTIVE'),
    (2, 1, 'TN0010002', 'SAVINGS', 3500.00, 'ACTIVE'),
    (3, 2, 'TN0020001', 'CHECKING', 900.00, 'ACTIVE'),
    (4, 3, 'TN0030001', 'SAVINGS', 4200.00, 'ACTIVE');

INSERT INTO transaction_logs (from_account_id, to_account_id, amount, transaction_type, description, status) VALUES
    (1, 2, 200.00, 'TRANSFER', 'Initial transfer between Tunis customers', 'COMPLETED'),
    (3, 4, 150.00, 'TRANSFER', 'Cross-branch transfer to Sfax', 'COMPLETED');

UPDATE accounts
SET balance = balance - 200.00
WHERE account_id = 1;

UPDATE accounts
SET balance = balance + 200.00
WHERE account_id = 2;

UPDATE accounts
SET balance = balance - 150.00
WHERE account_id = 3;

UPDATE accounts
SET balance = balance + 150.00
WHERE account_id = 4;

SELECT * FROM customers;
SELECT * FROM accounts;
SELECT * FROM transaction_logs;
