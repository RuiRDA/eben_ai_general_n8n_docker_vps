FROM node:22.23.2-alpine3.24 AS patches
RUN apk add --no-cache apk-tools-static
WORKDIR /patches
COPY images/n8n-patches/package.json images/n8n-patches/package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts
FROM n8nio/n8n:2.37.10
USER root
COPY --from=patches /sbin/apk.static /tmp/apk.static
RUN /tmp/apk.static add --no-cache --upgrade libcrypto3 libssl3 openssh && rm /tmp/apk.static
COPY --from=patches /patches/node_modules /opt/security-patches/node_modules
COPY images/n8n-patches/apply.cjs /opt/security-patches/apply.cjs
RUN node /opt/security-patches/apply.cjs && rm -rf /opt/security-patches
USER node
