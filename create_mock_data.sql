DO $$
DECLARE
    v_user_id bigint;
    v_role_id int;
    v_service_id int;
    v_booking_id bigint;
BEGIN
    -- 1. Get user by phone or create one
    SELECT id INTO v_user_id FROM users WHERE phone = '0901234567' LIMIT 1;
    
    IF v_user_id IS NULL THEN
        -- Create User (Password: Test@123)
        INSERT INTO users (phone, password_hash, status, created_at, updated_at)
        VALUES ('0901234567', '$2b$10$Giji6eQDBsvOOrCPINHC9.pVBy13pbepDfqaTq2TxUiTvTtbms9Gy', 'active', NOW(), NOW())
        RETURNING id INTO v_user_id;
        
        -- Create User Profile
        INSERT INTO user_profiles (user_id, full_name, created_at, updated_at)
        VALUES (v_user_id, 'Test User', NOW(), NOW());
    ELSE
        -- Update password for existing user to ensure login works
        UPDATE users 
        SET password_hash = '$2b$10$Giji6eQDBsvOOrCPINHC9.pVBy13pbepDfqaTq2TxUiTvTtbms9Gy'
        WHERE id = v_user_id;

        -- Ensure profile exists for existing user
        INSERT INTO user_profiles (user_id, full_name, created_at, updated_at)
        VALUES (v_user_id, 'Test User', NOW(), NOW())
        ON CONFLICT (user_id) DO NOTHING;
    END IF;

    -- 2. Handle Role
    -- Get or create 'user' role
    SELECT id INTO v_role_id FROM roles WHERE name = 'user' LIMIT 1;
    
    IF v_role_id IS NULL THEN
        INSERT INTO roles (name, description, created_at)
        VALUES ('user', 'Regular user', NOW())
        RETURNING id INTO v_role_id;
    END IF;

    -- Assign role to user
    INSERT INTO user_roles (user_id, role_id, created_at)
    VALUES (v_user_id, v_role_id, NOW())
    ON CONFLICT (user_id, role_id) DO NOTHING;

    -- 3. Ensure Wallet exists
    INSERT INTO wallets (user_id, balance, currency, version, created_at, updated_at)
    VALUES (v_user_id, 5000000, 'VND', 0, NOW(), NOW())
    ON CONFLICT (user_id) DO NOTHING;

    -- 4. Get service or create one
    SELECT id INTO v_service_id FROM services WHERE name = 'Dọn dẹp nhà' LIMIT 1;
    
    IF v_service_id IS NULL THEN
        INSERT INTO services (name, description, base_price, created_at, updated_at)
        VALUES ('Dọn dẹp nhà', 'Dịch vụ dọn dẹp', 200000, NOW(), NOW())
        RETURNING id INTO v_service_id;
    END IF;

    -- 5. Create Booking
    INSERT INTO bookings (
        code, 
        customer_id, 
        service_id, 
        status, 
        scheduled_at, 
        address_text, 
        location, 
        estimated_price, 
        created_at, 
        updated_at
    )
    VALUES (
        'BK_' || floor(random() * 100000)::text,
        v_user_id,
        v_service_id,
        'pending',
        NOW() + INTERVAL '1 day',
        'Hà Nội',
        ST_SetSRID(ST_MakePoint(105, 21), 4326),
        200000,
        NOW(),
        NOW()
    )
    RETURNING id INTO v_booking_id;
    
    RAISE NOTICE 'SUCCESS: Created Booking ID: % for User ID: %', v_booking_id, v_user_id;
    RAISE NOTICE 'LOGIN INFO: Phone: 0901234567, Password: Test@123';
END $$;
