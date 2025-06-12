#!/bin/bash

# Script para importar configurações do Keycloak
echo "Iniciando Keycloak com importação de configurações..."

# Diretório onde estão os arquivos de configuração
IMPORT_DIR="/opt/keycloak/data/import"

# Verificar se existem arquivos para importar
if [ -d "$IMPORT_DIR" ] && [ "$(ls -A $IMPORT_DIR)" ]; then
    echo "Configurações encontradas em $IMPORT_DIR:"
    ls -la "$IMPORT_DIR"
    
    # Remover arquivo de metadados que não deve ser importado
    if [ -f "$IMPORT_DIR/realms-list.json" ]; then
        echo "Removendo arquivo de metadados realms-list.json"
        rm "$IMPORT_DIR/realms-list.json"
    fi
    
    echo "Iniciando importação..."
    
    # Executar Keycloak com importação
    exec /opt/keycloak/bin/kc.sh start-dev --import-realm
else
    echo "Nenhuma configuração encontrada. Iniciando Keycloak normalmente..."
    
    # Executar Keycloak normalmente
    exec /opt/keycloak/bin/kc.sh start-dev
fi

