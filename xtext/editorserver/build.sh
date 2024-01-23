#!/bin/bash

archiveFile=$1
buildDir=${ES_BUILD_LOCATION}/$archiveFile
deployDir=${ES_DEPLOY_FILE_LOCATION}

acemodebundlerDir=/acemodebundler
modeBasePath=xtext-resources/generated
modeFileName=mode.js

# Prepare
mkdir -p $buildDir
mkdir -p $deployDir
echo null > ${ES_BUILD_LOCATION}/$archiveFile/build.res
cp ./uploads/$archiveFile $buildDir

cd $buildDir

# Build
unzip -q $archiveFile

parentProjectName=$(find -name '*.parent')
parentProjectName=${parentProjectName#./}
parentProjectName=${parentProjectName%.parent}
cd $buildDir/*.parent

mvn --batch-mode --quiet clean install > ${ES_BUILD_LOCATION}/$archiveFile/build.log 2>&1
    # sdtout and std error are combined to preserve the interleaving of logs.

# Save the exit code
echo $? > ${ES_BUILD_LOCATION}/$archiveFile/build.res

# Run a second round build with the new web servlet code
# We can only do this here because we first need to have Xtext create the original file
cd $buildDir/*.web

languageExtension=$(find -name 'mode-*.js')
languageExtension=${languageExtension##*-} 
languageExtension=${languageExtension%.*}

cd ./src/
languagePackageName=$(find -name 'web')
languagePackageName=${languagePackageName#./}
languagePackageName=${languagePackageName////.}
cd `find -name 'web'`
languageClassName=$(find -name '*Servlet.java')
languageClassName=${languageClassName#./}
languageClassName=${languageClassName%Servlet.java}
cp /editorserver/Servlet.java *Servlet.java
sed -i "s@DSLQNAME@$languagePackageName@" *Servlet.java
sed -i "s@DSLNAME@$languageClassName@" *Servlet.java
sed -i "s@LANGUAGE_EXT@$languageExtension@" *Servlet.java

cp /editorserver/model2plantuml.egl ./model2plantuml.egl

# Ensure EGL and PlantUML are available to generated tool server for diagram generation
cd $buildDir/*.web
cp /editorserver/web-pom.xml ./pom.xml
sed -i "s@DSL_BASE_NAME@$parentProjectName@" pom.xml

cd $buildDir/*.parent

mvn --batch-mode --quiet install

cd ..

# Prepare for bundling
echo Prepare for bundling - $(pwd)
cp -R $acemodebundlerDir .
mkdir wartemp && cd wartemp
mv $buildDir/*.web/target/*.war .
unzip -q *.war && rm *.war

# Convert the mode
mv $modeBasePath/mode-*.js $modeBasePath/$modeFileName
sed -i -z -f ../acemodebundler/xtextAceModeToEpMode.sed $modeBasePath/$modeFileName
sed -i 's/\x0//g' $modeBasePath/$modeFileName
sed -i "s@LANGUAGE_EXT@$languageExtension@" $modeBasePath/$modeFileName

# Bundle the generated mode
mv $modeBasePath/$modeFileName ../acemodebundler/src/$modeFileName
npm --prefix ../acemodebundler run build
mv ../acemodebundler/dist/$modeFileName ./$modeBasePath/$modeFileName

# Add Xtext-generated meta-model
metamodelName=$(find $buildDir -name '*.ecore')
cp $metamodelName $modeBasePath/meta-model.ecore

# Add tool definition
cp /editorserver/editor_tool.json ./editor_tool.json

# Add tomcat http headers config
cp ../acemodebundler/web.xml ./WEB-INF/web.xml

zip -q -m -r $archiveFile.war .

# Deploy
mv $archiveFile.war $deployDir/$archiveFile.war
