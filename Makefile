SLURM_VERSION:=25.05.2

# Variant build pipelines for different distros
deb11: IMAGE_NAME =  bullseye-slurm
deb11: BASE_IMAGE =  debian:bullseye
deb11: OPENMPI_VERSION = 1.13
deb11: LIBJWT_PKG = libjwt0

deb13: IMAGE_NAME =  trixie-slurm
deb13: BASE_IMAGE =  debian:trixie
deb13: OPENMPI_VERSION = 1.18
deb13: LIBJWT_PKG = libjwt2

CONTAINER_NAME=deb-slurm-$(IMAGE_NAME)


.PHONY: deb11
deb11: mk-deb

.PHONY: deb13
deb13: mk-deb

.PHONY: docker-build
docker-build:
	docker build --build-arg SLURM_VERSION=$(SLURM_VERSION) --build-arg BASE_IMAGE=$(BASE_IMAGE) --build-arg OPENMPI_VERSION=$(OPENMPI_VERSION) --build-arg LIBJWT_PKG=$(LIBJWT_PKG) -t $(IMAGE_NAME):$(SLURM_VERSION) .

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

.PHONY: clean
clean:
	if [ -d slurm_packages_output ]; then \
		rm -rf slurm_packages_output; \
	fi
