#!/bin/sh
set -e

git config --global user.name "Travis CI"
git config --global user.email "noreply+travis@iamareebjamal.org"

export DEPLOY_BRANCH=${DEPLOY_BRANCH:-master}

if [ "$TRAVIS_PULL_REQUEST" != "false" -o "$TRAVIS_REPO_SLUG" != "iamareebjamal/android-test-fastlane" -o  "$TRAVIS_BRANCH" != "$DEPLOY_BRANCH" ]; then
    echo "We upload apk only for changes in master. So, let's skip this shall we ? :)"
    exit 0
fi

git clone --quiet --branch=apk https://iamareebjamal:$GITHUB_API_KEY@github.com/iamareebjamal/android-test-fastlane apk > /dev/null
cd apk
rm *.apk
cp ../app/build/outputs/apk/*.apk .

# Signing Apps

${ANDROID_HOME}/build-tools/25.0.2/zipalign -v -p 4 app-release-unsigned.apk app-release-aligned.apk
cp app-release-aligned.apk app-release.apk
jarsigner -verbose -tsa http://timestamp.comodoca.com/rfc3161 -sigalg SHA1withRSA -digestalg SHA1 -keystore ../scripts/key.jks -storepass $STORE_PASS -keypass $KEY_PASS app-release.apk $ALIAS

for file in *; do
  mv $file test-${file%%}
done

# Create a new branch that will contains only latest apk
git checkout --orphan temporary

# Add generated APK
git add --all .
git commit -am "[Auto] Update Test Apk ($(date +%Y-%m-%d.%H:%M:%S))"

# Delete current apk branch
git branch -D apk
# Rename current branch to apk
git branch -m apk

# Force push to origin since histories are unrelated
git push origin apk --force --quiet > /dev/null
