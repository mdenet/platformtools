#! /bin/bash

# clean any previous editor instances
find ${CATALINA_HOME}/webapps/ -type f -not -name 'ROOT.war' -delete
find ${CATALINA_HOME}/webapps/ -type d -not -name 'ROOT' -delete

# start tomcat
catalina.sh run &

# start toolfunction
(cd /toolservice/com.mde-network.ep.toolfunctions.xtextfunction; \
    mvn function:run \
    -Drun.functionTarget=com.mdenetnetwork.ep.toolfunctions.xtextfunction.RunXtextFunction \
    -Drun.port=$TS_PORT) &

# start editorserver
node ./src/server.js &

# wait for them all
wait -n