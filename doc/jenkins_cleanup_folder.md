#Fresh project directory for Jenkins job
When a build job is scheduled, at times a few dependent files are not checked out freshly from the repository causing the build to fail. A clear checkout is required to fetch all the data completely and build the gateware (a fresh directory must be created with no previous data)

##Problem statement
When a new Jenkins job is started, an error is displayed on the console output stating `cannot connect to X server` and the build is unsuccessful. This error disappears when the job to build the gateware is compiled for the 1st time from the command line and then all the successive builds are compiled from Jenkins without any error. Using Xvnc plugin from Jenkins has solved this problem.

## Steps to use Xvnc on Jenkins
1) Install Xvnc plugin from Jenkins web interface.

2) Install vnc server on Jenkins IPC using `sudo apt-get install vnc`

3) Start vnc server from command line for the Jenkins user by running `vncserver` on command line. Create a new password when asked for. A new desktop is created.

4) Stop the process using `vncserver -kill $nameofdesktop`

5) Go to project configuration page in a Jenkins project and enable the option `Run Xvnc during build`

6) Build project will create a new desktop every time a build is executed avoiding the error `cannot connect to X server` and compilation is successful.

7) Every jenkins job uses the option mentioned in 5) and each job is configured to delete the existing project directory and create a new directory before fetching all the data from the git repository and performing the build process. 
