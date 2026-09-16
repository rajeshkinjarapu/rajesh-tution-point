-- Fix NULL columns in auth.users that cause GoTrue "500: Database error querying schema"
UPDATE auth.users
SET 
  confirmation_token = COALESCE(confirmation_token, ''),
  recovery_token = COALESCE(recovery_token, ''),
  email_change_token_new = COALESCE(email_change_token_new, ''),
  email_change = COALESCE(email_change, ''),
  email_change_token_current = COALESCE(email_change_token_current, ''),
  phone_change = COALESCE(phone_change, ''),
  phone_change_token = COALESCE(phone_change_token, ''),
  reauthentication_token = COALESCE(reauthentication_token, ''),
  raw_app_meta_data = COALESCE(raw_app_meta_data, '{"provider":"email","providers":["email"]}'::jsonb),
  raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb),
  is_sso_user = COALESCE(is_sso_user, false),
  aud = COALESCE(aud, 'authenticated'),
  role = COALESCE(role, 'authenticated'),
  email_confirmed_at = COALESCE(email_confirmed_at, now());

-- Drop any lingering triggers on auth.users that block authentication/update
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
