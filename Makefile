COREOS_CHANNEL = stable
COREOS_VERSION = 1000.0.0
COREOS_MD5_CHECKSUM = 2207f09699ee37e79c32aae972432059
OPENNEBULA_DATASTORE = default

PACKER_IMAGE_DIR = builds/coreos-$(COREOS_CHANNEL)-$(COREOS_VERSION)-qemu
PACKER_IMAGE_NAME = coreos-$(COREOS_CHANNEL)-$(COREOS_VERSION)
PACKER_IMAGE = $(PACKER_IMAGE_DIR)/$(PACKER_IMAGE_NAME)
PACKER_IMAGE_BZ2 = $(PACKER_IMAGE).bz2
PACKER_IMAGE_COMPRESSION = false
PACKER_IMAGE_DEPS = \
	coreos.json \
	packer.sh \
	files/install.yml \
	oem/coreos-setup-environment \
	oem/opennebula-cloudinit \
	oem/opennebula-common \
	oem/opennebula-hostname \
	oem/opennebula-network \
	oem/opennebula-ssh-key \
	scripts/cleanup.sh \
	scripts/oem.sh

all: $(PACKER_IMAGE)

$(PACKER_IMAGE): $(PACKER_IMAGE_DEPS)
	rm -rf $(PACKER_IMAGE_DIR)
	env \
	  COREOS_CHANNEL=$(COREOS_CHANNEL) \
	  COREOS_VERSION=$(COREOS_VERSION) \
	  COREOS_MD5_CHECKSUM=$(COREOS_MD5_CHECKSUM) \
	  PACKER_LOG=1 \
	    ./packer.sh validate coreos.json
	env \
	  COREOS_CHANNEL=$(COREOS_CHANNEL) \
	  COREOS_VERSION=$(COREOS_VERSION) \
	  COREOS_MD5_CHECKSUM=$(COREOS_MD5_CHECKSUM) \
	  PACKER_LOG=1 \
	    ./packer.sh build coreos.json
	mv $(PACKER_IMAGE_DIR)/packer-qemu $(PACKER_IMAGE)
ifeq ($(PACKER_IMAGE_COMPRESSION), true)
	bzip2 -9vk $(PACKER_IMAGE)
endif
	echo "Image file $(PACKER_IMAGE) ready"

.PHONY: latest appliance register clean

latest: COREOS_VERSION = $(shell curl https://$(COREOS_CHANNEL).release.core-os.net/amd64-usr/current/version.txt -s|grep -i '^COREOS_VERSION_ID='|cut -d= -f2-)
latest: COREOS_MD5_CHECKSUM = $(shell curl -X HEAD -I -s -D - https://$(COREOS_CHANNEL).release.core-os.net/amd64-usr/current/coreos_production_iso_image.iso -o /dev/null|grep -i '^ETAg: '|cut -d: -f2-|tr -d ' "')

latest: $(PACKER_IMAGE)

OPENNEBULA_IMAGE = coreos-$(COREOS_CHANNEL)

clean:
	rm -rf builds
