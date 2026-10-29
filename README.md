# MiniBanquing SQL Project

This project turns the mini banking scenario into a PostgreSQL-based database design.

## Project goals
- Model a simple bank with multiple branches
- Support customer and account management
- Implement safe money transfers with pessimistic locking
- Show how customers can be fragmented by branch
- Provide sample data and useful SQL queries

## Database design

The project includes:
- `branches`: branch information
- `customers`: branch-based customer records
- `customer_credentials`: email/login/security info separated from the main customer table
- `accounts`: account records and balances
- `transaction_logs`: transfer and transaction history
- `transfer_money(...)`: a stored procedure that locks the source and destination accounts before updating balances

## Why this matches the scenario

### Concurrency control
The `transfer_money` stored function uses `SELECT ... FOR UPDATE` to lock both account rows before any balance modification. This is a pessimistic locking strategy, which is appropriate for banking transactions where correctness is more important than concurrency.

### Distributed design
Customer records are naturally split by branch using `branch_id`, which matches horizontal fragmentation. Sensitive login/email data is stored separately in `customer_credentials`, which mirrors vertical partitioning.

## Run the project

1. Create the database:
   ```bash
   createdb minibanquing
   ```

2. Create the tables and stored procedure:
   ```bash
   psql -d minibanquing -f schema.sql
   ```

3. Insert sample data:
   ```bash
   psql -d minibanquing -f seed.sql
   ```

4. Run example queries:
   ```bash
   psql -d minibanquing -f queries.sql
   ```

## Example transfer

```sql
SELECT * FROM transfer_money(1001, 1002, 250.00, 'Transfer to savings');
```

This transaction will lock both accounts, ensure enough funds exist, and update the balances atomically.
