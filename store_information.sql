-- Store Information Table for Bancon App
-- This table stores all store/customer information collected by agents

CREATE TABLE store_information (
    -- Primary Key
    store_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Form Fields
    date DATE NOT NULL,
    store_name VARCHAR(255) NOT NULL,
    purchaser_owner VARCHAR(255) NOT NULL,
    contact_number VARCHAR(50) NOT NULL,
    complete_address TEXT NOT NULL,
    territory VARCHAR(100) NOT NULL,
    store_classification VARCHAR(100) NOT NULL,
    tin VARCHAR(50) NOT NULL,
    payment_term VARCHAR(100) NOT NULL,
    price_level VARCHAR(50) NOT NULL,
    agent_code VARCHAR(50) NOT NULL,
    sales_person VARCHAR(255) NOT NULL,
    
    -- Attachments (store file paths or URLs)
    store_picture_url TEXT,
    business_permit_url TEXT,
    
    -- Map Coordinates
    map_latitude DECIMAL(10, 8),
    map_longitude DECIMAL(11, 8),
    
    -- Metadata
    agent_id UUID NOT NULL REFERENCES users_db(user_id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status INTEGER DEFAULT 1 CHECK (status IN (1, 2)) -- 1=active, 2=inactive
);

-- Create indexes for frequently queried columns
CREATE INDEX idx_store_information_agent_id ON store_information(agent_id);
CREATE INDEX idx_store_information_date ON store_information(date);
CREATE INDEX idx_store_information_status ON store_information(status);
CREATE INDEX idx_store_information_territory ON store_information(territory);
CREATE INDEX idx_store_information_created_at ON store_information(created_at);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_store_information_updated_at 
    BEFORE UPDATE ON store_information 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE store_information ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Agents can only view their own store information
CREATE POLICY "Agents can view own stores"
    ON store_information
    FOR SELECT
    USING (
        agent_id = auth.uid()
        OR
        EXISTS (
            SELECT 1 FROM users_db
            WHERE users_db.user_id = auth.uid()
            AND users_db.role IN ('admin', 'supervisor', 'encoder')
        )
    );

-- Agents can only insert their own store information
CREATE POLICY "Agents can insert own stores"
    ON store_information
    FOR INSERT
    WITH CHECK (agent_id = auth.uid());

-- Agents can only update their own store information, admins can update all
CREATE POLICY "Agents can update own stores"
    ON store_information
    FOR UPDATE
    USING (
        agent_id = auth.uid()
        OR
        EXISTS (
            SELECT 1 FROM users_db
            WHERE users_db.user_id = auth.uid()
            AND users_db.role IN ('admin', 'supervisor')
        )
    );

-- Only admins can delete store information
CREATE POLICY "Admins can delete stores"
    ON store_information
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM users_db
            WHERE users_db.user_id = auth.uid()
            AND users_db.role = 'admin'
        )
    );

-- Comments for documentation
COMMENT ON TABLE store_information IS 'Stores customer/store information collected by agents in the field';
COMMENT ON COLUMN store_information.store_id IS 'Unique identifier for each store record';
COMMENT ON COLUMN store_information.agent_id IS 'Reference to the agent who created this record';
COMMENT ON COLUMN store_information.status IS '1=active, 2=inactive/deleted';
COMMENT ON COLUMN store_information.map_latitude IS 'GPS latitude coordinate of store location';
COMMENT ON COLUMN store_information.map_longitude IS 'GPS longitude coordinate of store location';
