# podman/Containerfile
#
# Build a Podman container image from the latest
# stable version of Podman on the Fedoras Updates System.
# https://bodhi.fedoraproject.org/updates/?search=podman
# This image can be used to create a secured container
# that runs safely with privileges within the container.
#
# FLAVOR defaults to stable if unset
#
# FLAVOR=stable    acquires a stable version of Podman
#                   from the Fedoras Updates System.
# FLAVOR=testing   acquires a testing version of Podman
#                   from the Fedoras Updates System.
# FLAVOR=upstream  acquires a testing version of Podman
#                   from the Fedora Copr Buildsystem.
#                   https://copr.fedorainfracloud.org/coprs/rhcontainerbot/podman-next/
#
# https://bodhi.fedoraproject.org/updates/?search=podman

FROM registry.fedoraproject.org/fedora:latest
ARG FLAVOR=stable

# When building for multiple-architectures in parallel using emulation
# it's really easy for one/more dnf processes to timeout or mis-count
# the minimum download rates.  Bump both to be extremely forgiving of
# an overworked host.
RUN echo -e "\n\n# Added during image build" >> /etc/dnf/dnf.conf && \
    echo -e "minrate=100\ntimeout=60\n" >> /etc/dnf/dnf.conf

# Don't include container-selinux and remove
# directories used by dnf that are just taking
# up space.
# TODO: rpm --setcaps... needed due to Fedora (base) image builds
#       being (maybe still?) affected by
#       https://bugzilla.redhat.com/show_bug.cgi?id=1995337#c3
RUN dnf -y makecache && \
    dnf -y update && \
    rpm --setcaps shadow-utils 2>/dev/null && \
    case "${FLAVOR}" in \
      stable) \
        dnf -y install podman fuse-overlayfs openssh-clients wget --exclude container-selinux \
      ;; \
      testing) \
        dnf -y install podman fuse-overlayfs openssh-clients --exclude container-selinux \
            --enablerepo updates-testing \
      ;; \
      upstream) \
        dnf -y install 'dnf-command(copr)' --enablerepo=updates-testing && \
        dnf -y copr enable rhcontainerbot/podman-next && \
        dnf -y install podman fuse-overlayfs openssh-clients \
            --exclude container-selinux \
            --enablerepo=updates-testing \
      ;; \
      *) \
        printf "\\nFLAVOR argument must be set and valid, currently: '${FLAVOR}'\\n\\n" 1>&2 && \
        exit 1 \
      ;; \
    esac && \
    dnf clean all && \
    rm -rf /var/cache /var/log/dnf* /var/log/yum.*

ARG UID=1001

RUN useradd podman -u $UID; \
    echo -e "podman:1000750000:65536" > /etc/subuid; \
    echo -e "podman:1000750000:65536" > /etc/subgid; \
    chmod u-s /usr/bin/new[gu]idmap; \
    setcap cap_setuid+eip /usr/bin/newuidmap; \
    setcap cap_setgid+eip /usr/bin/newgidmap;

ADD https://raw.githubusercontent.com/containers/image_build/main/podman/containers.conf /etc/containers/containers.conf
ADD https://raw.githubusercontent.com/containers/image_build/main/podman/podman-containers.conf /home/podman/.config/containers/containers.conf

RUN mkdir -p /home/podman/.local/share/containers && \
    chown $UID:$UID -R /home/podman && \
    chown $UID:$UID -R /usr/local && \
    chmod 644 /etc/containers/containers.conf

# Copy & modify the defaults to provide reference if runtime changes needed.
# Changes here are required for running with fuse-overlay storage inside container.
RUN sed -e 's|^#mount_program|mount_program|g' \
           -e '/additionalimage.*/a "/var/lib/shared",' \
           -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' \
           /usr/share/containers/storage.conf \
           > /etc/containers/storage.conf

# Setup internal Podman to pass subscriptions down from host to internal container
RUN printf '/run/secrets/etc-pki-entitlement:/run/secrets/etc-pki-entitlement\n/run/secrets/rhsm:/run/secrets/rhsm\n' > /etc/containers/mounts.conf

# Note VOLUME options must always happen after the chown call above
# RUN commands can not modify existing volumes
VOLUME /var/lib/containers
VOLUME /home/podman/.local/share/containers

RUN mkdir -p /var/lib/shared/overlay-images \
             /var/lib/shared/overlay-layers \
             /var/lib/shared/vfs-images \
             /var/lib/shared/vfs-layers && \
    touch /var/lib/shared/overlay-images/images.lock && \
    touch /var/lib/shared/overlay-layers/layers.lock && \
    touch /var/lib/shared/vfs-images/images.lock && \
    touch /var/lib/shared/vfs-layers/layers.lock

ENV _CONTAINERS_USERNS_CONFIGURED="" \
    BUILDAH_ISOLATION=chroot

RUN dnf -y install python3 python3-pip

RUN pip3 install --upgrade pip \
    && python3 -m pip install ansible

USER podman

WORKDIR /home/podman

RUN wget https://github.com/IBM/cpd-cli/releases/download/v13.1.5/cpd-cli-linux-SE-13.1.5.tgz \
    && tar -xzf cpd-cli-linux-SE-13.1.5.tgz \
    && rm cpd-cli-linux-SE-13.1.5.tgz \
    && mv cpd-cli-*/* /usr/local/bin/