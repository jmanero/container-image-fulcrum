ARG VERSION="2.1.0"

FROM docker.io/library/fedora:latest AS fetch
ARG VERSION

RUN dnf install -y bzip2-libs gpg

## Handle mismatched architecture identifiers
RUN case $(arch) in\
  aarch64) curl -LO --fail https://github.com/cculianu/Fulcrum/releases/download/v${VERSION}/Fulcrum-${VERSION}-arm64-linux.tar.gz   ;;\
  *)       curl -LO --fail https://github.com/cculianu/Fulcrum/releases/download/v${VERSION}/Fulcrum-${VERSION}-$(arch)-linux.tar.gz ;;\
esac

ADD https://github.com/cculianu/Fulcrum/releases/download/v${VERSION}/Fulcrum-${VERSION}-shasums.txt SHA256SUMS
ADD https://github.com/cculianu/Fulcrum/releases/download/v${VERSION}/Fulcrum-${VERSION}-shasums.txt.asc SHA256SUMS.asc
ADD https://raw.githubusercontent.com/Electron-Cash/keys-n-hashes/master/pubkeys/calinkey.txt .

RUN gpg --import ./calinkey.txt && gpgconf --kill all
RUN gpg --verify SHA256SUMS.asc SHA256SUMS && gpgconf --kill all
# RUN sha256sum --ignore-missing --check SHA256SUMS

## Build a skelton for the scratch output image
RUN mkdir -p /build/etc /build/usr/bin /build/usr/lib /build/usr/lib64
RUN ln -s /usr/bin /build/bin
RUN ln -s /usr/lib /build/lib
RUN ln -s /usr/lib64 /build/lib64

RUN case $(arch) in\
  aarch64) tar -xzf Fulcrum-${VERSION}-arm64-linux.tar.gz   --strip-components 1 ;;\
  *)       tar -xzf Fulcrum-${VERSION}-$(arch)-linux.tar.gz --strip-components 1 ;;\
esac

## Add fulcrum binaries to output image
RUN cp -av Fulcrum /build/usr/bin/fulcrum
# RUN cp -av FulcrumAdmin /build/usr/bin/fulcrum-admin ## This is a python script, which won't work in the scratch image

## Add the dynamic loader and library dependencies to the image
## ldd build/usr/bin/fulcrum
	# linux-vdso.so.1 (0x00007ffd82ff3000)
	# libbz2.so.1.0 => not found
	# libz.so.1 => /lib64/libz.so.1 (0x000070d607c24000)
	# libdl.so.2 => /lib64/libdl.so.2 (0x000070d607c20000)
	# librt.so.1 => /lib64/librt.so.1 (0x000070d607c1c000)
	# libpthread.so.0 => /lib64/libpthread.so.0 (0x000070d607c16000)
	# libm.so.6 => /lib64/libm.so.6 (0x000070d607b28000)
	# libgcc_s.so.1 => /lib64/libgcc_s.so.1 (0x000070d607afc000)
	# libc.so.6 => /lib64/libc.so.6 (0x000070d60580e000)
	# /lib64/ld-linux-x86-64.so.2 (0x000070d607c4b000)
RUN cp -aLv /usr/lib64/libz.so.1 /usr/lib64/libdl.so.2 /lib64/librt.so.1 /usr/lib64/libpthread.so.0 /usr/lib64/libm.so.6 /usr/lib64/libgcc_s.so.1 /usr/lib64/libc.so.6 /build/usr/lib64
RUN cp -aLv /usr/lib64/libbz2.so.1 /build/usr/lib64/libbz2.so.1.0

## Location of the dynamic loader varies across architectures.
RUN cp /usr/lib64/ld-linux* /build/usr/lib64 && ln -s /usr/lib64/ld-linux-* build/usr/bin/ld.so || true
RUN cp /usr/lib/ld-linux* /build/usr/lib && ln -s /usr/lib/ld-linux-* build/usr/bin/ld.so || true
RUN [ -f /build/usr/bin/ld.so ] || (echo "Unable to find a dynamic loader library in /usr/lib or /usr/lib64" && exit 1)

RUN cp -av /etc/ld.so.* /build/etc

FROM scratch

COPY --from=fetch /build /
COPY fulcrum-banner.txt /etc
ENV LANG=C.UTF-8

ENV datadir=/data
ENV tcp=0.0.0.0:50001
ENV ws=0.0.0.0:50003
ENV admin=0.0.0.0:58000
ENV stats=0.0.0.0:58080

ENV rpcuser=bitcoin
ENV rpcpassword=bitcoin

## Disable peering
ENV hostname=nothing
ENV peering=false
ENV announce=false

ENV donation=nothing
ENV banner=/etc/fulcrum-banner.txt

ENTRYPOINT [ "/usr/bin/fulcrum" ]
CMD [ "_ENV_" ]
