# Notify build error through email in Jenkins

1) Jenkins performs email notification using SMTP server authentication. TLS (Transport Layer Security) encryption is required to use the SMTP server to send emails. The following system property should be added in the `/etc/default/jenkins` file for TLS encryption.

`JAVA_ARGS="-Dmail.smtp.starttls.enable=true"`

2) In the web interface of Jenkins server go to `Jenkins -> Manage Jenkins -> Configure system`. Under `Jenkins Location` section, provide the System Admin email address. This is the email address which will send the error information to email recipients. Ex: `csco-tg@gsi.de` is the system admin email id used for Jenkins server on TSL002.

3) In `Jenkins -> Manage Jenkins -> Configure system`, under Email Notification section, provide the following details:

SMTP Server: `smtp.gsi.de`

Default user e-mail suffix: `@gsi.de`

In the Advanced option, SMTP Port: `25`

4) To verify if the email notification is working, check the `Test configuration by sending test e-mail` option and provide a `Test e-mail recipient`. Click on `Test Configuration`. 

5) `email sent successfully` message is displayed if the configuration is right.

# Configuring Jenkins Project to receive email on Build Fail

1) Go to a `Jenkins Project -> Configure -> Post build actions -> Email notification`

2) Under Recipients column, provide the list of email recipients to receive the Build fail error mail.

3) Check the option `Send e-mail for every unstable build` and Save the configuration.

4) An email will be sent for every unstable build.
