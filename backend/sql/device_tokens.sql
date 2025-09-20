-- Create device_tokens table for storing iOS push notification tokens
CREATE TABLE IF NOT EXISTS device_tokens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_token TEXT NOT NULL,
    device_type TEXT DEFAULT 'ios',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure one token per user-device combination
    UNIQUE(user_id, device_token)
);

-- Add RLS (Row Level Security)
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access their own device tokens
CREATE POLICY "Users can manage their own device tokens" ON device_tokens
    FOR ALL USING (auth.uid() = user_id);

-- Create index for faster lookups
CREATE INDEX idx_device_tokens_user_id ON device_tokens(user_id);

-- Update trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_device_tokens_updated_at
    BEFORE UPDATE ON device_tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();