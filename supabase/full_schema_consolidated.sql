-- MISE: CONSOLIDATED SCHEMA & MIGRATION
-- Run this in your Supabase SQL Editor (Control + Enter)

-- 1. DROP EXISTING IF NEEDED (CAUTION)
-- DROP TABLE IF EXISTS public.deliveries CASCADE;
-- DROP TABLE IF EXISTS public.add_ons CASCADE;
-- DROP TABLE IF EXISTS public.swaps CASCADE;
-- DROP TABLE IF EXISTS public.orders CASCADE;
-- DROP TABLE IF EXISTS public.subscriptions CASCADE;
-- DROP TABLE IF EXISTS public.daily_menus CASCADE;
-- DROP TABLE IF EXISTS public.menu_items CASCADE;
-- DROP TABLE IF EXISTS public.users CASCADE;
-- DROP TYPE IF EXISTS subscription_status;
-- DROP TYPE IF EXISTS meal_category;

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

-- 3. USERS (Extends Supabase Auth)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
    full_name TEXT,
    phone_number TEXT UNIQUE,
    office_address TEXT,
    dietary_preferences TEXT[],
    allergies TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. MENU ITEMS
CREATE TABLE IF NOT EXISTS public.menu_items (
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

-- 5. DAILY MENUS
CREATE TABLE IF NOT EXISTS public.daily_menus (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    date DATE NOT NULL,
    meal_type meal_category DEFAULT 'Lunch' NOT NULL,
    veg_menu_item_id UUID REFERENCES public.menu_items(id),
    non_veg_menu_item_id UUID REFERENCES public.menu_items(id),
    alt_menu_item_id UUID REFERENCES public.menu_items(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(date, meal_type)
);

-- 6. SUBSCRIPTIONS
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) NOT NULL,
    status subscription_status DEFAULT 'active' NOT NULL,
    meals_remaining INTEGER DEFAULT 24 NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    auto_renew BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 7. ORDERS
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) NOT NULL,
    daily_menu_id UUID REFERENCES public.daily_menus(id) NOT NULL,
    type TEXT CHECK (type IN ('base', 'swap', 'add_on')) NOT NULL,
    status TEXT CHECK (status IN ('pending', 'delivered', 'cancelled')) DEFAULT 'pending' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 8. SWAPS
CREATE TABLE IF NOT EXISTS public.swaps (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) NOT NULL,
    original_order_id UUID REFERENCES public.orders(id),
    daily_menu_id UUID REFERENCES public.daily_menus(id) NOT NULL,
    fee_amount DECIMAL(10,2) DEFAULT 50.00,
    payment_status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 9. ADD-ONS
CREATE TABLE IF NOT EXISTS public.add_ons (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) NOT NULL,
    daily_menu_id UUID REFERENCES public.daily_menus(id) NOT NULL,
    price DECIMAL(10,2) DEFAULT 120.00,
    payment_status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 10. DELIVERIES
CREATE TABLE IF NOT EXISTS public.deliveries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID REFERENCES public.orders(id),
    delivery_partner_name TEXT,
    tracking_url TEXT,
    photo_proof_url TEXT,
    delivered_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 11. PAUSES
CREATE TABLE IF NOT EXISTS public.pauses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    subscription_id UUID REFERENCES public.subscriptions(id) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 12. RATINGS
CREATE TABLE IF NOT EXISTS public.ratings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) NOT NULL,
    item_id UUID, -- Can be menu_item or delivery 
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    feedback TEXT,
    tags TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 13. PAYMENTS
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'INR',
    provider TEXT, -- 'razorpay', 'stripe'
    transaction_id TEXT UNIQUE,
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 14. RLS (ROW LEVEL SECURITY)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own data" ON public.users;
CREATE POLICY "Users can view their own data" ON public.users FOR SELECT USING (auth.uid() = id);

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own subscriptions" ON public.subscriptions;
CREATE POLICY "Users can view their own subscriptions" ON public.subscriptions FOR SELECT USING (auth.uid() = user_id);

ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Everyone can view menu items" ON public.menu_items;
CREATE POLICY "Everyone can view menu items" ON public.menu_items FOR SELECT USING (true);

ALTER TABLE public.daily_menus ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Everyone can view daily menus" ON public.daily_menus;
CREATE POLICY "Everyone can view daily menus" ON public.daily_menus FOR SELECT USING (true);
