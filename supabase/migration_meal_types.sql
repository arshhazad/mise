-- Migration: Add meal_type to daily_menus
CREATE TYPE meal_category AS ENUM ('Breakfast', 'Lunch', 'Snacks', 'Dinner');

ALTER TABLE public.daily_menus 
ADD COLUMN meal_type meal_category DEFAULT 'Lunch' NOT NULL;

-- Drop old unique constraint and add new one for date + meal_type
ALTER TABLE public.daily_menus DROP CONSTRAINT IF EXISTS daily_menus_date_key;
ALTER TABLE public.daily_menus ADD CONSTRAINT daily_menus_date_meal_type_key UNIQUE (date, meal_type);

-- Update menu_items to include category info
ALTER TABLE public.menu_items 
ADD COLUMN default_category meal_category DEFAULT 'Lunch';
