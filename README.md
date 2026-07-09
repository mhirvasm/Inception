*This project has been created as part
of the 42 curriculum by <mhirvasm>*

Description

Instructions

Resources

(Virtual Machines vs Docker, Secrets vs environment variables, docker network vs host network, docker volumes vs bind mounts)

### Operating System
The infrastructure runs on **Alpine Linux (virt edition)**. 

* **Why Alpine?** It is built around `musl libc` and `busybox`, making it significantly smaller and more secure than traditional glibc-based distributions.
* **Why the 'virt' edition?** The `virt` ISO is heavily stripped down. It omits all hardware drivers, firmware, and kernel modules required for bare-metal installations (like Wi-Fi or physical GPUs). This ensures the OS idles at an absolute minimum RAM footprint, perfectly fitting the strict 1 CPU / 2048 MB memory constraints of this project.

### Core Utilities
Instead of installing heavy GNU utilities, the system relies on **BusyBox**. 

BusyBox combines tiny versions of many common UNIX utilities into a single small executable. During the OS setup, BusyBox was specifically selected to handle NTP (Network Time Protocol) for clock synchronization. This avoids the overhead of running a full standalone daemon like `chronyd` or `ntpd`, while keeping the system clock accurate—which is a strict requirement for validating the SSL/TLS certificates used by NGINX later in the stack.

### Automated Provisioning (`setup.sh`)
Because campus workstations utilize volatile local storage (`/goinfre`) to bypass network profile quotas, the virtual machine environment is treated as ephemeral. It will be wiped periodically.

To adhere to "Infrastructure as Code" principles, the base OS configuration is fully automated via `setup.sh`. 

**How to provision a fresh VM:**
Since copy-paste is disabled in the bare-metal VirtualBox console, the provisioning script is pulled directly from the Git repository using `wget` and executed as root:

1.  Log into the fresh Alpine VM as `root`.
2.  Execute:
    ```sh
    wget [https://raw.githubusercontent.com/](https://raw.githubusercontent.com/)<login>/<repo>/main/setup.sh
    chmod +x setup.sh
    ./setup.sh <login>
    ```
3.  The script automatically:
    * Enables the Alpine community repositories.
    * Installs dependencies (`docker`, `docker-cli-compose`, `sudo`, `openssh`).
    * Creates the non-root user and assigns `wheel` and `docker` permissions.
    * Configures the SSH daemon to listen on port 4241 and denies root login.
    * Registers Docker and SSH to start on boot.
4.  Once complete, abandon the VM console and manage the system remotely via SSH from the host machine.