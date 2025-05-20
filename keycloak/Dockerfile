FROM quay.io/keycloak/keycloak:26.2.4 as builder

ENV KC_FEATURES=organizations

RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:26.2.4

COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENV KC_FEATURES=organizations
ENV KC_TRANSACTION_XA_ENABLED=true
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

WORKDIR /opt/keycloak

EXPOSE 8080

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]

CMD ["start-dev"]