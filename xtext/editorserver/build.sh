#!/bin/bash

archiveFile=$1
buildDir=$PWD/build/$archiveFile
deployDir=/usr/local/tomcat/webapps

acemodebundlerDir=/acemodebundler
modeBasePath=xtext-resources/generated
modeFileName=mode.js

# Prepare
mkdir -p $buildDir
mkdir -p $deployDir

cp ./uploads/$archiveFile $buildDir

cd $buildDir

# Build
unzip -q $archiveFile

cd $buildDir/*.parent

mvn --batch-mode --quiet clean install

# Run a second round build with the new web servlet code
# We can only do this here because we first need to have Xtext create the original file
cd $buildDir/*.web
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
languageExtension=$(find $modeBasePath -maxdepth 1 -name 'mode-*.js')
languageExtension=${languageExtension##*-} 
languageExtension=${languageExtension%.*}

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
