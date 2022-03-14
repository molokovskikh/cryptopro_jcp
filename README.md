# cryptopro jcp
Установка Java CryptoPro в локальные maven и nexus 
* git clone https://github.com/molokovskikh/cryptopro_jcp
* SCRIPT_HOME=$(pwd)
* cd $JCP_X_Y_ZIP_PATH
* export NEXUS_URL="http://admin:admin123@localhost:8089"
> If want to see part of pom dependencies then can set **export POM_FILE=pom.xml**<br>
> If want to see part of build.gradle dependencies then can set **export GRADLE_FILE=build.gradle**
* $SCRIPT_HOME/local_maven.sh
* cat $GRADLE_FILE
 
