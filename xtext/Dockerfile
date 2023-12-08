# syntax=docker/dockerfile:1


FROM node:19-bullseye AS toolstaticbuild

RUN apt-get update && apt-get install -y --no-install-recommends zip

WORKDIR /usr/src/mdenet-tool

# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)
COPY xtext/static.xtext/package*.json ./

COPY xtext/static.xtext .

RUN npm install; npm run build; chmod -R 755 dist/

# CORS configuration for webapp
COPY xtext/acemodebundler/web.xml /usr/src/mdenet-tool/dist/WEB-INF/web.xml

RUN cd dist && zip -r ROOT.war .




FROM maven:3.6.3-openjdk-17 AS toolfunctions

#Copy ocl toolfunction source and its dependencies
COPY services/com.mde-network.ep.toolfunctions.core /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.core
COPY services/com.mde-network.ep.toolfunctions.emf /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.emf
COPY services/com.mde-network.ep.toolfunctions.xtext /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.xtext
COPY services/com.mde-network.ep.toolfunctions.xtextfunction /usr/src/toolfunctions/com.mde-network.ep.toolfunctions.xtextfunction
COPY services/pom.xml /usr/src/toolfunctions/

WORKDIR /usr/src/toolfunctions

RUN mvn clean install -Pxtext

# Get runtime dependencies 
RUN mvn org.apache.maven.plugins:maven-dependency-plugin:3.6.0:get -Dartifact=com.google.cloud.functions:function-maven-plugin:0.9.5 && mvn org.apache.maven.plugins:maven-dependency-plugin:3.6.0:get -Dartifact=org.apache.maven.plugins:maven-deploy-plugin:2.7 


FROM tomcat:9.0.76-jdk17-temurin


# toolserice main endpoint port
ENV TS_PORT=9000
# editor server internal port
ENV ES_PORT=10001 

ENV INSTALL_DIR=/usr/local

# The release of node to install
ENV NODE_VERSION=19.9.0
ENV NODE_RELEASE=node-v${NODE_VERSION}-linux-x64

RUN apt-get update && apt-get install -y --no-install-recommends unzip zip xz-utils maven 

# Install node
WORKDIR $INSTALL_DIR
RUN echo installing ${NODE_RELEASE}\
    && curl --output ${NODE_RELEASE}.tar.xz  https://nodejs.org/download/release/v${NODE_VERSION}/${NODE_RELEASE}.tar.xz\
    && tar -xf ${NODE_RELEASE}.tar.xz
ENV PATH="$INSTALL_DIR/${NODE_RELEASE}/bin:${PATH}"


WORKDIR /usr/src/toolfunctions

# Copy built tool and sources
COPY --from=toolfunctions /root/.m2 /root/.m2
COPY --from=toolfunctions /usr/src/toolfunctions /toolservice

COPY xtext/acemodebundler /acemodebundler
COPY xtext/editorserver /editorserver

WORKDIR /acemodebundler

RUN npm ci 

WORKDIR /editorserver

RUN npm ci --omit=dev

EXPOSE ${ES_PORT}
EXPOSE ${TS_PORT}
#8080 is the default tomcat public port
EXPOSE 8080

COPY xtext/start.sh /editorserver/start.sh


RUN chmod +x /editorserver/start.sh

# deploy tool static files
COPY --from=toolstaticbuild /usr/src/mdenet-tool/dist/ROOT.war /usr/local/tomcat/webapps/ROOT.war

ENTRYPOINT [ "/bin/bash", "start.sh" ]