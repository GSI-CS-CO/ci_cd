#Procedure to perform parameterized build in Jenkins

Jenkins has an in-built function called Parameterized Build wherein the parameter passed to this function can be used inside the shell script. The following steps are carried out to use this functionality.

1) Go to any Jenkins project -> configure -> General (Reference project in jenkins: nightly_build_two_branches)

2) Select `This project is parameterized` option

3) Add the type of parameter to be passed under `Add Parameter` option eg: `String parameter`

4) Enter the `name` and `default_value` for the parameter eg: `name: VAR` ; `default_value: exploder5`

5) Use this parameter in the shell script that will be executed within this project.

6) The shell script will gather the information from the string parameter in the Jenkins project and execute further.

## Some Notes

Two options to build the project

1) Build with parameters: When this option is selected, Jenkins will pop up a window for the user to type the parameter which will overwrite the default parameter.

2) Scheduled build: For this option, Jenkins uses the default parameter and builds the project at the scheduled time. If default parameter is not mentioned, empty string is considered as the default parameter.

Usage of parameterized build for bel_projects in a jenkins job

1) This option is useful when Jenkins should build gatewares for multiple form factors from bel_projects

2) A parameterized build project with a string parameter is created to provide the name of the form factor. This parameter is used in a shell script to build the gateware of that particular form factor.

3) If gateware for a different form factor should be built, then the user must just change the name of this parameter in the Jenkins job and the shell script will take care of building the gateware for that particular form factor.

4) Additionally in this project, the user can also change the branch of the git repository from which jenkins should fetch the data to build the gateware (Reference project in jenkins: nightly_build_two_branches). Under `Source Code Management` -> `Branches to build`, mention the branch that is required to build the gateware. The shell script which fetches the data from git repo will refer to this branch and retrieve all the information available in this branch before starting the build process.
