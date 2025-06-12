#!/bin/bash

# Script para exportar configurações do Keycloak
echo "=== Exportador de Configurações do Keycloak ==="

# Verificar se o Keycloak está rodando
if ! curl -s http://localhost:8080 >/dev/null; then
    echo "Erro: Keycloak não está disponível em http://localhost:8080"
    echo "Certifique-se de que o container está rodando com: docker compose up -d"
    exit 1
fi

echo "Keycloak detectado. Iniciando exportação..."

# Obter token de acesso
echo "Obtendo token de autenticação..."
RESPONSE=$(curl -s -X POST http://localhost:8080/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin" \
  -d "password=admin" \
  -d "grant_type=password" \
  -d "client_id=admin-cli")

TOKEN=$(echo $RESPONSE | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo "Erro: Não foi possível obter token de acesso"
    echo "Verifique as credenciais admin/admin"
    exit 1
fi

echo "Token obtido com sucesso!"

# Criar diretório de backup
BACKUP_DIR="keycloak/import.backup.$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Fazer backup das configurações atuais
if [ -d "keycloak/import" ]; then
    echo "Fazendo backup das configurações atuais..."
    cp -r keycloak/import/* "$BACKUP_DIR/" 2>/dev/null || true
fi

# Listar realms
echo "Listando realms disponíveis..."
curl -s -X GET "http://localhost:8080/admin/realms" \
  -H "Authorization: Bearer $TOKEN" > /tmp/realms-list.json

REALMS=$(grep -o '"realm":"[^"]*"' /tmp/realms-list.json | cut -d'"' -f4)

echo "Realms encontrados:"
for realm in $REALMS; do
    echo "  - $realm"
done

# Função para exportação completa de um realm
export_realm_complete() {
    local realm=$1
    echo "Exportando realm completo: $realm"
    
    # Criar estrutura de export manual
    local temp_dir="/tmp/keycloak-export-$realm"
    mkdir -p "$temp_dir"
    
    # 1. Exportar configuração base do realm
    echo "  1/4 Exportando configuração base do realm..."
    curl -s -X GET "http://localhost:8080/admin/realms/$realm" \
      -H "Authorization: Bearer $TOKEN" > "$temp_dir/realm-base.json"
    
    # 2. Exportar clients
    echo "  2/4 Exportando clients..."
    curl -s -X GET "http://localhost:8080/admin/realms/$realm/clients" \
      -H "Authorization: Bearer $TOKEN" > "$temp_dir/clients.json"
    
    # 3. Exportar roles
    echo "  3/4 Exportando roles..."
    curl -s -X GET "http://localhost:8080/admin/realms/$realm/roles" \
      -H "Authorization: Bearer $TOKEN" > "$temp_dir/roles.json"
    
    # 4. Exportar groups (se existirem)
    echo "  4/4 Exportando groups..."
    curl -s -X GET "http://localhost:8080/admin/realms/$realm/groups" \
      -H "Authorization: Bearer $TOKEN" > "$temp_dir/groups.json"
    
    # Combinar tudo em um único arquivo JSON
    echo "  Combinando dados..."
    python3 << EOF
import json
import sys

try:
    # Carregar dados base
    with open('$temp_dir/realm-base.json', 'r') as f:
        realm_data = json.load(f)
    
    # Carregar clients
    with open('$temp_dir/clients.json', 'r') as f:
        clients = json.load(f)
    
    # Carregar roles
    with open('$temp_dir/roles.json', 'r') as f:
        roles = json.load(f)
    
    # Carregar groups
    with open('$temp_dir/groups.json', 'r') as f:
        groups = json.load(f)
    
    # Adicionar ao realm_data
    realm_data['clients'] = clients
    realm_data['roles'] = {'realm': roles}
    realm_data['groups'] = groups
    
    # Salvar arquivo final
    with open('keycloak/import/$realm-realm.json', 'w') as f:
        json.dump(realm_data, f, indent=2)
    
    print(f'    ✓ Exportação combinada concluída')
    print(f'    - Clients: {len(clients)}')
    print(f'    - Roles: {len(roles)}')
    print(f'    - Groups: {len(groups)}')
    
except Exception as e:
    print(f'    ✗ Erro ao combinar dados: {e}')
    sys.exit(1)
EOF
    
    # Limpar arquivos temporários
    rm -rf "$temp_dir"
    
    # Verificar resultado final
    if [ -f "keycloak/import/$realm-realm.json" ]; then
        local file_size=$(wc -c < "keycloak/import/$realm-realm.json")
        echo "  ✓ $realm exportado com sucesso ($file_size bytes)"
    else
        echo "  ✗ Falha na exportação de $realm"
    fi
}

# Exportar cada realm com configuração completa
echo "Exportando configurações completas dos realms..."
for realm in $REALMS; do
    export_realm_complete "$realm"
done

echo
echo "=== Exportação Concluída ==="
echo "Arquivos exportados:"
ls -la keycloak/import/
echo
echo "Backup das configurações anteriores em: $BACKUP_DIR"
echo
echo "Para aplicar as novas configurações:"
echo "1. docker compose down"
echo "2. docker compose build keycloak --no-cache"
echo "3. docker compose up -d"
echo

