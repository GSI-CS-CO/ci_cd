# Accessing Jenkins from command line

Jenkins CLI is an interface that allows the user to access Jenkins from the shell. 

1) Download the application using `wget http://$web_address_jenkins/jnlpJars/jenkins-cli.jar`

Ex: `wget http://tsl002.acc.gsi.de:8080/jnlpJars/jenkins-cli.jar`

2) Run this application on the command line using

`java -jar jenkins-cli.jar -s http://$web_address_jenkins/ help --username $USERNAME --password $PASSWORD`

Ex: `java -jar jenkins-cli.jar -s http://tsl002.acc.gsi.de:8080/ list-jobs --username $USERNAME --password $PASSWORD`


# Some Notes

1) Access the jenkins-cli.jar file from the path it has been downloaded to.

Ex: `/home/timing/Downloads: java -jar jenkins-cli.jar -s http://tsl002.acc.gsi.de:8080/ get-job $JOB_NAME --username $USERNAME --password $PASSWORD`

# Possible Issues

1)Some commands for Jenkins CLI requires that the access be given to anonymous user. Provide authorization for Anonymous user in the web interface.

`Manage Jenkins -> Configure global security -> Authorization -> Matrix based security -> Anonymous (Tick Administer)`

This issue has been logged as a bug in the Jenkins website. Link [here](https://issues.jenkins-ci.org/browse/JENKINS-12543)
