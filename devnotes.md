# Procedures & roadmap

## Procedures
* used ChatGPT to help produce the Dockerfile & build_android.sh which was built off of the master branch to become a new branch *docker-build-setup*
* used Gemini to help refactor the build environment in order to build for an earlier version, v4.2.LTS than what was on *master*. If you are reading this, you probably figured out that this is all on *build-v4.2.LTS*, which is based off of the tag *v4.2.LTS*.

## Roadmap
* get master to build a simple library without the --full
* understand where the code should be checked out in order to build the object *mobile-ffmpeg-full-4.2.LTS.aar*
* refactor build_android.sh for build options for --lts and --full
* build the library object needed
* build and test Story Producer
* rename *master* as *master-archive*, and *develop* as *develop-archive*
* put finished code from *build_v4.2.LTS* to *master* and to *develop*
* research how to create this library so it is compliant with Google Play Store's new requirement for applications targetting 64 bit devices to support 16KB memory page sizes -> for apps targetting Android 15 (API 35)
* refactor the 4.2.LTS branch for 16KB compliance and API 35
* OR if the above is not possible, then find out what is needed to make Story Producer work with a more recent version of mobile-ffmpeg.
* refactor SP and get it to build with a more recent artifact of mobile-ffmpeg
* refactor mobile-ffmpeg, this project to be able to be built
* build & test SP with the refactored mobile-ffmpeg generated artifact 

## some tools

For cleaning up after a build:
echo "    -> Deleting prebuilt/, .tmp/, android/build/ and build.log"
rm -f build.log
# Delete build directories based on .gitignore and known cache locations
rm -rf prebuilt/ .tmp/ android/build/

For radical cleaning up of docker images
docker system prune


