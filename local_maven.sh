#!/bin/bash
#

JCP_GROUPID=ru.CryptoPro
JCP_VERSION=2.0.41789
#JARS_PATH=/opt/java/jdk1.8.0-162/jre/lib/ext

NEXUS_URL=${NEXUS_URL:-http://localhost:8081}
NEXUS_USR=${NEXUS_USR:-admin}
NEXUS_PWD=${NEXUS_PWD:-admin123}

unpack()
{
JCP_ZIP=$(find $1 -iname "jcp-*.zip"|head -1)
test -n "${JCP_ZIP}" &&
JARS_PATH=$(mktemp -d) &&
unzip -o ${JCP_ZIP} *.jar -d ${JARS_PATH} &&
JARS_PATH=$JARS_PATH/$(basename ${JCP_ZIP}|sed 's/\.zip$//')
}

manifest()
{
unzip -q -p $1 META-INF/MANIFEST.MF|grep "$2"|cut -d ' ' -f 2|tr -d '\r'|tr -d '\n'
}

release_version()
{
 manifest $1 "Release-Version"
}

group_id()
{
 manifest $1 "Implementation-Vendor-Id"
}

artifact_id()
{
 manifest $1 "Implementation-Title"
}


maven()
{
 JAR_FILE=$1
 GROUP_ID=$2
 ARTIFACT_ID=$3
 VERSION=$4
mvn install:install-file -Dfile=${JAR_FILE} \
-DgroupId=${GROUP_ID} \
-DartifactId=${ARTIFACT_ID} \
-Dversion=${VERSION} \
-Dpackaging=jar
}

nexus()
{
 JAR_FILE=$1
 GROUP_ID=$2
 ARTIFACT_ID=$3
 VERSION=$4
 mvn deploy:deploy-file \
--settings ${SETTINGS_XML} -U \
-Dfile=${JAR_FILE} \
-DgroupId=${GROUP_ID} \
-DartifactId=${ARTIFACT_ID} \
-Dversion=${VERSION} \
-Dpackaging=jar \
-DrepositoryId=nexus \
-Durl=$NEXUS_URL/repository/maven-releases
}

install_jar()
{
 JCP_ARTIFACTID=$1
 JAR_FILE=${JARS_PATH}/${JCP_ARTIFACTID}.jar
 GROUP_ID=${JCP_GROUPID}
 VERSION=${JCP_VERSION}
 test -f ${JAR_FILE} && GROUP_ID=$(group_id ${JAR_FILE})
 test -f ${JAR_FILE} && ARTIFACT_ID=$(artifact_id ${JAR_FILE})
 test -f ${JAR_FILE} && VERSION=$(release_version ${JAR_FILE})
 test -z "${GROUP_ID}" && GROUP_ID=${JCP_GROUPID}
 test -z "${ARTIFACT_ID}" && ARTIFACT_ID=${JCP_ARTIFACTID}
 test -z "${VERSION}" && VERSION=${JCP_VERSION}
 test -f ${JAR_FILE}  && maven ${JAR_FILE} ${GROUP_ID} ${ARTIFACT_ID} ${VERSION}
 test -f ${JAR_FILE} && nexus ${JAR_FILE} ${GROUP_ID} ${ARTIFACT_ID} ${VERSION}
 test -n "${GRADLE_FILE}" && echo -e "\nimplementation '${GROUP_ID}:${ARTIFACT_ID}:${VERSION}'" >> ${GRADLE_FILE}
 test -n "${POM_FILE}" && echo -e "\n\t<dependency>\n\t\t<groupId>${GROUP_ID}</groupId>\n\t\t<artifactId>${ARTIFACT_ID}</artifactId>\n\t\t<version>${VERSION}</version>\n\t</dependency>\n" >> ${POM_FILE}
}

parse_url() {
  eval $(echo "$1" | sed -e "s#^\(\(.*\)://\)\?\(\([^:@]*\)\(:\(.*\)\)\?@\)\?\([^/?]*\)\(/\(.*\)\)\?#${PREFIX:-URL_}SCHEME='\2' ${PREFIX:-URL_}USER='\4' ${PREFIX:-URL_}PASSWORD='\6' ${PREFIX:-URL_}HOST='\7' ${PREFIX:-URL_}PATH='\9'#")
}

settings_xml()
{
 test -z "$SETTINGS_XML" && 
 SETTINGS_XML=$(mktemp)
cat << EOF > ${SETTINGS_XML}
 <?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
<servers>
  <server>
      <id>nexus</id>
      <username>$1</username>
      <password>$2</password>
    </server>
  </servers>
</settings>
EOF
}


pre()
{
 test -n "${GRADLE_FILE}" && echo -e "\ndependencies {\n">${GRADLE_FILE}
 test -n "${POM_FILE}" && POM_FILE="_${POM_FILE}" && echo -e "\n<dependencies>\n">${POM_FILE}
 test -n "${NEXUS_URL}" &&
 PREFIX="NEXUS_URL_" 
 parse_url "$NEXUS_URL"
 test -n "${NEXUS_URL_USER}" && 
 test -n "${NEXUS_URL_PASSWORD}" && 
 NEXUS_USR=${NEXUS_URL_USER} &&
 NEXUS_PWD=${NEXUS_URL_PASSWORD}
 settings_xml $NEXUS_USR $NEXUS_PWD
 NEXUS_URL="$NEXUS_URL_SCHEME://$NEXUS_URL_HOST/$NEXUS_URL_PATH"
}

post()
{
 test -n "${GRADLE_FILE}" && echo -e "\n}\n" >>${GRADLE_FILE}
 test -n "${POM_FILE}" && echo -e "\n</dependencies>\n" >> ${POM_FILE}
 test -n "${GRADLE_FILE}" && cat ${GRADLE_FILE}
 test -n "${POM_FILE}" && cat ${POM_FILE}
 #cat ${SETTINGS_XML} 
 rm -rf ${SETTINGS_XML}
 rm -rf ${JARS_PATH}
}

test -z "${JARS_PATH}" &&
unpack $(pwd)

pre

install_jar JCP
install_jar JCryptoP
install_jar CAdES
install_jar asn1rt
install_jar ASN1P


post
