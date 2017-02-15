#These scripts are written in the Jenkins projects under Build option (Execute shell)
#All the scripts for jenkins project is available in /home/timing/shell_scripts directory
cd /home/timing/jenkins_jobs/

if [ -d balloon_build_exploder5 ]; then
   rm -rf balloon_build_exploder5
fi
mkdir balloon_build_exploder5
cd balloon_build_exploder5
git clone https://github.com/GSI-CS-CO/bel_projects.git . --recursive

#quartus path to environmental variable
. ~/shell_scripts/quartus16.sh

#Git checkout branch "balloon" and update submodules
. ~/shell_scripts/git_chkout_branch.sh
. ~/shell_scripts/git_init.sh

cd ip_cores/fpga-config-space
. ~/shell_scripts/git_init.sh
cd legacy-vme64x-core
. ~/shell_scripts/git_init.sh
cd ../../wrpc-sw
. ~/shell_scripts/git_init.sh

#Compilation of gateware
cd ../..
. ~/shell_scripts/balloon_filecopy_websrvr.sh
