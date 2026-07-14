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

8.	Application Layer (WordPress & PHP-FPM)
	The WordPress container acts as the application server. It does not run a traditional web server like Apache; instead, it utilizes PHP-FPM (FastCGI Process Manager) coupled with Alpine Linux.

	Automated Installation (WP-CLI): To adhere to the requirement that the infrastructure must configure itself without manual browser intervention, the container downloads and executes wp-cli. This command-line utility handles downloading the WordPress core, injecting database credentials into wp-config.php, and creating both the administrator and standard user accounts defined in the .env file.

	Memory Management Fix: By default, PHP limits script memory allocation to 128MB. Because extracting modern WordPress core files via WP-CLI exceeds this, a custom .ini configuration is injected during the Docker build (memory_limit = 256M) to prevent out-of-memory fatal errors during initialization.

	Startup Synchronization: The WordPress container utilizes Docker Compose's depends_on: service_healthy directive. It will not execute its initialization script until the MariaDB container passes its UNIX socket ping test. This prevents race conditions where WordPress attempts to populate a database that has not finished booting.

	Process Management (PID 1): After installation, the script uses the exec command to replace the bash shell with php-fpm83 -F (running in the foreground). This promotes PHP-FPM to PID 1, allowing it to correctly receive termination signals from the Docker daemon.

	UID/GID Mapping Note: Files generated in the /var/www/html volume are owned by the nobody user (the default unprivileged user for PHP-FPM in Alpine). Similar to the MariaDB host volume mapping (where the host may display ownership as klogd due to UID 101/103 discrepancies), this is expected behavior based on how Alpine maps internal container UIDs to the host system.

	Infrastructure Management & Debugging
	Because the containers run in detached mode, verifying the internal state or diagnosing startup failures requires checking the Docker daemon logs.

	Standard Logging Commands:
	Must be executed from the directory containing docker-compose.yml (e.g., ~/inceptionWork/srcs).

	View logs for the entire stack:
	Bash
	docker compose logs

	View logs for a specific container:
	docker compose logs <service_name> 


	### Web Server Layer (NGINX)
	The NGINX container serves as the sole entry point to the infrastructure, strictly adhering to the HTTPS requirement on port 443. 

	* **TLS/SSL Security:** A self-signed X.509 certificate and RSA key are dynamically generated via `openssl` during the container's initialization. The server block strictly enforces `TLSv1.2` and `TLSv1.3` protocols, rejecting older vulnerable standards.
	* **FastCGI Proxying:** NGINX does not execute PHP directly. It utilizes FastCGI parameters (`$fastcgi_script_name`) to construct absolute paths, passing execution requests across the Docker network to the WordPress container on port 9000.
	* **Process Management:** To maintain PID 1 status and prevent immediate container exit, the initialization script executes NGINX using the `daemon off;` directive, shifting it from a background process to the foreground.

	## Alpine VM: Minimal GUI and Browser Installation

	To test the web application locally within the Alpine VM and bypass host network restrictions, install a lightweight XFCE desktop environment and Firefox.

	### 1. Install Base X.Org Server
	Install the minimal required X11 packages.
	```bash
	sudo setup-xorg-base

	2. Install XFCE, DBus, and Firefox
	Install the desktop environment, terminal emulator, system message bus, and browser.

	Bash
	sudo apk add xfce4 xfce4-terminal firefox dbus font-terminus
	3. Enable and Start DBus
	Add the DBus service to the default runlevel and start it.

	Bash
	sudo rc-update add dbus default
	sudo service dbus start
	4. Configure the X Session
	Configure the X server to launch XFCE on startup.

	Bash
	echo "exec startxfce4" > ~/.xinitrc
	5. Launch the GUI
	Initialize the desktop environment.

	Bash
	startx

	You must map the domain to your localhost IP address in the VM's /etc/hosts file with command:
	echo "127.0.0.1 mhirvasm.42.fr" | sudo tee -a /etc/hosts