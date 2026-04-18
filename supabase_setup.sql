-- ============================================================
-- PharmaVault — Supabase Database Setup
-- Run this in: Supabase Dashboard > SQL Editor > New Query
-- ============================================================


-- ──────────────────────────────────────────────────────────────
-- 1. PROFILES  (extends Supabase auth.users)
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id               UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  customer_name    TEXT        NOT NULL,
  customer_email   TEXT,
  customer_contact TEXT,
  customer_city    TEXT,
  customer_image   TEXT,
  customer_type    TEXT        NOT NULL DEFAULT 'customer',  -- 'customer' | 'pharmacy'
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-create a profile row whenever a new auth user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, customer_name, customer_email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'customer_name', ''),
    NEW.email
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ──────────────────────────────────────────────────────────────
-- 2. CATEGORIES
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.categories (
  cat_id    SERIAL      PRIMARY KEY,
  cat_name  TEXT        NOT NULL UNIQUE
);

INSERT INTO public.categories (cat_name) VALUES
  ('Pain Relief'),
  ('Antibiotics'),
  ('Vitamins & Supplements'),
  ('Diabetes Care'),
  ('Malaria Treatment'),
  ('Digestive Health'),
  ('Skincare'),
  ('First Aid'),
  ('Cold & Flu'),
  ('Heart & Blood Pressure')
ON CONFLICT DO NOTHING;


-- ──────────────────────────────────────────────────────────────
-- 3. BRANDS
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.brands (
  brand_id    SERIAL PRIMARY KEY,
  brand_name  TEXT   NOT NULL UNIQUE
);

INSERT INTO public.brands (brand_name) VALUES
  ('Panadol'),
  ('Ampiclox'),
  ('Seven Seas'),
  ('Metformin GH'),
  ('Coartem'),
  ('Flagyl'),
  ('Jik'),
  ('Betapyn'),
  ('Actifed'),
  ('Amlodipine GH')
ON CONFLICT DO NOTHING;


-- ──────────────────────────────────────────────────────────────
-- 4. PRODUCTS
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.products (
  product_id          SERIAL   PRIMARY KEY,
  product_title       TEXT     NOT NULL,
  product_description TEXT     NOT NULL DEFAULT '',
  product_price       NUMERIC(10,2) NOT NULL,
  product_stock       INT      NOT NULL DEFAULT 0,
  product_image       TEXT,
  product_keywords    TEXT,
  cat_id              INT      REFERENCES public.categories(cat_id),
  brand_id            INT      REFERENCES public.brands(brand_id),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ──────────────────────────────────────────────────────────────
-- 5. CART
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.cart (
  cart_id     SERIAL PRIMARY KEY,
  c_id        UUID   NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id  INT    NOT NULL REFERENCES public.products(product_id) ON DELETE CASCADE,
  cart_qty    INT    NOT NULL DEFAULT 1,
  added_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (c_id, product_id)
);


-- ──────────────────────────────────────────────────────────────
-- 6. ORDERS
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.orders (
  order_id        SERIAL  PRIMARY KEY,
  c_id            UUID    NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  invoice_no      TEXT    NOT NULL UNIQUE,
  order_date      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  order_status    TEXT    NOT NULL DEFAULT 'pending',  -- pending|confirmed|processing|delivered|cancelled
  delivery_method TEXT,
  delivery_notes  TEXT,   -- JSON string: {address, city, contact}
  payment_amount  NUMERIC(10,2) NOT NULL DEFAULT 0,
  is_paid         BOOLEAN NOT NULL DEFAULT FALSE,
  order_total     NUMERIC(10,2) NOT NULL DEFAULT 0
);


-- ──────────────────────────────────────────────────────────────
-- 7. ORDER ITEMS
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.order_items (
  item_id       SERIAL PRIMARY KEY,
  order_id      INT    NOT NULL REFERENCES public.orders(order_id) ON DELETE CASCADE,
  product_id    INT    NOT NULL REFERENCES public.products(product_id),
  qty           INT    NOT NULL DEFAULT 1,
  product_price NUMERIC(10,2) NOT NULL,
  line_total    NUMERIC(10,2) NOT NULL
);


-- ──────────────────────────────────────────────────────────────
-- 8. PRESCRIPTIONS
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.prescriptions (
  prescription_id     SERIAL  PRIMARY KEY,
  c_id                UUID    NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  prescription_number TEXT    NOT NULL UNIQUE,
  doctor_name         TEXT,
  issue_date          DATE,
  expiry_date         DATE,
  prescription_image  TEXT,
  prescription_notes  TEXT,
  status              TEXT    NOT NULL DEFAULT 'pending',  -- pending|approved|rejected
  allow_pharmacy_access BOOLEAN NOT NULL DEFAULT FALSE,
  uploaded_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE public.profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.brands         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prescriptions  ENABLE ROW LEVEL SECURITY;


-- profiles: users read/update only their own row; pharmacies are publicly readable
CREATE POLICY "Own profile" ON public.profiles
  FOR ALL USING (auth.uid() = id);

CREATE POLICY "Pharmacies are public" ON public.profiles
  FOR SELECT USING (customer_type = 'pharmacy');


-- categories & brands & products: anyone can read
CREATE POLICY "Public read categories" ON public.categories
  FOR SELECT USING (TRUE);

CREATE POLICY "Public read brands" ON public.brands
  FOR SELECT USING (TRUE);

CREATE POLICY "Public read products" ON public.products
  FOR SELECT USING (TRUE);


-- cart: users see/modify only their own rows
CREATE POLICY "Own cart" ON public.cart
  FOR ALL USING (auth.uid() = c_id);


-- orders: users see/create only their own rows
CREATE POLICY "Own orders read"   ON public.orders FOR SELECT USING (auth.uid() = c_id);
CREATE POLICY "Own orders insert" ON public.orders FOR INSERT WITH CHECK (auth.uid() = c_id);


-- order_items: readable if the parent order belongs to the user
CREATE POLICY "Own order items" ON public.order_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.order_id = order_items.order_id
        AND o.c_id = auth.uid()
    )
  );

CREATE POLICY "Own order items insert" ON public.order_items
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.order_id = order_items.order_id
        AND o.c_id = auth.uid()
    )
  );


-- prescriptions: users see/modify only their own rows
CREATE POLICY "Own prescriptions" ON public.prescriptions
  FOR ALL USING (auth.uid() = c_id);


-- ============================================================
-- STORAGE BUCKET  (run separately in Storage tab or via SQL)
-- ============================================================
-- In the Supabase Dashboard go to Storage > New Bucket:
--   Name: prescriptions
--   Public: YES  (so the app can display prescription images via public URL)
--
-- Or via SQL (requires pg_storage extension to be enabled):
-- INSERT INTO storage.buckets (id, name, public) VALUES ('prescriptions', 'prescriptions', true)
-- ON CONFLICT DO NOTHING;
--
-- Storage RLS — allow authenticated users to upload their own files:
-- CREATE POLICY "Auth upload" ON storage.objects FOR INSERT
--   WITH CHECK (bucket_id = 'prescriptions' AND auth.role() = 'authenticated');
-- CREATE POLICY "Public read"  ON storage.objects FOR SELECT
--   USING (bucket_id = 'prescriptions');


-- ============================================================
-- SAMPLE PRODUCTS  (optional — delete if you add your own)
-- ============================================================
INSERT INTO public.products (product_title, product_description, product_price, product_stock, product_keywords, cat_id, brand_id)
VALUES
  ('Panadol Extra 500mg (24 tabs)', 'Fast-acting paracetamol for headache, fever and body pain.', 8.50,  100, NULL, 1, 1),
  ('Ampiclox 500mg Capsules (12)',  'Broad-spectrum antibiotic for bacterial infections.',         22.00, 60,  'rx', 2, 2),
  ('Seven Seas Cod Liver Oil',      'Rich in Omega-3, Vitamin A & D for immunity support.',        35.00, 80,  NULL, 3, 3),
  ('Metformin 500mg (30 tabs)',     'Blood glucose control for type-2 diabetes.',                  15.00, 50,  'rx', 4, 4),
  ('Coartem 80/480mg (24 tabs)',    'First-line artemisinin-based malaria treatment.',              45.00, 40,  'rx', 5, 5),
  ('Flagyl 400mg (21 tabs)',        'Metronidazole for bacterial & protozoal infections.',          12.50, 70,  'rx', 6, 6),
  ('Betapyn Tablets (20)',          'Combination analgesic for pain and fever.',                    6.00,  120, NULL, 1, 8),
  ('Actifed Syrup 100ml',          'Relieves cold, flu, and nasal congestion.',                    14.00, 90,  NULL, 9, 9)
ON CONFLICT DO NOTHING;
