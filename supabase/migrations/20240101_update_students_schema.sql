-- Add new columns to students table if they don't exist
DO $$ 
BEGIN
    -- Add email if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'students' AND column_name = 'email') THEN
        ALTER TABLE students ADD COLUMN email text;
    END IF;

    -- Add phone if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'students' AND column_name = 'phone') THEN
        ALTER TABLE students ADD COLUMN phone text;
    END IF;

    -- Add payment_status if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'students' AND column_name = 'payment_status') THEN
        ALTER TABLE students ADD COLUMN payment_status text DEFAULT 'pending';
    END IF;

    -- Add payment_amount if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'students' AND column_name = 'payment_amount') THEN
        ALTER TABLE students ADD COLUMN payment_amount numeric(12,2);
    END IF;
END $$;
