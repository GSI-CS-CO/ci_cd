#Backup Jenkins home directory 
Jenkins has a plugin to back up the jenkins home directory which contains the configuration files of all the jenkins jobs created.

##Install and configure backup plugin

1. The plugin to create a backup of Jenkins home directory is called **Thin Backup**. Install this plugin from `Manage Jenkins -> Manage plugin` page in the Jenkins web interface.

2. After installation, this plugin is visible under `Manage Jenkins` page. Go to the `Settings` page of this plugin and configure the required data. For example `Backup directory`, `Backup schedule`, `Max number of backup sets` and other relevant details if required. Refer jenkins web interface on tsl002.acc.gsi.de:8080 for details.

3. Scheduled backup of Jenkins home directory will be carried out after the above configuration is complete. User can backup Jenkins instantly by using the `Backup Now` option available in the `Thin Backup` page. The backup is placed in the directory mentioned in the `Settings` page.

4. To restore the backup, use the `Restore` option available in the `Thin Backup` page. A drop down list of backups will be displayed for selection. Select the backup required and click on `Restore`. Restarting Jenkins after this will restore all the configuration files from this backup into the Jenkins home directory.

##Copy Jenkins home directory manually to a different location

1. In order to not loose any data of Jenkins if the Jenkins PC crashes, it is recommended to manually copy the Jenkins home directory to a different IPC or to a git repository.

2. In case of a crash, the copied directory can be used to restore Jenkins to its original condition.
