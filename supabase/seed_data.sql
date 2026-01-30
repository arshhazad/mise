-- SEED DATA FOR MISE
-- Run this in your Supabase SQL Editor to see menus on the Dashboard

-- 1. Insert Sample Menu Items
INSERT INTO public.menu_items (name, description, calories, protein, carbs, fats, image_url, default_category, is_premium)
VALUES 
('Indori Poha', 'Classic breakfast with flattened rice, onions, and spices.', 250, 6, 45, 8, 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format', 'Breakfast', false),
('Paneer Tikka Bowl', 'Grilled paneer with spicy rice and fresh veggies.', 550, 25, 60, 22, 'https://images.unsplash.com/photo-1567306301498-519add92fa44?w=500&auto=format', 'Lunch', true),
('Roasted Makhana', 'Healthy foxnut snack roasted in olive oil.', 120, 2, 15, 4, 'https://images.unsplash.com/photo-1621939514649-280e2ee9d160?w=500&auto=format', 'Snacks', false),
('Grilled Chicken Salad', 'Lean chicken breast with exotic greens and balsamic dressing.', 420, 35, 12, 18, 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500&auto=format', 'Dinner', true);

-- 2. Schedule Menus for Today and Tomorrow
DO $$
DECLARE
    breakfast_id UUID;
    lunch_id UUID;
    snack_id UUID;
    dinner_id UUID;
    today_date DATE := CURRENT_DATE;
    tomorrow_date DATE := CURRENT_DATE + 1;
BEGIN
    -- Get IDs
    SELECT id INTO breakfast_id FROM public.menu_items WHERE name = 'Indori Poha' LIMIT 1;
    SELECT id INTO lunch_id FROM public.menu_items WHERE name = 'Paneer Tikka Bowl' LIMIT 1;
    SELECT id INTO snack_id FROM public.menu_items WHERE name = 'Roasted Makhana' LIMIT 1;
    SELECT id INTO dinner_id FROM public.menu_items WHERE name = 'Grilled Chicken Salad' LIMIT 1;

    -- Schedule Today
    INSERT INTO public.daily_menus (date, meal_type, base_menu_item_id) VALUES 
    (today_date, 'Breakfast', breakfast_id),
    (today_date, 'Lunch', lunch_id),
    (today_date, 'Snacks', snack_id),
    (today_date, 'Dinner', dinner_id)
    ON CONFLICT (date, meal_type) DO NOTHING;

    -- Schedule Tomorrow
    INSERT INTO public.daily_menus (date, meal_type, base_menu_item_id) VALUES 
    (tomorrow_date, 'Breakfast', breakfast_id),
    (tomorrow_date, 'Lunch', lunch_id),
    (tomorrow_date, 'Snacks', snack_id),
    (tomorrow_date, 'Dinner', dinner_id)
    ON CONFLICT (date, meal_type) DO NOTHING;
END $$;
