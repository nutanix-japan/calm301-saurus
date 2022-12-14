---
title: "Calm: Windows Workloads"
---

*The estimated time to complete this lab is 60 minutes.*

# Overview

**In this exercise you will explore the basics of working with Windows
workloads in Nutanix Calm by building and deploying a blueprint that
installs and configures a multi-tier** [bug
tracker](http://bugnetproject.com/documentation/) **web app using
Microsoft SQL Server database & IIS webserver. This lab assumes you are
familiar with basic Calm functionality or have completed the**
`calm_linux`{.interpreted-text role="ref"} **lab.**

# Creating the Blueprint

1.  Within Calm, create a new **Multi VM/Pod Blueprint**.

2.  Fill out the following fields and click **Proceed** to launch the
    Blueprint Editor:

    -   **Name** - *Initials*-CalmWindowsIntro
    -   **Description** - \[BugNET\](http://@@{MSIIS.address}@@/bugnet)
    -   **Project** - *Initials*-Calm

    ::: note
    ::: title
    Note
    :::

    Using the description value provided will create a hyperlink to the
    BugNET application to launch once deployment has completed.
    :::

3.  Click **Credentials** and create the following two credentials:

      --------------------- --------------------- ---------------------
      **Credential Name**   WIN_VM_CRED           SQL_CRED

      **Username**          Administrator         Administrator

      **Secret Type**       Password              Password

      **Password**          nutanix/4u            Str0ngSQL/4u\$
      --------------------- --------------------- ---------------------

    ![](images/credentials.png)

4.  Click **Save** and return back to the Blueprint Editor.

5.  ::: note
    ::: title
    Note
    :::
    :::

    **This step illustrated the ability to download the image
    dynamically. This iso file was more than 3 GB and would take some
    time to load. Skip this step because the iso file was already
    uploaded in the image in Prism Central.**

> Click **Configuration** and create the following **Downloadable Image
> Configuration**:
>
> > -   **Package Name** - MSSQL2014_ISO
> > -   **Description** - Microsoft SQL 2014 Installation ISO
> > -   **Image Name** - MSSQL2014.iso
> > -   **Image Type** - ISO Image
> > -   **Architecture** - X86_64
> > -   **Source URI** -
> >     <http://download.microsoft.com/download/7/9/F/79F4584A-A957-436B-8534-3397F33790A6/SQLServer2014SP3-FullSlipstream-x64-ENU.iso>
> > -   **Product Name** - MSSQL
> > -   **Product Version** - 2014
> > -   **Checksum Algorithm** - *Leave blank*
> > -   **Checksum Value** - *Leave blank*
> >
> > ![](images/downloadable_image_config.png)

1.  Click **Save** and return back to the Blueprint Editor.

2.  Using the **Default** Application Profile, specify the following
    **Variables** in the **Configuration Panel**:

      -------------------------------------------------------------------------
      **Name**          **Data Type** **Value** \|   **Secret**   **Runtime**
      ----------------- ------------- -------------- ------------ -------------
      DbName            String        BugNET \|      No           Yes

      DbUsername        String        BugNETUser \|  No           Yes

      DbPassword        String        Nutanix/4u\$   Yes          Yes
                                      \|                          

      User_initials     String        *Leave blank*  No           Yes
                                      \|                          
      -------------------------------------------------------------------------

    ![](images/variables.png)

3.  Click **Save**.

# Adding Services

1.  Under **Application Overview \> Services**, click
    `plus-circle`{.interpreted-text role="fa"} twice to add two new
    Services.

    ![](images/create_service.png)

2.  Use the table below to complete the **VM** fields for each service:

      ------------------------- --------------------------- ---------------------------
      **Service Name**          **MSSQL**                   **MSIIS**

      **Name**                  MSSQL2014                   MSIIS8

      **Cloud**                 Nutanix                     Nutanix

      **Operating System**      Windows                     Windows

      **VM Name**               @@{User_initials}@@-MSSQL   @@{User_initials}@@-MSIIS

      **Number of Images**      2                           1

      **Image 1**               Windows2016                 Windows2016

      **Device Type 1**         DISK                        DISK

      **Device Bus 1**          SCSI                        SCSI

      **Bootable 1**            Yes                         Yes

      **Image 2**               MSSQL2014_ISO               N/A

      **Device Type 2**         CD-ROM                      N/A

      **Device Bus 2**          IDE                         N/A

      **Bootable 2**            No                          N/A

      **vCPUs**                 2                           2

      **Cores per vCPU**        2                           2

      **Memory (GiB)**          6                           6

      **Guest Customization**   Yes                         Yes

      **Type**                  Sysprep                     Sysprep

      **Install Type**          Prepared                    Prepared

      **Script**                *Copy script below table*   *Copy script below table*

      **Additional vDisks**     1                           1

      **Device Type**           DISK                        DISK

      **Device Buse**           SCSI                        SCSI

      **Size (GiB)**            100                         100

      **VGPUs**                 None                        None

      **Categories**            None                        None

      **Network Adapters**      1                           1

      **NIC 1**                 Rx-Automation-Network       Rx-Automation-Network

      **Check log-in upon       Yes                         Yes
      create**                                              

      **Credential**            WIN_VM_CRED                 WIN_VM_CRED

      **Address**               NIC 1                       NIC 1

      **Connection Type**       Windows (Powershell)        Windows (Powershell)

      **Connection Port**       5985                        5985

      **Delay (in seconds)**    Increase to **90**          Increase to **90**
      ------------------------- --------------------------- ---------------------------

    Take a minute to review the Sysprep script, a short description
    follows after.

    ::: {.literalinclude language="xml"}
    Sysprep-unattended.xml
    :::

    You can see the VMs being configured to autologon to the local
    Administrator account using the WIN_VM_CRED password. While this
    exercise will not join the VMs to an Active Directory domain, you
    could use either Sysprep or a Package Install task script to
    automate the joining of a domain.

    Additionally, the firewall is configured to allow port 5985 which
    Calm uses to execute PowerShell scripts against the host.

    ::: note
    ::: title
    Note
    :::

    Since Calm 2.5, the **Karan** service VM is no longer required to
    proxy PowerShell commands to the service VMs. Instead, Calm has
    introduced native support for running PowerShell scripts on remote
    hosts.
    :::

    Similar to the Task Manager application in the
    `calm_linux`{.interpreted-text role="ref"} lab, you want to ensure
    the database is available prior to the IIS web server setup.

3.  In the Blueprint Editor, select the **MSIIS** service and create a
    dependency on the **MSSQL** service.

    ![](images/services.png)

# Defining Package Install

For **each** of the following 7 scripts (3 for MSSSQL and 4 for MSIIS),
the **Type**, **Script Type**, and **Credential** fields will be the
same:

-   **Type** - Execute
-   **Script Type** - PowerShell
-   **Credential** - WIN_VM_CRED

::: note
::: title
Note
:::

If you were working with domain joined VMs, you would require a separate
domain credential to execute PowerShell scripts following the VM being
joined to the domain.
:::

1.  Select the **MSSQL** service and open the **Package** tab in the
    **Configuration Panel**.

2.  Name the package and click **Configure install** to begin adding
    installation tasks.

    You will add multiple scripts to complete each installation. Working
    with multiple scripts allows for easier maintenance and application
    of code across multiple services or blueprints using the Calm **Task
    Library**. The Task Library allows you to create modularized scripts
    to achieve certain common functions such as joining a domain or
    configuring common OS settings.

3.  Under **MSSQL \> Package Install**, click **+ Task** and fill out
    the following fields:

    -   **Task Name** - InitializeDisk1
    -   **Script** -

    ::: {.literalinclude language="posh"}
    InitializeDisk1.ps1
    :::

    The above script simply performs an initialization and format of the
    extra 100GB VDisk added during VM configuration of the service.

4.  Click **Publish To Library \> Publish** to save this task script to
    the Task Library for future use.

5.  Repeat clicking **+ Task** to add the remaining two scripts:

    -   **Task Name** - InstallMSSQL
    -   **Script** -

    ::: {.literalinclude language="posh"}
    InstallMSSQL.ps1
    :::

    Reviewing the above script you can see it is performing an automated
    installation of SQL Server, using the SQL_CRED credential details
    and using the extra 100GB VDisk for the SQL data files.

    According to Nutanix best practices for production database
    deployments, what else would need to be added to the
    VM/installation?

    -   **Task Name** - FirewallRules
    -   **Script** -

    ::: {.literalinclude language="posh"}
    FirewallRules.ps1
    :::

    Reviewing the above script you can see it is allowing inbound access
    through the Windows Firewall for key SQL services.

    Once complete, your MSSQL service should look like this:

    ![](images/mssql_package_install.png)

6.  Select the **MSIIS** service and open the **Package** tab in the
    **Configuration Panel**.

7.  Name the package and click **Configure install** to begin adding
    installation tasks.

8.  Under **MSIIS \> Package Install**, click **+ Task**.

9.  Similar to the first step of the MSSQL service installation, you
    will need to initialize and format the additional 100GB VDisk.
    Rather than manually specifying the same script for this task, click
    **Browse Library**.

10. Select the **InitializeDisk1** task you had previously published and
    click **Select \> Copy**.

    ![](images/task_library.png)

    ::: note
    ::: title
    Note
    :::

    The Task Library also gives you the ability to provide variable
    definitions if there are Calm macros present in the published task.
    :::

11. Specify the **Name** and **Credential**, then repeat clicking **+
    Task** to add the remaining three scripts:

    -   **Task Name** - InstallWebPI
    -   **Script** -

    ::: {.literalinclude language="posh"}
    InstallWebPI.ps1
    :::

    The above script installs the Microsoft Web Platform Installer
    (WebPI), which is used to download, install, and update components
    of the Microsoft Web Platform, including Internet Information
    Services (IIS), IIS Media Platform technologies, SQL Server Express,
    .NET Framework, and Visual Web Developer.

    -   **Task Name** - InstallNetFeatures
    -   **Script** -

    ::: {.literalinclude language="posh"}
    InstallNetFeatures.ps1
    :::

    The above script installs .NET Framework 4.5 on the VM.

    -   **Task Name** - InstallBugNetApp
    -   **Script** -

    ::: {.literalinclude language="posh"}
    InstallBugNetApp.ps1
    :::

    The above script uses the Application Profile variables you defined
    at the beginning of the exercise to populate the configuration file
    of the Bug Tracker app. It then leverages WebPI to install the
    application from the [Microsoft Web App
    Gallery](https://webgallery.microsoft.com/gallery). With minimal
    changes, you could leverage many popular applications from the
    Gallery, including apps for CMS, eCommerce, Wiki, ticketing, and
    more.

    Once complete, your MSIIS service should look like this:

    ![](images/msiis_package_install.png)

12. Click **Save**.

# Launching the Blueprint

1.  From the upper toolbar in the Blueprint Editor, click **Launch**.

2.  Specify a unique **Application Name** (e.g. *Initials*-BugNET) and
    your **User_initials** Runtime variable value for VM naming.

3.  Click **Create**.

    The **Audit** tab can be used to monitor the deployment of the
    application. The application should take approximately 20 minutes to
    deploy.

4.  Once the Create action completes, and the application is in a
    **Running** state, open the **BugNET** link in a new tab.

    ![](images/bugnet_link.png)

5.  You\'ll be presented with an **Installation Status Report** page.
    Wait for it to report **Installation Complete**, and then click the
    link at the bottom to access the application.

    ![](images/bugnet_setup.png)

    Congratulations! You now have a fully functional bug tracking
    application automatically provisioned leveraging Microsoft SQL
    Server and IIS.

    ![](images/bugnet_app.png)

# (Optional) Scale Out IIS Tier

Leveraging the same approach from the `calm_linux`{.interpreted-text
role="ref"} lab of having multiple web server replicas, can you add a
CentOS based HAProxy service to this blueprint to allow for load
balancing across multiple IIS servers?

# Takeaways

-   Calm provides the same application deployment and lifecycle
    management benefits for Windows workloads as it does for Linux
    workloads.
-   Calm can natively execute remote PowerShell scripts on Windows
    endpoints without the need for a Windows-based proxy.
