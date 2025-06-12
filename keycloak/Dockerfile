FROM quay.io/keycloak/keycloak:26.2.4 as builder

ENV KC_FEATURES=organization
ENV KC_DB=postgres
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_TRANSACTION_XA_ENABLED=true

RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:26.2.4

COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Copiar script de inicialização
COPY --chmod=755 import-config.sh /opt/keycloak/bin/import-config.sh
# Copiar configurações exportadas para o container
COPY import/ /opt/keycloak/data/import/

ENV KC_FEATURES=organization
ENV KC_DB=postgres
ENV KC_DB_URL_HOST=postgres
ENV KC_DB_URL_DATABASE=suitedb
ENV KC_DB_USERNAME=admin
ENV KC_DB_PASSWORD=admin
ENV KC_DB_SCHEMA=keycloak
ENV KC_TRANSACTION_XA_ENABLED=true
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

WORKDIR /opt/keycloak

EXPOSE 8080

ENTRYPOINT ["/opt/keycloak/bin/import-config.sh"]
