Install the following prerequisites:

* jstools: https://github.com/whitmo/jstools
* Maven 3
* Java 7

Clone the git source repository:

* git clone https://github.com/UBR-KOOP/Geozet.git

Build the javascript source:

* cd geozet/jsbuild
* ./build-all.sh

Verify that 4 js files got created:

* ls -l ../geozet-webapp/src/main/webapp/static/js/

Build the webapp:

* cd ../geozet-webapp
* mvn -Dmaven.test.skip=true

To run the webapp locally you can do:

* mvn jetty:run
