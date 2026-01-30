-- MISE MASTER REPAIR & SEED SCRIPT
-- RUN THIS IN SUPABASE SQL EDITOR TO FIX SCHEMA MISMATCHES

-- 1. DROP EVERYTHING (Clean Slate)
DROP TABLE IF EXISTS public.deliveries CASCADE;
DROP TABLE IF EXISTS public.add_ons CASCADE;
DROP TABLE IF EXISTS public.swaps CASCADE;
DROP TABLE IF EXISTS public.orders CASCADE;
DROP TABLE IF EXISTS public.subscriptions CASCADE;
DROP TABLE IF EXISTS public.daily_menus CASCADE;
DROP TABLE IF EXISTS public.menu_items CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;
DROP TABLE IF EXISTS public.pauses CASCADE;
DROP TABLE IF EXISTS public.ratings CASCADE;
DROP TABLE IF EXISTS public.payments CASCADE;

-- 2. CREATE TYPES
DO $$ BEGIN
    CREATE TYPE subscription_status AS ENUM ('active', 'paused', 'expired', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE meal_category AS ENUM ('Breakfast', 'Lunch', 'Snacks', 'Dinner');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. TABLES
CREATE TABLE public.users (
    id UUID PRIMARY KEY,
    full_name TEXT,
    phone_number TEXT UNIQUE,
    addresses JSONB DEFAULT '[]'::jsonb,
    selected_address_tag TEXT DEFAULT 'Office',
    dietary_preferences TEXT[],
    default_preference TEXT CHECK (default_preference IN ('Veg', 'Non-Veg')) DEFAULT 'Veg',
    allergies TEXT[],
    onboarding_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE public.menu_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    ingredients TEXT[],
    calories INTEGER,
    protein INTEGER,
    carbs INTEGER,
    fats INTEGER,
    image_url TEXT,
    is_premium BOOLEAN DEFAULT FALSE,
    default_category meal_category DEFAULT 'Lunch',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE public.daily_menus (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    date DATE NOT NULL,
    meal_type meal_category DEFAULT 'Lunch' NOT NULL,
    veg_menu_item_id UUID REFERENCES public.menu_items(id),
    non_veg_menu_item_id UUID REFERENCES public.menu_items(id),
    alt_menu_item_id UUID REFERENCES public.menu_items(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(date, meal_type)
);

CREATE TABLE public.subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) NOT NULL,
    status subscription_status DEFAULT 'active' NOT NULL,
    meals_remaining INTEGER DEFAULT 24 NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    end_date DATE NOT NULL,
    auto_renew BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE public.orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) NOT NULL,
    daily_menu_id UUID REFERENCES public.daily_menus(id) NOT NULL,
    type TEXT CHECK (type IN ('base', 'swap', 'add_on')) NOT NULL,
    status TEXT CHECK (status IN ('pending', 'delivered', 'cancelled')) DEFAULT 'pending' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, daily_menu_id)
);

CREATE TABLE public.add_ons (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) NOT NULL,
    daily_menu_id UUID REFERENCES public.daily_menus(id) NOT NULL,
    name TEXT,
    price DECIMAL(10,2) DEFAULT 120.00,
    payment_status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, daily_menu_id, name)
);

CREATE TABLE public.payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'INR',
    provider TEXT,
    transaction_id TEXT UNIQUE,
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. INSERT DEV ADMIN USER (Crucial for Verification)
INSERT INTO public.users (id, full_name, phone_number, default_preference)
VALUES ('00000000-0000-0000-0000-000000000000', 'Dev Admin (Bypassed)', '+919666350033', 'Veg');

-- 4.5 INSERT DUMMY SUBSCRIPTION
INSERT INTO public.subscriptions (user_id, status, meals_remaining, end_date)
VALUES ('00000000-0000-0000-0000-000000000000', 'active', 24, CURRENT_DATE + INTERVAL '30 days')
ON CONFLICT DO NOTHING;

-- 5. SEED 100 LUNCH ITEMS
DO $$
DECLARE
    i INT;
    names TEXT[] := ARRAY['Paneer Tikka Box', 'Chicken Curry Thali', 'Quinoa Salad', 'Dal Makhani Special', 'Pasta Alfredo', 'Fish Masala Box', 'Egg Curry Lunch', 'Vegetable Biryani', 'Kadhai Paneer', 'Butter Chicken'];
    img_urls TEXT[] := ARRAY[
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
        'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=500',
        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500',
        'https://images.unsplash.com/photo-1603894584115-f70f2cd87122?w=500'
    ];
BEGIN
    FOR i IN 1..100 LOOP
        INSERT INTO public.menu_items (name, description, calories, protein, carbs, fats, image_url, default_category)
        VALUES (
            names[(i % 10) + 1] || ' #' || i,
            'Daily healthy lunch balanced with macros for a perfect day.',
            450 + (i % 100),
            25 + (i % 20),
            50 + (i % 30),
            15 + (i % 10),
            img_urls[(i % 4) + 1],
            'Lunch'
        );
    END LOOP;
END $$;

-- 6. SCHEDULE 100 DAYS
DO $$
DECLARE
    curr_date DATE := CURRENT_DATE;
    v_id UUID;
    nv_id UUID;
    a_id UUID;
BEGIN
    FOR i IN 0..99 LOOP
        SELECT id INTO v_id FROM public.menu_items OFFSET (i % 100) LIMIT 1;
        SELECT id INTO nv_id FROM public.menu_items OFFSET ((i + 1) % 100) LIMIT 1;
        SELECT id INTO a_id FROM public.menu_items OFFSET ((i + 2) % 100) LIMIT 1;

        INSERT INTO public.daily_menus (date, meal_type, veg_menu_item_id, non_veg_menu_item_id, alt_menu_item_id)
        VALUES (curr_date + i, 'Lunch', v_id, nv_id, a_id);
    END LOOP;
END $$;

-- 7. ENABLE RLS (Simplified for Dev)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow All Dev" ON public.users FOR ALL USING (true);
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow All Dev" ON public.menu_items FOR ALL USING (true);
ALTER TABLE public.daily_menus ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow All Dev" ON public.daily_menus FOR ALL USING (true);
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow All Dev" ON public.orders FOR ALL USING (true);
ALTER TABLE public.add_ons ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow All Dev" ON public.add_ons FOR ALL USING (true);
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow All Dev" ON public.payments FOR ALL USING (true);
