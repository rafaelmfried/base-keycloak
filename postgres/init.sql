-- 0) Cria extensao uuid-ossp
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1) Cria schemas
CREATE SCHEMA IF NOT EXISTS tenant AUTHORIZATION admin;
CREATE SCHEMA IF NOT EXISTS app_user AUTHORIZATION admin;
CREATE SCHEMA IF NOT EXISTS notification AUTHORIZATION admin;
CREATE SCHEMA IF NOT EXISTS invite AUTHORIZATION admin;
CREATE SCHEMA IF NOT EXISTS keycloak AUTHORIZATION admin;

-- 2) Tabela de tenants
CREATE TABLE IF NOT EXISTS tenant.tenants (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT        NOT NULL,
  alias      TEXT        UNIQUE NOT NULL,
  domain    TEXT        UNIQUE NOT NULL,
  created_at TIMESTAMP   NOT NULL DEFAULT now()
);

-- 3) Tabela de usuários
CREATE TABLE IF NOT EXISTS app_user.users (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  email      TEXT        NOT NULL,
  full_name  TEXT,
  created_at TIMESTAMP   NOT NULL DEFAULT now(),
  CONSTRAINT uq_user_email UNIQUE(email)
);

-- 4) Catálogo global de Roles
CREATE TABLE IF NOT EXISTS app_user.roles (
  id          UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT      NOT NULL UNIQUE,   -- ex: 'admin', 'financial', 'user', 'root'
  description TEXT
);

-- 6) Associação Usuário ↔ Tenant
CREATE TABLE IF NOT EXISTS tenant.user_tenants (
  user_id   UUID NOT NULL
    REFERENCES app_user.users(id)  ON DELETE CASCADE,
  tenant_id UUID NOT NULL
    REFERENCES tenant.tenants(id) ON DELETE CASCADE,
  joined_at TIMESTAMP NOT NULL DEFAULT now(),
  PRIMARY KEY(user_id, tenant_id)
);

-- 7) Associação Usuário ↔ Role ↔ Tenant
CREATE TABLE IF NOT EXISTS app_user.user_roles (
  user_id    UUID NOT NULL
     REFERENCES app_user.users(id) ON DELETE CASCADE,
  tenant_id  UUID NOT NULL
     REFERENCES tenant.tenants(id) ON DELETE CASCADE,
  role_id    UUID NOT NULL
     REFERENCES app_user.roles(id) ON DELETE CASCADE,
  granted_at TIMESTAMP NOT NULL DEFAULT now(),
  PRIMARY KEY(user_id, tenant_id, role_id)
);

-- 8) Permissions globais
CREATE TABLE IF NOT EXISTS app_user.permissions (
  id          UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT      NOT NULL UNIQUE,
  description TEXT
);

-- 9) Mapeamento Role → Permission
CREATE TABLE IF NOT EXISTS app_user.role_permissions (
  role_id        UUID NOT NULL
    REFERENCES app_user.roles(id) ON DELETE CASCADE,
  permission_id  UUID NOT NULL
    REFERENCES app_user.permissions(id) ON DELETE CASCADE,
  assigned_at    TIMESTAMP NOT NULL DEFAULT now(),
  PRIMARY KEY(role_id, permission_id)
);


-- 10) Povoando o banco com as roles e permissions globais
INSERT INTO app_user.roles (name,description)
  VALUES('admin','Administrador completo'),
        ('financial','Gerência de finanças'),
        ('user','Usuário comum')
ON CONFLICT (name) DO NOTHING;


-- 11) Insere no catálogo global (permissions)
INSERT INTO app_user.permissions (name, description)
VALUES
  ('read:user',    'Permissão de leitura de usuários'),
  ('write:user',   'Permissão de criação/edição de usuários'),
  ('read:tenant',  'Permissão de leitura de tenants'),
  ('write:tenant', 'Permissão de criação/edição de tenants')
ON CONFLICT (name) DO NOTHING;
-- 12) Verificação de constraints entre schemas
DO $$ 
DECLARE
  r RECORD;
BEGIN
  -- Verifica se todas as constraints de chave estrangeira estão corretamente configuradas
  RAISE NOTICE 'Verificando constraints de chave estrangeira entre schemas...';
  
  -- Lista todas as constraints de chave estrangeira entre os schemas
  CREATE TEMP TABLE IF NOT EXISTS check_constraints AS
  SELECT
      tc.constraint_name,
      tc.table_schema, 
      tc.table_name, 
      kcu.column_name,
      ccu.table_schema AS foreign_table_schema,
      ccu.table_name AS foreign_table_name,
      ccu.column_name AS foreign_column_name
  FROM information_schema.table_constraints AS tc
  JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name
  JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name
  WHERE tc.constraint_type = 'FOREIGN KEY'
    AND (tc.table_schema = 'app_user' OR tc.table_schema = 'tenant');
  
  RAISE NOTICE 'Verificação concluída. % constraints encontradas.', (SELECT COUNT(*) FROM check_constraints);
  
  -- Exibe as constraints encontradas
  RAISE NOTICE 'Listando constraints...';
  FOR r IN (SELECT * FROM check_constraints) LOOP
    RAISE NOTICE 'Constraint: % | Tabela: %.% | Referencia: %.%', 
      r.constraint_name, r.table_schema, r.table_name, 
      r.foreign_table_schema, r.foreign_table_name;
  END LOOP;
  
  DROP TABLE IF EXISTS check_constraints;
END $$;