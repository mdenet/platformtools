# syntax=docker/dockerfile:1
#
# Central multi-stage Dockerfile for all tool services.
#
# A single Maven build stage compiles every tool module so that Maven runs
# only once and Docker can cache the result across all subsequent stages.
#
# Build a specific tool service by targeting the appropriate stage, e.g.:
#   docker build --target toolservice-emf      -t emf-tool      .
#   docker build --target toolservice-emfatic  -t emfatic-tool  .
#   docker build --target toolservice-ocl      -t ocl-tool      .
#   docker build --target toolservice-conversion -t conversion-tool .
#   docker build --target toolservice-xtext    -t xtext-tool    .

# ---------------------------------------------------------------------------
# Stage 1 – Maven build (all modules built in a single invocation)
# ---------------------------------------------------------------------------
FROM maven:3.8.5-openjdk-17 AS mavenbuilder

COPY services /usr/src/toolfunctions

WORKDIR /usr/src/toolfunctions

RUN mvn clean install -Pall

# Get runtime dependencies used by the tool-runner stages
RUN mvn org.apache.maven.plugins:maven-dependency-plugin:3.6.0:get \
        -Dartifact=com.google.cloud.functions:function-maven-plugin:0.9.5 \
    && mvn org.apache.maven.plugins:maven-dependency-plugin:3.6.0:get \
        -Dartifact=org.apache.maven.plugins:maven-deploy-plugin:2.7


# ---------------------------------------------------------------------------
# Stage 2a – Static frontend build for EMF
# ---------------------------------------------------------------------------
FROM node:19-bullseye AS staticbuild-emf

WORKDIR /usr/src/mdenet-tool

COPY static.emf/package*.json ./
COPY static.emf .

RUN npm install; npm run build; chmod -R 755 dist/


# ---------------------------------------------------------------------------
# Stage 2b – Static frontend build for Emfatic
# ---------------------------------------------------------------------------
FROM node:19-bullseye AS staticbuild-emfatic

WORKDIR /usr/src/mdenet-tool

COPY static.emfatic/package*.json ./
COPY static.emfatic .

RUN npm install; npm run build; chmod -R 755 dist/


# ---------------------------------------------------------------------------
# Stage 2c – Static frontend build for OCL
# ---------------------------------------------------------------------------
FROM node:19-bullseye AS staticbuild-ocl

WORKDIR /usr/src/mdenet-tool

COPY static.ocl/package*.json ./
COPY static.ocl .

RUN npm install; npm run build; chmod -R 755 dist/


# ---------------------------------------------------------------------------
# Stage 2d – Static frontend build for Conversion (Epsilon)
# ---------------------------------------------------------------------------
FROM node:19-bullseye AS staticbuild-conversion

WORKDIR /usr/src/mdenet-tool

COPY static.conversion/package*.json ./
COPY static.conversion .

RUN npm install; npm run build; chmod -R 755 dist/


# ---------------------------------------------------------------------------
# Stage 2e – Static frontend build for Xtext
# ---------------------------------------------------------------------------
FROM node:19-bullseye AS staticbuild-xtext

ARG TRUSTED_ORIGINS

RUN apt-get update && apt-get install -y --no-install-recommends zip

WORKDIR /usr/src/mdenet-tool

COPY xtext/static.xtext/package*.json ./
COPY xtext/static.xtext .

RUN npm install; npm run build; chmod -R 755 dist/

# CORS configuration for webapp
COPY xtext/acemodebundler/web.xml /usr/src/mdenet-tool/dist/WEB-INF/web.xml

RUN sed -i "s|http://127.0.0.1:8080|$TRUSTED_ORIGINS|g" /usr/src/mdenet-tool/dist/WEB-INF/web.xml

RUN cd dist && zip -r ROOT.war .


# ---------------------------------------------------------------------------
# Stage 3a – EMF tool service
# ---------------------------------------------------------------------------
FROM nginx:1.24.0-bullseye AS toolservice-emf

# Needed to avoid prompts blocking the build process
ENV DEBIAN_FRONTEND=noninteractive

# Needed for Cloud Build
ENV PORT=80

RUN apt-get update \
    && apt-get install -y python3-minimal maven tini netcat \
    && rm -rf /var/lib/apt/lists/*

# Copy built tool and sources (only the modules required for the emf profile)
COPY --from=mavenbuilder /root/.m2 /root/.m2
COPY --from=mavenbuilder /usr/src/toolfunctions/pom.xml /toolservice/pom.xml
COPY --from=mavenbuilder /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.core /toolservice/com.mde-network.ep.toolfunctions.core
COPY --from=mavenbuilder /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.emf /toolservice/com.mde-network.ep.toolfunctions.emf
COPY --from=mavenbuilder /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.emffunction /toolservice/com.mde-network.ep.toolfunctions.emffunction

# Copy files for webserver
COPY static.emf/nginx.conf.template /etc/nginx.conf.template

RUN rm -r /usr/share/nginx/html/*
COPY --from=staticbuild-emf /usr/src/mdenet-tool/dist /usr/share/nginx/html

WORKDIR /toolservice

# Due to https://issues.apache.org/jira/browse/MDEP-568, m-dependency-p
# is not a practical solution for ensuring all dependencies are available.
#
# We use https://github.com/qaware/go-offline-maven-plugin instead.
# TODO: This was commented out in the original Docker file, but is active in some of the other tools. Need to understand which is correct.
#RUN mvn -B de.qaware.maven:go-offline-maven-plugin:1.2.8:resolve-dependencies

# Copy start script and make it executable
ADD static.emf/start.sh /
RUN chmod +x /start.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/start.sh"]


# ---------------------------------------------------------------------------
# Stage 3b – Emfatic tool service
# ---------------------------------------------------------------------------
FROM nginx:1.24.0-bullseye AS toolservice-emfatic

ENV DEBIAN_FRONTEND=noninteractive
ENV PORT=80

RUN apt-get update \
    && apt-get install -y python3-minimal maven tini netcat \
    && rm -rf /var/lib/apt/lists/*

# Copy built tool and sources (only the modules required for the emfatic profile)
COPY --from=mavenbuilder /root/.m2 /root/.m2
COPY --from=mavenbuilder /usr/src/toolfunctions/pom.xml /toolservice/pom.xml
COPY --from=mavenbuilder /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.core /toolservice/com.mde-network.ep.toolfunctions.core
COPY --from=mavenbuilder /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.emf /toolservice/com.mde-network.ep.toolfunctions.emf
COPY --from=mavenbuilder /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.emfatic /toolservice/com.mde-network.ep.toolfunctions.emfatic
COPY --from=mavenbuilder /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.emfaticfunction /toolservice/com.mde-network.ep.toolfunctions.emfaticfunction

# Copy files for webserver
COPY static.emfatic/nginx.conf.template /etc/nginx.conf.template

RUN rm -r /usr/share/nginx/html/*
COPY --from=staticbuild-emfatic /usr/src/mdenet-tool/dist /usr/share/nginx/html

WORKDIR /toolservice

# Due to https://issues.apache.org/jira/browse/MDEP-568, m-dependency-p
# is not a practical solution for ensuring all dependencies are available.
#
# We use https://github.com/qaware/go-offline-maven-plugin instead.
# TODO: This was commented out in the original Docker file, but is active in some of the other tools. Need to understand which is correct.
#RUN mvn -B de.qaware.maven:go-offline-maven-plugin:1.2.8:resolve-dependencies

ADD static.emfatic/start.sh /
RUN chmod +x /start.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/start.sh"]


# ---------------------------------------------------------------------------
# Stage 3c – OCL tool service
# ---------------------------------------------------------------------------
FROM nginx:1.24.0-bullseye AS toolservice-ocl

ENV DEBIAN_FRONTEND=noninteractive
ENV PORT=80

RUN apt-get update \
    && apt-get install -y python3-minimal openjdk-17-jdk maven tini netcat \
    && rm -rf /var/lib/apt/lists/*

# Copy built tool and sources (only the modules required for the ocl profile)
COPY --from=mavenbuilder /root/.m2 /root/.m2
COPY --from=mavenbuilder /usr/src/toolfunctions/pom.xml /toolservice/pom.xml
COPY --from=mavenbuilder /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.core /toolservice/com.mde-network.ep.toolfunctions.core
COPY --from=mavenbuilder /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.eclipseocl /toolservice/com.mde-network.ep.toolfunctions.eclipseocl
COPY --from=mavenbuilder /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.eclipseoclfunction /toolservice/com.mde-network.ep.toolfunctions.eclipseoclfunction

# Copy files for webserver
COPY static.ocl/nginx.conf.template /etc/nginx.conf.template

RUN rm -r /usr/share/nginx/html/*
COPY --from=staticbuild-ocl /usr/src/mdenet-tool/dist /usr/share/nginx/html

WORKDIR /toolservice

# Due to https://issues.apache.org/jira/browse/MDEP-568, m-dependency-p
# is not a practical solution for ensuring all dependencies are available.
#
# We use https://github.com/qaware/go-offline-maven-plugin instead.
# TODO: This was commented out in the original Docker file, but is active in some of the other tools. Need to understand which is correct.
#RUN mvn -B de.qaware.maven:go-offline-maven-plugin:1.2.8:resolve-dependencies

ADD static.ocl/start.sh /
RUN chmod +x /start.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/start.sh"]


# ---------------------------------------------------------------------------
# Stage 3d – Conversion (Epsilon) tool service
# ---------------------------------------------------------------------------
FROM nginx:1.24.0-bullseye AS toolservice-conversion

ENV DEBIAN_FRONTEND=noninteractive
ENV PORT=80

RUN apt-get update \
    && apt-get install -y python3-minimal maven tini netcat \
    && rm -rf /var/lib/apt/lists/*

# Copy tool sources
COPY services/epsilon /toolservice

# Copy additional built tool and sources (only the modules required for the epsilon profile)
COPY --from=mavenbuilder /root/.m2 /root/.m2
COPY --from=mavenbuilder /usr/src/toolfunctions/pom.xml /toolservice-add/pom.xml
COPY --from=mavenbuilder /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.core /toolservice-add/com.mde-network.ep.toolfunctions.core
COPY --from=mavenbuilder /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.emf /toolservice-add/com.mde-network.ep.toolfunctions.emf
COPY --from=mavenbuilder /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.epsilon /toolservice-add/com.mde-network.ep.toolfunctions.epsilon
COPY --from=mavenbuilder /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.epsilonfunction /toolservice-add/com.mde-network.ep.toolfunctions.epsilonfunction

# Copy files for webserver
COPY static.conversion/nginx.conf.template /etc/nginx.conf.template

RUN rm -r /usr/share/nginx/html/*
COPY --from=staticbuild-conversion /usr/src/mdenet-tool/dist /usr/share/nginx/html

WORKDIR /toolservice

# Due to https://issues.apache.org/jira/browse/MDEP-568, m-dependency-p
# is not a practical solution for ensuring all dependencies are available.
#
# We use https://github.com/qaware/go-offline-maven-plugin instead.
RUN mvn -B de.qaware.maven:go-offline-maven-plugin:1.2.8:resolve-dependencies

ADD static.conversion/start.sh /
RUN chmod +x /start.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/start.sh"]


# ---------------------------------------------------------------------------
# Stage 3e – Xtext tool service
# ---------------------------------------------------------------------------
FROM tomcat:9.0.76-jdk17-temurin AS toolservice-xtext

# See https://github.com/mdenet/educationplatform-docker/blob/main/README.md#environment-variables
ARG ES_ADDRESS
ARG ES_DEPLOY_ADDRESS

# toolservice main endpoint port
ENV TS_PORT=9000
# editor server internal port
ENV ES_PORT=10001

ENV INSTALL_DIR=/usr/local

# Paths for editor builds
ENV ES_DIR=/editorserver
ENV ES_BUILD_LOCATION=${ES_DIR}/build
ENV ES_UPLOAD_LOCATION=${ES_DIR}/uploads
ENV ES_DEPLOY_FILE_LOCATION=${CATALINA_HOME}/webapps

# The release of node to install
ENV NODE_VERSION=19.9.0

RUN apt-get update && apt-get install -y --no-install-recommends unzip zip xz-utils maven cron psmisc

# Install node (detect architecture for arm64/x64 compatibility)
WORKDIR $INSTALL_DIR
RUN ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then NODE_ARCH="linux-arm64"; else NODE_ARCH="linux-x64"; fi \
    && NODE_RELEASE="node-v${NODE_VERSION}-${NODE_ARCH}" \
    && echo "Installing ${NODE_RELEASE}" \
    && curl --output ${NODE_RELEASE}.tar.xz https://nodejs.org/download/release/v${NODE_VERSION}/${NODE_RELEASE}.tar.xz \
    && tar -xf ${NODE_RELEASE}.tar.xz \
    && ln -s ${INSTALL_DIR}/${NODE_RELEASE} ${INSTALL_DIR}/node
ENV PATH="$INSTALL_DIR/node/bin:${PATH}"

WORKDIR /usr/src/toolfunctions

# Copy built tool and sources (only the modules required for the xtext profile)
COPY --from=mavenbuilder /root/.m2 /root/.m2
COPY --from=mavenbuilder /usr/src/toolfunctions/pom.xml /toolservice/pom.xml
COPY --from=mavenbuilder /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.core /toolservice/com.mde-network.ep.toolfunctions.core
COPY --from=mavenbuilder /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.emf /toolservice/com.mde-network.ep.toolfunctions.emf
COPY --from=mavenbuilder /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.xtext /toolservice/com.mde-network.ep.toolfunctions.xtext
COPY --from=mavenbuilder /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.xtextfunction /toolservice/com.mde-network.ep.toolfunctions.xtextfunction

COPY xtext/acemodebundler /acemodebundler
COPY xtext/editorserver ${ES_DIR}

WORKDIR /acemodebundler

RUN npm ci

WORKDIR ${ES_DIR}

RUN npm ci --omit=dev

EXPOSE ${ES_PORT}
EXPOSE ${TS_PORT}
# 8080 is the default tomcat public port
EXPOSE 8080

COPY xtext/start.sh ${ES_DIR}/start.sh
COPY xtext/cron-setup.sh ${ES_DIR}/cron-setup.sh

RUN chmod +x ${ES_DIR}/start.sh
RUN chmod +x ${ES_DIR}/cron-setup.sh

# deploy tool static files
COPY --from=staticbuild-xtext /usr/src/mdenet-tool/dist/ROOT.war ${ES_DEPLOY_FILE_LOCATION}/ROOT.war

# Cron time for scheduled stop
ENV XTEXT_ES_STOP_CRON_TIME="* 4 * * *"

# setup cron job to periodically stop the server
RUN ./cron-setup.sh

ENTRYPOINT [ "/bin/bash", "start.sh" ]
