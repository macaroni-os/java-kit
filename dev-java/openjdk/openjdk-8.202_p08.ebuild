# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit check-reqs eapi7-ver flag-o-matic java-pkg-2 java-vm-2 multiprocessing pax-utils toolchain-funcs

MY_PV=$(ver_rs 1 'u' 2 '-' ${PV//p/b})

BASE_URI="https://hg.${PN}.java.net/jdk8u/jdk8u"

DESCRIPTION="Open source implementation of the Java programming language"
HOMEPAGE="https://openjdk.java.net"
SRC_URI="
	${BASE_URI}/archive/jdk${MY_PV}.tar.bz2 -> ${P}.tar.bz2
	${BASE_URI}/corba/archive/jdk${MY_PV}.tar.bz2 -> ${PN}-corba-${PV}.tar.bz2
	${BASE_URI}/hotspot/archive/jdk${MY_PV}.tar.bz2 -> ${PN}-hotspot-${PV}.tar.bz2
	${BASE_URI}/jaxp/archive/jdk${MY_PV}.tar.bz2 -> ${PN}-jaxp-${PV}.tar.bz2
	${BASE_URI}/jaxws/archive/jdk${MY_PV}.tar.bz2 -> ${PN}-jaxws-${PV}.tar.bz2
	${BASE_URI}/jdk/archive/jdk${MY_PV}.tar.bz2 -> ${PN}-jdk-${PV}.tar.bz2
	${BASE_URI}/langtools/archive/jdk${MY_PV}.tar.bz2 -> ${PN}-langtools-${PV}.tar.bz2
	${BASE_URI}/nashorn/archive/jdk${MY_PV}.tar.bz2 -> ${PN}-nashorn-${PV}.tar.bz2
"

LICENSE="GPL-2"
SLOT="$(ver_cut 1)"
KEYWORDS="~amd64 ~arm64 ~ppc64 ~x86"
IUSE="alsa debug cups doc examples gentoo-vm headless-awt +jbootstrap nsplugin +pch selinux source +webstart"

CDEPEND="
	media-libs/freetype:2=
	sys-libs/zlib
	alsa? ( media-libs/alsa-lib )
	!headless-awt? (
		media-libs/giflib:0/7
		x11-libs/libX11
		x11-libs/libXext
		x11-libs/libXi
		x11-libs/libXrender
		x11-libs/libXt
		x11-libs/libXtst
	)
"

RDEPEND="
	${CDEPEND}
	cups? ( net-print/cups )
	selinux? ( sec-policy/selinux-java )
"

# cups headers requied to build, runtime dep is optional
DEPEND="
	${CDEPEND}
	net-print/cups
	app-arch/zip
	app-misc/ca-certificates
	dev-lang/perl
	dev-libs/openssl:0
	media-libs/alsa-lib
	!headless-awt? (
		x11-base/xorg-proto
	)
	|| (
		dev-java/openjdk-bin:${SLOT}
		dev-java/icedtea-bin:${SLOT}
		dev-java/openjdk:${SLOT}
		dev-java/icedtea:${SLOT}
	)
"

PDEPEND="webstart? ( >=dev-java/icedtea-web-1.6.1:0 )
	nsplugin? ( >=dev-java/icedtea-web-1.6.1:0[nsplugin] )"

S="${WORKDIR}/jdk${SLOT}u-jdk${MY_PV}"

# The space required to build varies wildly depending on USE flags,
# ranging from 2GB to 16GB. This function is certainly not exact but
# should be close enough to be useful.
openjdk_check_requirements() {
	local M
	M=2048
	M=$(( $(usex debug 3 1) * $M ))
	M=$(( $(usex jbootstrap 2 1) * $M ))
	M=$(( $(usex doc 320 0) + $(usex source 128 0) + 192 + $M ))

	CHECKREQS_DISK_BUILD=${M}M check-reqs_pkg_${EBUILD_PHASE}
}

pkg_pretend() {
	openjdk_check_requirements
	has ccache ${FEATURES} && die "FEATURES=ccache doesn't work with ${PN}"
}

pkg_setup() {
	openjdk_check_requirements
	java-vm-2_pkg_setup

	JAVA_PKG_WANT_BUILD_VM="openjdk-${SLOT} openjdk-bin-${SLOT} icedtea-${SLOT} icedtea-bin-${SLOT}"
	JAVA_PKG_WANT_SOURCE="${SLOT}"
	JAVA_PKG_WANT_TARGET="${SLOT}"

	# The nastiness below is necessary while the gentoo-vm USE flag is
	# masked. First we call java-pkg-2_pkg_setup if it looks like the
	# flag was unmasked against one of the possible build VMs. If not,
	# we try finding one of them in their expected locations. This would
	# have been slightly less messy if openjdk-bin had been installed to
	# /opt/${PN}-${SLOT} or if there was a mechanism to install a VM env
	# file but disable it so that it would not normally be selectable.

	local vm
	for vm in ${JAVA_PKG_WANT_BUILD_VM}; do
		if [[ -d ${EPREFIX}/usr/lib/jvm/${vm} ]]; then
			java-pkg-2_pkg_setup
			return
		fi
	done

	if has_version --host-root dev-java/openjdk:${SLOT}; then
		export JDK_HOME=${EPREFIX}/usr/$(get_libdir)/openjdk-${SLOT}
	else
		JDK_HOME=$(best_version --host-root dev-java/openjdk-bin:${SLOT})
		[[ -n ${JDK_HOME} ]] || die "Build VM not found!"
		JDK_HOME=${JDK_HOME#*/}
		JDK_HOME=${EPREFIX}/opt/${JDK_HOME%-r*}
		export JDK_HOME
	fi
}

src_prepare() {
	default
	chmod +x configure || die
	local repo
	for repo in corba hotspot jdk jaxp jaxws langtools nashorn; do
		ln -s ../"${repo}-jdk${MY_PV}" "${repo}" || die
	done

	# linux 5 is ok https://bugs.gentoo.org/679506
	sed -i '/^SUPPORTED_OS_VERSION/ s/ 4%/ 4% 5%/' hotspot/make/linux/Makefile || die
}

src_configure() {
	# general build info found here:
	#https://hg.openjdk.java.net/jdk8/jdk8/raw-file/tip/README-builds.html

	# Work around stack alignment issue, bug #647954.
	use x86 && append-flags -mincoming-stack-boundary=2

	append-flags -Wno-error

	local myconf=(
			--disable-ccache
			--enable-unlimited-crypto
			--with-boot-jdk="${JDK_HOME}"
			--with-extra-cflags="${CFLAGS}"
			--with-extra-cxxflags="${CXXFLAGS}"
			--with-extra-ldflags="${LDFLAGS}"
			--with-giflib=system
			--with-jtreg=no
			--with-jobs=1
			--with-num-cores=1
			--with-update-version="$(ver_cut 2)"
			--with-build-number="$(ver_cut 4)"
			--with-milestone="gentoo"
			--with-zlib=system
			--with-native-debug-symbols=$(usex debug internal none)
			$(usex headless-awt --disable-headful '')
		)

	# PaX breaks pch, bug #601016
	if use pch && ! host-is-pax; then
		myconf+=( --enable-precompiled-headers )
	else
		myconf+=( --disable-precompiled-headers )
	fi

	(
		unset _JAVA_OPTIONS JAVA JAVAC XARGS
		CFLAGS= CXXFLAGS= LDFLAGS= \
		CONFIG_SITE=/dev/null \
		econf "${myconf[@]}"
	)
}

src_compile() {
	emake -j1 LOG=debug JOBS=$(makeopts_jobs)\
		$(usex jbootstrap bootcycle-images images) $(usex doc docs '')
}

src_install() {
	local dest="/usr/$(get_libdir)/${PN}-${SLOT}"
	local ddest="${ED}${dest#/}"

	cd "${S}"/build/*-release/images/j2sdk-image || die

	if ! use alsa; then
		rm -v jre/lib/$(get_system_arch)/libjsoundalsa.* || die
	fi

	if ! use examples ; then
		rm -vr demo/ || die
	fi

	if ! use source ; then
		rm -v src.zip || die
	fi

	dodir "${dest}"
	cp -pPR * "${ddest}" || die

	einfo "Generating cacerts file from certificates in ${EPREFIX}/usr/share/ca-certificates/"
	mkdir "${T}/certgen" && cd "${T}/certgen" || die
	cp "${FILESDIR}/generate-cacerts.pl" . && chmod +x generate-cacerts.pl || die
	for c in "${EPREFIX}"/usr/share/ca-certificates/*/*.crt; do
		openssl x509 -text -in "${c}" >> all.crt || die
	done
	./generate-cacerts.pl "${ddest}/bin/keytool" all.crt || die
	cp -vRP cacerts "${ddest}/jre/lib/security/" || die
	chmod 644 "${ddest}/jre/lib/security/cacerts" || die

	use gentoo-vm && java-vm_install-env "${FILESDIR}"/${PN}-${SLOT}.env.sh
	java-vm_set-pax-markings "${ddest}"
	java-vm_revdep-mask
	java-vm_sandbox-predict /dev/random /proc/self/coredump_filter

	if use doc ; then
		insinto /usr/share/doc/${PF}/html
		doins -r "${S}"/build/*-release/docs/*
	fi
}

pkg_postinst() {
	java-vm-2_pkg_postinst

	if use gentoo-vm ; then
		ewarn "WARNING! You have enabled the gentoo-vm USE flag, making this JDK"
		ewarn "recognised by the system. This will almost certainly break things."
	else
		ewarn "The experimental gentoo-vm USE flag has not been enabled so this JDK"
		ewarn "will not be recognised by the system. For example, simply calling"
		ewarn "\"java\" will launch a different JVM. This is necessary until Gentoo"
		ewarn "fully supports Java ${SLOT}. This JDK must therefore be invoked using its"
		ewarn "absolute location under ${EPREFIX}/usr/$(get_libdir)/${PN}-${SLOT}."
	fi
}
