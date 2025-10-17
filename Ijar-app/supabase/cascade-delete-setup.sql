-- ============================================
-- ACCOUNT DELETION SETUP
-- ============================================
-- Run this SQL in your Supabase SQL Editor to enable account deletion
-- ============================================

-- Step 1: Set up CASCADE deletes
-- When a user is deleted, automatically delete all their related data

ALTER TABLE query
DROP CONSTRAINT IF EXISTS query_user_id_fkey,
ADD CONSTRAINT query_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

ALTER TABLE user_property_action
DROP CONSTRAINT IF EXISTS user_property_action_user_id_fkey,
ADD CONSTRAINT user_property_action_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

ALTER TABLE device_tokens
DROP CONSTRAINT IF EXISTS device_tokens_user_id_fkey,
ADD CONSTRAINT device_tokens_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

-- Step 2: Create function to delete user account
-- This function runs with elevated privileges (SECURITY DEFINER)
-- so authenticated users can delete their own accounts

CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Delete the user from auth.users
  -- CASCADE will automatically delete all related data
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_user_account() TO authenticated;
