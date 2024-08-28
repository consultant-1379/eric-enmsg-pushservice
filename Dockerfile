ARG ERIC_ENM_SLES_EAP7_IMAGE_NAME=eric-enm-sles-eap7
ARG ERIC_ENM_SLES_EAP7_IMAGE_REPO=armdocker.rnd.ericsson.se/proj-enm
ARG ERIC_ENM_SLES_EAP7_IMAGE_TAG=1.64.0-32

FROM ${ERIC_ENM_SLES_EAP7_IMAGE_REPO}/${ERIC_ENM_SLES_EAP7_IMAGE_NAME}:${ERIC_ENM_SLES_EAP7_IMAGE_TAG}

ARG BUILD_DATE=unspecified
ARG IMAGE_BUILD_VERSION=unspecified
ARG GIT_COMMIT=unspecified
ARG ISO_VERSION=unspecified
ARG RSTATE=unspecified
# According to DR-D1123-122, User ID is generated by scripts below:
# cntr=pushservice; h=$( sha256sum <<< "${cntr}" | cut -f1 -d ' ' ) ; printf '%s : %d\n' "${cntr}" "$( bc -q <<< "scale=0;obase=10;ibase=16;(${h^^}%30D41)+186A0" )"
ARG SGUSER=125634

LABEL \
com.ericsson.product-number="CXD 101 1159" \
com.ericsson.product-revision=$RSTATE \
enm_iso_version=$ISO_VERSION \
org.label-schema.name="ENM File Push Service Group" \
org.label-schema.build-date=$BUILD_DATE \
org.label-schema.vcs-ref=$GIT_COMMIT \
org.label-schema.vendor="Ericsson" \
org.label-schema.version=$IMAGE_BUILD_VERSION \
org.label-schema.schema-version="1.0.0-rc1"

COPY --chown=jboss_user:jboss image_content/ /var/tmp/

RUN zypper install -y \
    ERICpushservicecmmodule_CXP9041740 \
    ERICfntcommandhandler_CXP9041645 \
    ERICfilepushservice_CXP9041644 \
    ERICserviceframework4_CXP9037454 \
    ERICserviceframeworkmodule4_CXP9037453 \
    ERICmodelserviceapi_CXP9030594 \
    ERICmodelservice_CXP9030595 \
    ERICpib2_CXP9037459 \
    ERICdpsruntimeapi_CXP9030469 \
    ERICdpsruntimeimpl_CXP9030468 \
    ERICmediationengineapi2_CXP9038435 \
    ERICdpsmediationclient2_CXP9038436 \
    ERICdpsattributeresolver2_CXP9038437 &&\
    zypper download ERICenmsgpushservice_CXP9041518 && \
    rpm -ivh /var/cache/zypp/packages/enm_iso_repo/ERICenmsgpushservice_CXP9041518*.rpm --nodeps --noscripts && \
    rm -f /ericsson/3pp/jboss/bin/post-start/update_management_credential_permissions.sh \
          /ericsson/3pp/jboss/bin/post-start/update_standalone_permissions.sh && \
    zypper clean -a

### copy file from image_content
COPY image_content/createCertificatesLinks.sh /ericsson/3pp/jboss/bin/pre-start/createCertificatesLinks.sh
### ...

### run for non root
RUN chown jboss_user:jboss /ericsson/3pp/jboss/bin/pre-start/createCertificatesLinks.sh
RUN chmod 550 /ericsson/3pp/jboss/bin/pre-start/createCertificatesLinks.sh

RUN chmod 440 /opt/fnt-command-handler/data/json/pushfiletransfer.json
RUN chmod 440 /ericsson/3pp/jboss/bin/cli/services/*.cli
RUN chmod 550 /ericsson/3pp/jboss/standalone/deployments/*
### ...

RUN mkdir -p /ericsson/ftps/data/certs
RUN chmod 770 -R /ericsson/ftps/data/certs

RUN echo "$SGUSER:x:$SGUSER:$SGUSER:An Identity for pushservice:/nonexistent:/bin/false" >>/etc/passwd && \
    echo "$SGUSER:!::0:::::" >>/etc/shadow

ENV ENM_JBOSS_SDK_CLUSTER_ID="pushservice" \
    ENM_JBOSS_BIND_ADDRESS="0.0.0.0" \
    JBOSS_HOME="/ericsson/3pp/jboss" \
    GLOBAL_CONFIG="/gp/global.properties" \
    JBOSS_CONF="/ericsson/3pp/jboss/app-server.conf"

RUN sed -i 's/Http11NioProtocol/Http11Protocol/g' /ericsson/3pp/jboss/standalone/configuration/standalone-eap7-enm.xml

EXPOSE 4447 5140 5445 7500 8009 8080 9600 9990 9999 12987 58156

USER $SGUSER
