#!/bin/bash
#This script is written to check if there are any critical timing warnings during the balloon build of gateware for different formfactors
#Checking is done based on the status report generated during build process

#Variables
exp_job_path=/home/timing/jenkins_jobs/balloon_build_exploder5/syn/gsi_exploder5/exploder5_csco_tr/exploder5_csco_tr.sta.rpt
pex_job_path=/home/timing/jenkins_jobs/balloon_build_pexarria5/syn/gsi_pexarria5/control/pci_control.sta.rpt
vet_job_path=/home/timing/jenkins_jobs/balloon_build_vetar2a/syn/gsi_vetar2a/wr_core_demo/vetar2a.sta.rpt
scu3_job_path=/home/timing/jenkins_jobs/balloon_build_scu3/syn/gsi_scu/control3/scu_control.sta.rpt
scu2_job_path=/home/timing/jenkins_jobs/balloon_build_scu2/syn/gsi_scu/control2/scu_control.sta.rpt
dm_job_path=/home/timing/jenkins_jobs/balloon_build_datamaster/syn/gsi_pexarria5/ftm/ftm.sta.rpt

#Check if gateware built for exploder5 has any critical timing warnings
if [ -f $exp_job_path ]; then
        if (grep -rqn $exp_job_path -e "Critical Warning (332148): Timing requirements not met"); then
                echo "Exploder5 has critical warning. Timing requirements not met"
        else
                echo "Exploder5 has no timing critical warning"
        fi
else
	echo "Exploder5 nightly build was not stable"
fi

#Check if gateware built for pexarria5 has any critical timing warnings
if [ -f $pex_job_path ]; then
        if (grep -rqn $pex_job_path -e "Critical Warning (332148): Timing requirements not met"); then
                echo "Pexarria5 has critical warning. Timing requirements not met"
        else
                echo "Pexarria5 has no timing critical warning"
        fi
else
        echo "Pexarria5 nightly build was not stable"
fi

#Check if gateware built for vetar2a has any critical timing warnings
if [ -f $vet_job_path ]; then
        if (grep -rqn $vet_job_path -e "Critical Warning (332148): Timing requirements not met"); then
                echo "Vetar2a has critical warning. Timing requirements not met"
        else
                echo "Vetar2a has no timing critical warning"
        fi
else
        echo "Vetar2a nightly build was not stable"
fi

#Check if gateware built for SCU3 has any critical timing warnings
if [ -f $scu3_job_path ]; then
        if (grep -rqn $scu3_job_path -e "Critical Warning (332148): Timing requirements not met"); then
                echo "SCU3 has critical warning. Timing requirements not met"
        else
                echo "SCU3 has no timing critical warning"
        fi
else
        echo "SCU3 nightly build was not stable"
fi

#Check if gateware built for SCU2 has any critical timing warnings
if [ -f $scu2_job_path ]; then
        if (grep -rqn $scu2_job_path -e "Critical Warning (332148): Timing requirements not met"); then
                echo "SCU2 has critical warning. Timing requirements not met"
        else
                echo "SCU2 has no timing critical warning"
        fi
else
        echo "SCU2 nightly build was not stable"
fi

#Check if gateware built for datamaster has any critical timing warnings
if [ -f $dm_job_path ]; then
        if (grep -rqn $dm_job_path -e "Critical Warning (332148): Timing requirements not met"); then
                echo "Datamaster has critical warning. Timing requirements not met"
        else
                echo "Datamaster has no timing critical warning"
        fi
else
        echo "Datamaster nightly build was not stable"
fi
