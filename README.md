**This project has been created as part of the 42 curriculum by mturgeon**

# Description

This project uses Docker container, managed through Docker Compose, to deploy a multi-service application. 

# Instructions

Please refer to DEV_DOC.md and USER_DOC.md in the /docs directory for utilisation.

# Project description

The app consists of the following services:

### NGINX instance

The HTTPS entrypoint that allows access to both a Wordpress website and a static blog holding my resume. Traffic is only allowed through port 443 using HTTPS.

### Wordpress instance

The Wordpress service runs the PHP FastCGI Process Manager to generate the content of the Wordress website.

### MariaDB instance

This service holds all the data the Wordpress service needs to fetch to generate the web pages (users, pages, comments, etc)

### Redis cache

A caching service is implemented between the database and the Wordpress service. It allows the most common DB queries to be stored in memory to speed up the generation of the most common assets.

### Adminer panel

Use mturgeon.42.fr/adminer.php to manage your database through a clean GUI instead of the command line interface in the docker container.

### Mariadb Backup service

This will backup the DB according to the following policy:
- At container build, a full backup is made.
- Everyday at 2am, an incremental backup is made (modifying the content of the full backup copy with what has changed since)
The backup can be found in the "mariadb-backup-volume" backup volume.

**Containerization** allows services to run isolated in minimum environments, reducing attack surfaces and easing deployment accross different machines.

# VMs vs Docker

Below are the notes I took during my research:

## Containerization vs. full Virtualization

less overhead on containers because no need to emulate the system calls ! Also, way less dependent on hardware compatibility

VMs emulate the hardware. Containers use the same hardware and same kernel as the Host (no hypervisor in between) but the rest is custom. limitations:

- isolation not as strong as full VM
- containers you run should be compatible with the kernel (no Windows container on Unix systems)

## Application-level containers vs OS-level containers

Docker is an application-level container.

### OS containers

Virtual environments that share the host’s kernel but provide user space isolation —> like VMs but shared hardware. Things running in the container can only see what’s inside the container. Designed to run **multiple processes and applications.**

ex: LXC, OpenVZ, BSD jails, Solaris zones

### Application containers

A container is a unit of software that holds together all the components and functionalities needed for an application to run.

Containers are short lived, lightweight, and frequently rebuilt from version-controlled sources.

Main idea: create different containers for each component of your application (microservices).

Designed to package and run single services. Still share same kernel as host. Notion of layers where each “thing” you add is a layer that is combined by Docker at runtime to reduce duplication. You can roll back to previous layers if something fails on the deeper one. Start with base image common to all components and specify stuff for each one.

ex: Docker, Rocket

![os-vs-app-containers.jpeg](attachment:aeaaa9c1-7a9a-465a-9e7f-e874e6e8ee45:os-vs-app-containers.jpeg)

integration technologies like Apache Kafta help with data and apps management to scale data streaming.

# Secrets vs Environment variables

Secrets are volumes automatically managed and mounted by the Docker Daemon, delegating their isolation and security to the Docker app, who is usually much better than you at this. It's also useful to integrate with secrets manager for more professional projects.
Environment variables are automatically loaded as envvars to the PID 1 process of the container. They are much less secure as an attacker that takes control of a container has access to them all.

# Docker networks vs Host Network

Docker Networks are isolated networks from the Host network by a driver (bridge by default) that emulates a host network on which only the containers attached are visible. You have to map it manually to the host network for it to be an interface. See notes below:

## Docker Network

when starting a container, it is by default connected to the default docker network bridge. Containers connected to the default bridge have access to all network interfaces of the host by default. Through “masquerading” they access the internet without further configuration. In this configuration, they access other containers by their IP addresses.

### User defined networks

Containers in the same network can communicate to each other using their names or IP addresses. There are a bunch of [network drivers](https://docs.docker.com/engine/network/) that do a bunch of special things. The default one on Linux is bridge.

Containers can be connected to multiple networks, e.g. internal bridge network for other services and external ipvlan for internet access. Use gw-priority to better define default gateways on containers. Connect w/ multiple —network flags or with docker network connect on already running containers.

# Docker Volumes vs Bind Mounts

Volumes are handled by docker and shadow the content of the directory at build time while mounts are a direct link with the host mountpoint which increases attack surface. See notes:

## Volume vs bind mounts

-v (—volume) and —mount lets the user share files between host and container. for volumes, see above. Mount doesn’t create a directory automatically but offers more granular control (readonly, mount type, etc). Docker recommends mounting over volumes for sharing files with the host.

be sure to grant proper permissions wiht :ro, :rw, etc /host/path:rw

In large codebases, bind mounts might become slow —> [synchronized file share](https://docs.docker.com/desktop/features/synchronized-file-sharing/)

# Ressources

As always, Wikipedia is my first entrypoint on any subject. Claude was used for very precise questions sometimes and for explaining the differences between CSR SSR and SSG when it comes to web page rendering.
- https://www.cloudflare.com/learning/ssl/what-is-an-ssl-certificate about SSL certificate

- https://developers.cloudflare.com/reference-architecture/diagrams/serverless/fullstack-application/ Good stuff about full stack web app design

- https://martinfowler.com/eaaCatalog All the SSGs available

- https://docs.docker.com/get-started Docker tutorial

- https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-docker NGINX install

- https://www.dash0.com/guides/docker-health-check-a-practical-guide  Intro to healthchecks

- https://stackoverflow.com/questions/50734271/how-to-define-build-args-in-docker-compose  Docker build args (not used)

- https://docs.docker.com/engine/swarm/secrets Docker doc on secrets

- https://www.figma.com/resource-library/static-vs-dynamic-website/ Static vs dynamic website overview

- https://dev.to/ashenmaster/static-vs-dynamic-sites-61f Static vs dynamic website overview again

- https://en.wikipedia.org/wiki/Static_site_generator SSG wiki

- https://en.wikipedia.org/wiki/Content_delivery_network CDN wiki

- https://en.wikipedia.org/wiki/Single-page_application SPA wiki

- https://medium.com/@rushi-patel/server-side-rendering-ssr-and-static-site-generation-ssg-in-react-a-deep-dive-b55cc2ef30a4 Deep dive about SSR vs SSG for react devs

- https://about.gitlab.com/blog/comparing-static-site-generators/ How to choose your SSG

- https://jamstack.org/generators/ about SSGs

- https://www.getzola.org/documentation/getting-started/overview/ Zola doc

- https://github.com/aaranxu/tale-zola/blob/main/config.toml Zola config file

- https://docs.docker.com/compose Docker compose doc

- https://wiki.alpinelinux.org/wiki/MariaD mariadb doc for aline