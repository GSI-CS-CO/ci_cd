#These scripts are written in the Jenkins projects under Build option (Execute shell)
#All the scripts for this jenkins project is available in ci_cd git repository
cd
if [ -d ci_cd ]; then
   rm -rf ci_cd
fi

git clone https://github.com/GSI-CS-CO/ci_cd.git
cd ci_cd
git checkout master
git pull
git submodule init
git submodule update --recursive

cd /home/timing/jenkins_jobs/

if [ -d nightly_build_exploder5 ]; then
   rm -rf nightly_build_exploder5
fi
mkdir nightly_build_exploder5
cd nightly_build_exploder5
git clone https://github.com/GSI-CS-CO/bel_projects.git . --recursive

#quartus path to environmental variable
. ~/ci_cd/scripts/nightly/quartus16.sh

#Git checkout proposed_master and update submodules
. ~/ci_cd/scripts/nightly/git_chkout_branch.sh
. ~/ci_cd/scripts/nightly/git_init.sh

cd ip_cores/fpga-config-space
. ~/ci_cd/scripts/nightly/git_init.sh
cd legacy-vme64x-core
. ~/ci_cd/scripts/nightly/git_init.sh
cd ../../wrpc-sw
. ~/ci_cd/scripts/nightly/git_init.sh

#Compilation of gateware
cd ../..
. ~/ci_cd/scripts/nightly/filecopy_websrvr.sh
