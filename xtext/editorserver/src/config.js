

export const config = {

    port: process.env.ES_PORT || "10000",

    address: process.env.ES_ADDRESS || "http://127.0.0.1:" + process.env.ES_PORT || "10000",

    deployAddress: process.env.ES_DEPLOY_ADDRESS || "http://127.0.0.1:8074",

    deployFileLocation: process.env.ES_DEPLOY_FILE_LOCATION || "/usr/local/tomcat/webapps",

    buildFileLocation: process.env.ES_BUILD_LOCATION || "/editorserver/build",

    endpointsPrefix: process.env.ES_ENDPOINT_PREFIX || "",

    trustedWebOrigins: [process.env.TRUSTED_ORIGIN || "http://127.0.0.1:8080"],


}
