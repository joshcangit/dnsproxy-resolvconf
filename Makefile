BINDIR ?= /opt/adguard
CONFDIR ?= /etc/adguard
SYMLINK ?= /usr/local/sbin/dnsp

define setup_files
	@$(1) -m744 dnsproxy-helper.sh $(2)
	@$(1) -m744 dnsproxy-setup.sh $(2)
	@$(1) -m644 dnsproxy.yml $(3)
endef

define service_files
	@$(1)$(2) adguard-dnsproxy-setup.service $(3)
	@$(1)$(2) adguard-dnsproxy-setup.timer $(3)
	@$(1)$(2) adguard-dnsproxy.service $(3)
	@$(1)systemctl daemon-reload
endef

all: install start

install:
ifneq ($(BINDIR), /opt/adguard)
ifeq ($(BINDIR), /usr/sbin)
	$(error "That path is not allowed.")
endif
@$(foreach file,$(wildcard *.sh *.service),sed -i "s|/opt/adguard|$(BINDIR)|g" $(file);)
endif
ifneq ($(CONFDIR), /etc/adguard)
ifeq ($(CONFDIR), /etc)
	$(error "That path is not allowed.")
endif
@$(foreach file,$(wildcard *.sh),sed -i "s|/etc/adguard|$(CONFDIR)|g" $(file);)
endif
ifeq ($(shell id -u), 0)
	@mkdir -p $(BINDIR) $(CONFDIR)
	$(call setup_files,install -p,$(BINDIR),$(CONFDIR))
	$(call service_files,,install -p -m644,/etc/systemd/system)
	@ln -sf $(BINDIR)/dnsproxy $(SYMLINK)
else
	@sudo mkdir -p $(BINDIR) $(CONFDIR)
	$(call setup_files,sudo install -p,$(BINDIR),$(CONFDIR))
	$(call service_files,sudo ,install -p -m644,/etc/systemd/system)
	@sudo ln -sf $(BINDIR)/dnsproxy $(SYMLINK)
endif

start:
ifeq ($(shell id -u), 0)
	@systemctl enable --now adguard-dnsproxy-setup.service
	@systemctl enable --now adguard-dnsproxy-setup.timer
ifneq ($(wildcard $(BINDIR)/dnsproxy),)
	@systemctl enable --now adguard-dnsproxy.service
endif
else
	@sudo systemctl enable --now adguard-dnsproxy-setup.service
	@sudo systemctl enable --now adguard-dnsproxy-setup.timer
ifneq ($(wildcard $(BINDIR)/dnsproxy),)
	@sudo systemctl enable --now adguard-dnsproxy.service
endif
endif

stop:
ifeq ($(shell id -u), 0)
	@systemctl disable --now adguard-dnsproxy-setup.timer
	@systemctl disable adguard-dnsproxy-setup.service
	@systemctl disable --now adguard-dnsproxy.service
else
	@sudo systemctl disable --now adguard-dnsproxy-setup.timer
	@sudo systemctl disable adguard-dnsproxy-setup.service
	@sudo systemctl disable --now adguard-dnsproxy.service
endif

uninstall: stop
ifeq ($(shell id -u), 0)
	@rm -rf $(BINDIR) $(CONFDIR) $(SYMLINK)
	$(call service_files,,rm -f)
else
	@sudo rm -rf $(BINDIR) $(CONFDIR) $(SYMLINK)
	$(call service_files,sudo ,rm -f)
endif

clean:
	@git clean -df
	@git checkout -- .
