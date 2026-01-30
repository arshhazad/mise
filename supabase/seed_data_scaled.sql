-- SCALED SEED DATA FOR MISE (100 LUNCH ITEMS)
-- This script resets and populates the database with 100 lunch options.

-- 1. Clear existing data
TRUNCATE public.daily_menus CASCADE;
TRUNCATE public.menu_items CASCADE;

-- 2. Insert 100 Lunch Items
DO $$
DECLARE
    i INT;
    meal_names TEXT[] := ARRAY[
        'Home-Style Thali', 'Paneer Butter Masala', 'Dal Makhani Bowl', 'Vegetable Biryani', 
        'Healthy Salad Bowl', 'Grilled Chicken Salad', 'Pasta Primavera', 'Rajma Chawal', 
        'Chole Kulche', 'Kadahi Paneer Bowl', 'Quinoa Stir Fry', 'Lentil Soup', 
        'Mushroom Risotto', 'Tofu Stir Fry', 'Chickpea Curry', 'Aloo Gobi Bowl',
        'Palak Paneer', 'Butter Chicken (Lean)', 'Yellow Dal Tadka', 'Jeera Rice & Curry',
        'Veg Pulao', 'Egg Curry Bowl', 'Roasted Veggie Medley', 'Mediterranean Wrap',
        'Brown Rice & Dal', 'Spinach Corn Sandwich', 'Avocado Toast', 'Bento Box',
        'Tandoori Roti & Sabzi', 'Stuffed Paratha', 'Fruit Salad', 'Greek Yogurt Bowl'
    ];
    base_name TEXT;
    img_url TEXT;
BEGIN
    FOR i IN 1..100 LOOP
        base_name := meal_names[(i % array_length(meal_names, 1)) + 1] || ' #' || i;
        img_url := 'https://images.unsplash.com/photo-' || 
                   CASE (i % 5)
                       WHEN 0 THEN '1546069901-ba9599a7e63c'
                       WHEN 1 THEN '1567306301498-519add92fa44'
                       WHEN 2 THEN '1512621776951-a57141f2eefd'
                       WHEN 3 THEN '1606787366850-de6330128bfc'
                       ELSE '1490645935967-10de6ba17061'
                   END || '?w=500&auto=format';

        INSERT INTO public.menu_items (id, name, description, calories, protein, carbs, fats, image_url, default_category, is_premium)
        VALUES 
        (gen_random_uuid(), base_name, 'Delicious lunch option number ' || i || ' prepared fresh with premium ingredients.', 
         400 + (random() * 200)::int, 15 + (random() * 20)::int, 40 + (random() * 40)::int, 10 + (random() * 15)::int,
         img_url, 'Lunch', (i % 10 = 0));
    END LOOP;
END $$;

-- 3. Schedule 1 per day for the next 100 days
DO $$
DECLARE
    item_record RECORD;
    curr_date DATE := CURRENT_DATE;
    count INT := 0;
    v_id UUID;
    nv_id UUID;
    a_id UUID;
BEGIN
    FOR i IN 0..99 LOOP
        -- Select 3 distinct items for the day
        SELECT id INTO v_id FROM public.menu_items OFFSET (i % 100) LIMIT 1;
        SELECT id INTO nv_id FROM public.menu_items OFFSET ((i + 1) % 100) LIMIT 1;
        SELECT id INTO a_id FROM public.menu_items OFFSET ((i + 2) % 100) LIMIT 1;

        INSERT INTO public.daily_menus (date, meal_type, veg_menu_item_id, non_veg_menu_item_id, alt_menu_item_id)
        VALUES (curr_date + i, 'Lunch', v_id, nv_id, a_id);
    END LOOP;
END $$;
