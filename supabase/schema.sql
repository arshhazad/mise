-- Mise: Premium Chef Meal Subscription Schema

-- USERS (Extends Supabase Auth)
CREATE TABLE public.users (
    id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
    full_name TEXT,
    phone_number TEXT UNIQUE,
    office_address TEXT,
    dietary_preferences TEXT[],
    allergies TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- MENU ITEMS
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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- DAILY MENUS
CREATE TABLE public.daily_menus (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    date DATE UNIQUE NOT NULL,
    base_menu_item_id UUID REFERENCES public.menu_items(id),
    swap_menu_item_id UUID REFERENCES public.menu_items(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- SUBSCRIPTIONS
CREATE TYPE subscription_status AS ENUM ('active', 'paused', 'expired', 'cancelled');
CREATE TABLE public.subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) NOT NULL,
    status subscription_status DEFAULT 'active' NOT NULL,
    meals_remaining INTEGER DEFAULT 24 NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    auto_renew BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ORDERS
CREATE TABLE public.orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) NOT NULL,
    daily_menu_id UUID REFERENCES public.daily_menus(id) NOT NULL,
    type TEXT CHECK (type IN ('base', 'swap', 'add_on')) NOT NULL,
    status TEXT CHECK (status IN ('pending', 'delivered', 'cancelled')) DEFAULT 'pending' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- SWAPS
CREATE TABLE public.swaps (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) NOT NULL,
    original_order_id UUID REFERENCES public.orders(id),
    daily_menu_id UUID REFERENCES public.daily_menus(id) NOT NULL,
    fee_amount DECIMAL(10,2) DEFAULT 50.00,
    payment_status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ADD-ONS
CREATE TABLE public.add_ons (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) NOT NULL,
    daily_menu_id UUID REFERENCES public.daily_menus(id) NOT NULL,
    price DECIMAL(10,2) DEFAULT 120.00,
    payment_status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- DELIVERIES
CREATE TABLE public.deliveries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID REFERENCES public.orders(id),
    delivery_partner_name TEXT,
    tracking_url TEXT,
    photo_proof_url TEXT,
    delivered_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- PAUSES
CREATE TABLE public.pauses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    subscription_id UUID REFERENCES public.subscriptions(id) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RATINGS
CREATE TABLE public.ratings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) NOT NULL,
    item_id UUID, -- Can be menu_item or delivery 
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    feedback TEXT,
    tags TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- PAYMENTS
CREATE TABLE public.payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'INR',
    provider TEXT, -- 'razorpay', 'stripe'
    transaction_id TEXT UNIQUE,
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS (ROW LEVEL SECURITY)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own data" ON public.users FOR SELECT USING (auth.uid() = id);

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own subscriptions" ON public.subscriptions FOR SELECT USING (auth.uid() = user_id);

ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can view menu items" ON public.menu_items FOR SELECT USING (true);

ALTER TABLE public.daily_menus ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can view daily menus" ON public.daily_menus FOR SELECT USING (true);
