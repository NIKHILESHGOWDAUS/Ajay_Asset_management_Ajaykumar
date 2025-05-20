 CREATE TABLE IF NOT EXISTS asset_requests (
                id SERIAL PRIMARY KEY,
                employee_id VARCHAR(50) NOT NULL,
                employee_name VARCHAR(100) NOT NULL,
                email VARCHAR(50) NOT NULL,
                request_date DATE NOT NULL,
                asset_type VARCHAR(50) NOT NULL,
                asset_name VARCHAR(40) NOT NULL,
                details TEXT NOT NULL,
                status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'Approved', 'Rejected')),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );