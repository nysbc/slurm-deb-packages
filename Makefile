# Variant build pipelines for different distros / Slurm releases
deb11-25.05.2: SLURM_VERSION = 25.05.2
deb11-25.05.2: GIT_BRANCH = slurm-25-05-2-1
deb11-22.05.7-1: SLURM_VERSION = 22.05.7-1
deb11-22.05.7-1: GIT_BRANCH = bullseye-backport
deb11-22.05.7-1: GITHUB_ORG = nysbc
deb11-22.05.7-1: GITHUB_REPO = slurm-22.05-bullseye-backport
deb11: DISTRO_CODENAME =  bullseye
deb11: BASE_IMAGE =  debian:bullseye
deb11: OPENMPI_VERSION = 1.13
deb11: LIBJWT_PKG = libjwt0

deb13-25.05.2: SLURM_VERSION = 25.05.2
deb13-25.05.2: GIT_BRANCH = slurm-25-05-2-1
deb13: DISTRO_CODENAME = trixie
deb13: IMAGE_NAME =  trixie-slurm
deb13: BASE_IMAGE =  debian:trixie
deb13: OPENMPI_VERSION = 1.18
deb13: LIBJWT_PKG = libjwt2

GITHUB_ORG = SchedMD
GITHUB_REPO = slurm
IMAGE_NAME =  $(DISTRO_CODENAME)-slurm
REPO_NAME =  $(DISTRO_CODENAME)-slurm
CONTAINER_NAME=deb-slurm-$(IMAGE_NAME)
APTLY_DIR = /h2/jpellman/slurm-deb-packages/aptly
GPG_KEY = 7E5E28E00C712920
GPG_KEYRING = /h2/jpellman/.gnupg/pubring.kbx
GPG_PASSPHRASE = /h2/jpellman/slurm-deb-packages/aptly-password

.PHONY: deb11-22.05.7-1
deb11-22.05.7-1: deb11

.PHONY: deb11-25.05.2
deb11-25.05.2: deb11

.PHONY: deb13-25.05.2
deb13-25.05.2: deb13

.PHONY: deb11
deb11: pub-deb

.PHONY: deb13
deb13: pub-deb

.PHONY: docker-build
docker-build:
	docker build --build-arg SLURM_VERSION=$(SLURM_VERSION) --build-arg BASE_IMAGE=$(BASE_IMAGE) --build-arg OPENMPI_VERSION=$(OPENMPI_VERSION) --build-arg LIBJWT_PKG=$(LIBJWT_PKG) --build-arg GITHUB_ORG=$(GITHUB_ORG) --build-arg GITHUB_REPO=$(GITHUB_REPO) --build-arg GIT_BRANCH=$(GIT_BRANCH) -t $(IMAGE_NAME):$(SLURM_VERSION) .

.PHONY: mk-deb
mk-deb: docker-build
	mkdir -p slurm_packages_output/$(IMAGE_NAME)-$(SLURM_VERSION)
	if docker ps | fgrep -q $(CONTAINER_NAME); then \
		docker stop $(CONTAINER_NAME); \
		docker rm $(CONTAINER_NAME); \
	fi
	docker create --name $(CONTAINER_NAME) $(IMAGE_NAME):$(SLURM_VERSION) 
	docker start $(CONTAINER_NAME)
	docker cp $(CONTAINER_NAME):/usr/src/debs/. ./slurm_packages_output/$(IMAGE_NAME)-$(SLURM_VERSION)
	docker stop $(CONTAINER_NAME)
	docker rm $(CONTAINER_NAME)

.PHONY: init-apt
init-apt:
	if [ ! -f $(APTLY_DIR)/public/$(DISTRO_CODENAME)/dists/$(DISTRO_CODENAME)/main/binary-amd64/Release ]; then \
		aptly repo create -config=aptly.conf -architectures=amd64  -distribution="$(DISTRO_CODENAME)" -component="main"  "$(REPO_NAME)"; \
		aptly publish repo -config=aptly.conf -keyring=$(GPG_KEYRING) -gpg-key=$(GPG_KEY) -passphrase-file=$(GPG_PASSPHRASE) -architectures=amd64 -distribution="$(DISTRO_CODENAME)" -component="main" "$(REPO_NAME)" $(DISTRO_CODENAME); \
	fi

.PHONY: pub-deb
pub-deb: init-apt mk-deb
	aptly repo add -config=aptly.conf  "$(DISTRO_CODENAME)-slurm" ./slurm_packages_output/$(IMAGE_NAME)-$(SLURM_VERSION)/*.deb
	aptly publish update -config=aptly.conf -keyring=$(GPG_KEYRING) -gpg-key=$(GPG_KEY) -passphrase-file=$(GPG_PASSPHRASE) $(DISTRO_CODENAME) $(DISTRO_CODENAME)

.PHONY: clean
clean:
	if [ -d slurm_packages_output ]; then \
		rm -rf slurm_packages_output; \
	fi
