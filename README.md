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
	*	*ssh -p 4241 (login name)127.0.0.1

5.	### Orchestration & Persistent Data (`Makefile`)
	Docker containers are ephemeral. To satisfy the requirement that data must persist if a container crashes or is restarted, the infrastructure utilizes local bind mounts. 
	* The `Makefile` acts as the primary orchestrator. Before executing `docker compose up`, it automatically provisions the necessary host directories (`/home/<login>/data/mariadb` and `/home/<login>/data/wordpress`) on the Alpine virtual machine.
	* This guarantees the directories exist before Docker attempts to mount them, preventing runtime crash loops.

6.	### Secrets Management
	Passwords and credentials are never hardcoded into `docker-compose.yml` or Dockerfiles, as this violates strict security protocols.
	* A local host script (`configure-env.sh`) generates cryptographically secure, alphanumeric passwords using `openssl` (or `sha256sum` as a fallback).
	* This script dynamically writes the `srcs/.env` file required by Docker Compose and isolates evaluation credentials in a local `secrets/` directory. Both are excluded from version control via `.gitignore`.

7.	### Database Architecture (MariaDB)
	The MariaDB container is built from `alpine:3.20`. 
	* **Networking:** The default `mariadb-server.cnf` configuration is overridden to bind the daemon to `0.0.0.0` instead of `127.0.0.1`, allowing incoming connections from the WordPress container across the isolated Docker network.
	* **Process Management (PID 1):** The container strictly adheres to the PID 1 requirement. It avoids anti-patterns like `tail -f`. The custom `init.sh` entrypoint script configures the database and then uses the `exec` command to hand over process control entirely to the `mysqld` daemon. This ensures the database can cleanly intercept `SIGTERM` signals for graceful shutdowns without data corruption.	

	KEEP ON EYE ON THIS: 
	(
		Your database files are owned by klogd (a system user), not the mysql user. In some Alpine environments, the mysql user ID (UID) and Group ID (GID) are 101, whereas klogd might be 103 or similar.

		While it is currently "working," if you run into permission errors later, it is because your container's internal mysql user doesn't match the ownership of the files on the host. We will keep an eye on this.
	)