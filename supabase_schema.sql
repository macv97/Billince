-- 1. Gastos Personales Sincronizados
CREATE TABLE IF NOT EXISTS user_expenses (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  title TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  date TIMESTAMP WITH TIME ZONE NOT NULL,
  category TEXT NOT NULL,
  currency TEXT NOT NULL,
  attached_file_path TEXT
);

-- Políticas de Seguridad (RLS) para Gastos Personales
ALTER TABLE user_expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own expenses" 
  ON user_expenses FOR ALL 
  USING (auth.uid() = user_id);

-- 2. Grupos Compartidos (Eventos)
CREATE TABLE IF NOT EXISTS shared_groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  currency TEXT NOT NULL,
  created_by UUID REFERENCES auth.users NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Políticas de Seguridad (RLS) para Grupos
ALTER TABLE shared_groups ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Group visibility" ON shared_groups FOR SELECT USING (true); -- o restringir por members
CREATE POLICY "Group insertion" ON shared_groups FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Anyone can update groups" ON shared_groups FOR UPDATE USING (true);

-- 3. Miembros del Grupo (Deep Link Invites)
CREATE TABLE IF NOT EXISTS group_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID REFERENCES shared_groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users,     -- Si está logueado
  guest_name TEXT,                        -- Si no está logueado (acceso anónimo, opcional)
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(group_id, user_id)               -- Evitar duplicados
);

ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Members can view members" ON group_members FOR SELECT USING (true);
CREATE POLICY "Anyone can join" ON group_members FOR INSERT WITH CHECK (true);

-- 4. Listas de la compra sincronizadas
CREATE TABLE IF NOT EXISTS user_shopping_lists (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  title TEXT NOT NULL,
  date_created TIMESTAMP WITH TIME ZONE NOT NULL
);

ALTER TABLE user_shopping_lists ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their shopping lists" ON user_shopping_lists FOR ALL USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS user_checklist_items (
  id TEXT PRIMARY KEY,
  list_id TEXT REFERENCES user_shopping_lists(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  is_done BOOLEAN NOT NULL DEFAULT false,
  price NUMERIC NOT NULL DEFAULT 0.0
);

ALTER TABLE user_checklist_items ENABLE ROW LEVEL SECURITY;
-- Por simplicidad en inserción, permitimos todo a auth.users (en producción usar EXISTS con user_shopping_lists)
CREATE POLICY "Users can manage their checklist items" ON user_checklist_items FOR ALL USING (auth.uid() IS NOT NULL);

-- 5. Gastos de los grupos compartidos
CREATE TABLE IF NOT EXISTS shared_expenses (
  id TEXT PRIMARY KEY,
  group_id TEXT NOT NULL,
  payer TEXT NOT NULL,
  title TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  participants TEXT -- JSON or comma-separated string
);

ALTER TABLE shared_expenses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can manage shared expenses" ON shared_expenses FOR ALL USING (true);

-- 6. Listas de la compra compartidas
CREATE TABLE IF NOT EXISTS shared_checklists (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_by UUID REFERENCES auth.users NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE shared_checklists ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Shared checklists visibility" ON shared_checklists FOR SELECT USING (true);
CREATE POLICY "Shared checklists insertion" ON shared_checklists FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Anyone can update shared checklists" ON shared_checklists FOR UPDATE USING (true);

-- 7. Miembros de las listas compartidas
CREATE TABLE IF NOT EXISTS shared_checklist_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  list_id TEXT REFERENCES shared_checklists(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users,
  guest_name TEXT,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(list_id, user_id)
);

ALTER TABLE shared_checklist_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Shared list members visibility" ON shared_checklist_members FOR SELECT USING (true);
CREATE POLICY "Anyone can join shared list" ON shared_checklist_members FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can update user id" ON shared_checklist_members FOR UPDATE USING (true);

-- 8. Productos de las listas compartidas
CREATE TABLE IF NOT EXISTS shared_checklist_items (
  id TEXT PRIMARY KEY,
  list_id TEXT REFERENCES shared_checklists(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  is_done BOOLEAN NOT NULL DEFAULT false,
  tags TEXT,
  added_by TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE shared_checklist_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can manage shared checklist items" ON shared_checklist_items FOR ALL USING (true);

-- 9. Historial de acciones (Auditoría)
CREATE TABLE IF NOT EXISTS shared_checklist_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  list_id TEXT REFERENCES shared_checklists(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  user_name TEXT NOT NULL,
  item_title TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE shared_checklist_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can manage audit logs" ON shared_checklist_logs FOR ALL USING (true);

-- 10. Función Segura para Eliminar Cuenta (Bypass Client Deletion)
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS void AS $$
BEGIN
  -- Borrar datos personales y vinculaciones
  DELETE FROM public.user_expenses WHERE user_id = auth.uid();
  DELETE FROM public.user_shopping_lists WHERE user_id = auth.uid();
  DELETE FROM public.group_members WHERE user_id = auth.uid();
  DELETE FROM public.shared_checklist_members WHERE user_id = auth.uid();

  -- Eliminar el usuario de la autenticación de Supabase
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

