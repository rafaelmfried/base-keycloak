# Base Keycloak - Setup com Importação Automática

Este projeto configura um ambiente completo do Keycloak com PostgreSQL, RabbitMQ e Redis, incluindo importação automática de configurações.

## 🛠️ **Componentes**

- **Keycloak 26.2.4**: Servidor de autenticação e autorização
- **PostgreSQL 15**: Banco de dados principal
- **RabbitMQ 3 Management**: Message broker
- **Redis**: Cache e sessões

## 🚀 **Inicio Rápido**

### 1. Iniciar todos os serviços
```bash
docker compose up -d
```

### 2. Acessar os serviços

| Serviço | URL | Credenciais |
|---------|-----|-------------|
| Keycloak | http://localhost:8080 | admin/admin |
| RabbitMQ Management | http://localhost:15672 | admin/admin |
| PostgreSQL | localhost:5432 | admin/admin (database: suitedb) |
| Redis | localhost:6379 | - |

## 📜 **Configuração Automática**

### Importação Completa de Realms

O Keycloak é configurado para **importar automaticamente** as configurações completas dos realms durante a inicialização.

**O que é importado:**
- ✅ **Configurações do Realm** (timeouts, políticas, etc.)
- ✅ **Clients** (incluindo clients customizados)
- ✅ **Roles** (realm e client roles)
- ✅ **Groups** (se existirem)
- ✅ **Client Scopes** e Protocol Mappers
- ✅ **Authentication Flows**

Os arquivos de configuração são carregados de:
```
keycloak/import/
├── master-realm.json    # Configurações completas do realm master
└── suite-realm.json     # Configurações completas do realm suite
```

### Como Funciona

1. **Build**: Durante o build da imagem, as configurações são copiadas para `/opt/keycloak/data/import/`
2. **Startup**: O script `import-config.sh` detecta os arquivos e inicia o Keycloak com `--import-realm`
3. **Import**: O Keycloak importa automaticamente todos os realms encontrados

## 🔄 **Exportar Novas Configurações**

### Exportação Manual

Para exportar as configurações atuais do Keycloak:

```bash
./export-config.sh
```

Este script:
- ✅ Conecta na API Admin do Keycloak
- ✅ Faz backup das configurações antigas
- ✅ Exporta **configurações completas** de todos os realms:
  - Configurações base do realm
  - Todos os clients (incluindo customizados)
  - Todas as roles (realm + client roles)
  - Groups existentes
- ✅ Combina tudo em arquivos JSON estruturados
- ✅ Salva no diretório `keycloak/import/`

### Aplicar Novas Configurações

Após exportar, reconstrua a imagem:

```bash
docker compose down
docker compose build keycloak --no-cache
docker compose up -d
```

## 📱 **Arquitetura**

```
┌─────────────────────────────────────────────────────────┐
│                    keycloak_network                     │
│  ┌─────────────┐   ┌────────────────┐   ┌─────────────┐  │
│  │   Keycloak   │   │   PostgreSQL    │   │  RabbitMQ  │  │
│  │   :8080      │───│   :5432        │   │  :15672   │  │
│  └─────────────┘   └────────────────┘   └─────────────┘  │
│           │                                 ┌─────────────┐  │
│           └───────────────────────────────────┤   Redis    │  │
│                                            │   :6379   │  │
│                                            └─────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Características da Rede

- **Rede customizada**: `keycloak_network` com driver bridge
- **Comunicação interna**: Os containers se comunicam por hostname
- **Health checks**: PostgreSQL possui health check configurado
- **Dependências**: Keycloak aguarda PostgreSQL estar saudável

## 📁 **Estrutura do Projeto**

```
.
├── compose.yaml              # Configuração dos serviços
├── export-config.sh          # Script de exportação
├── postgres/
│   └── init.sql              # Script de inicialização do BD
└── keycloak/
    ├── Dockerfile            # Imagem customizada do Keycloak
    ├── import-config.sh      # Script de importação
    └── import/              # Configurações exportadas
        ├── master-realm.json
        ├── suite-realm.json
        └── realms-list.json
```

## 🔧 **Comandos Úteis**

### Gerenciamento dos Containers

```bash
# Iniciar todos os serviços
docker compose up -d

# Parar todos os serviços
docker compose down

# Ver status dos containers
docker compose ps

# Ver logs do Keycloak
docker compose logs keycloak -f

# Reconstruir apenas o Keycloak
docker compose build keycloak --no-cache
```

### Limpeza completa

```bash
# Parar e remover tudo (incluindo volumes)
docker compose down -v

# Remover imagens
docker rmi base-keycloak-keycloak
```

## 🚪 **Troubleshooting**

### Keycloak não inicia

1. Verificar logs: `docker compose logs keycloak`
2. Verificar se PostgreSQL está healthy: `docker compose ps`
3. Reconstruir imagem: `docker compose build keycloak --no-cache`

### PostgreSQL com problemas de permissão

1. Remover volumes: `docker compose down -v`
2. Reiniciar: `docker compose up -d`

### Problema na importação

1. Verificar arquivos em `keycloak/import/`
2. Validar JSON: `cat keycloak/import/master-realm.json | jq .`
3. Executar exportação novamente: `./export-config.sh`

## 🔒 **Segurança**

> **⚠️ Atenção**: Este setup é para **desenvolvimento apenas**.

Para produção, considere:

- Alterar credenciais padrão (admin/admin)
- Configurar HTTPS
- Usar secrets do Docker para senhas
- Configurar backup automatizado
- Implementar monitoramento
- Revisar configurações de segurança dos clients

## 🚀 **Clients Pré-configurados**

Após a importação, os seguintes clients estarão disponíveis:

### Realm Master
- `admin-cli` - Interface administrativa
- `security-admin-console` - Console de administração
- `account` / `account-console` - Gerenciamento de conta
- `broker` - Identity providers
- `suite-realm` - Gerenciamento do realm suite

### Realm Suite
- `admin-cli` - Interface administrativa
- `security-admin-console` - Console de administração
- `account` / `account-console` - Gerenciamento de conta
- `broker` - Identity providers
- `realm-management` - Gerenciamento do realm
- **`auth`** - Client customizado (se configurado)
- **`tenant`** - Client customizado (se configurado)
- **`user`** - Client customizado (se configurado)

> **Nota**: Os clients marcados em **negrito** são customizados e serão preservados durante a exportação/importação.

## 📝 **Licença**

Este projeto é fornecido como está, para fins educacionais e de desenvolvimento.

