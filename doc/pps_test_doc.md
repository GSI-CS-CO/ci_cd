#Procedure to perform PPS test for the CI system
A jenkins job named pps_test is created to perform PPS test on timing receivers.

#Some configuration prior to perform PPS test

File name: saftppsconfig.sh
1) Maximum acceptable time difference between PPS signal generated on different devices is given as 200 ns (can be modified)

2) Number of lines to be considered for time difference calculation from the output of PPS signal generation is 2000 (can be extended depending on the time PPS generation occurs). This number has been considered for PPS generation running for 5 minutes continuously.

3) Reference configuration: provides information about the device that acts as a reference to calculate the time difference between this device and other devices connected to it.

#Generation and Testing of PPS signals (ref CI_CD git repo: ci_cd/scripts/ci_testing/pps/)
1) Make sure that saftlib is installed into the PC (reference: tsl004 for PPS test) performing the PPS generation and saftd is running. Saftd configured for this project is as follows

`saftd exp:dev/wbm0 pex:dev/wbm1`

2) Configure the ports of the reference device to read the PPS signal data (saft-io-ctl function)

3) Generate the pps signal on devices (saft-pps-gen function)

4) Read the data on to the reference device (saft-io-ctl function)

5) After a period of time, kill the running saftlib processes.

6) Once the generation of PPS signal is complete, calculate the time difference between reference input (PPS signal from Network switch) and PPS signal from timing receivers (Pexarria5 and SCU3)

7) Result of this test is displayed as a console output on Jenkins project page.
