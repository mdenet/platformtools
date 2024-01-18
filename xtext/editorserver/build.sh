#! /bin/bash

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

cd ./*.parent

mvn --batch-mode --quiet clean install > ${ES_BUILD_LOCATION}/$archiveFile/build.log 2>&1
    # sdtout and std error are combined to preserve the interleaving of logs.

# Save the exit code
echo $? > ${ES_BUILD_LOCATION}/$archiveFile/build.res

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
cp $metamodelName ./xtext-resources/generated/meta-model.ecore

# Add tomcat http headers config
cp ../acemodebundler/web.xml ./WEB-INF/web.xml

zip -q -m -r $archiveFile.war .

# Deploy
mv $archiveFile.war $deployDir/$archiveFile.war
