# Distributed under the terms of the GNU General Public License v2
# Autogen by MARK Devkit

EAPI=7
ANT="${PN}-${SLOT}"
ANT_SHARE="/usr/share/${ANT}"
inherit java-pkg-2

DESCRIPTION="Project Management and Comprehension Tool for Java"
HOMEPAGE="https://ant.apache.org/"
SRC_URI="https://dlcdn.apache.org/ant/binaries/apache-ant-1.10.17-bin.tar.xz -> apache-ant-1.10.17-bin.tar.xz"
LICENSE="Apache-2.0"
SLOT="1.10"
KEYWORDS="*"
RDEPEND="|| (
	  virtual/jre:11
	  virtual/jre:17
	  virtual/jre:21
	)
	
"
DEPEND="|| (
	  virtual/jdk:11
	  virtual/jdk:17
	  virtual/jdk:21
	)
	app-eselect/eselect-java
	dev-java/java-config
	
"
S="${WORKDIR}/apache-ant-1.10.17"
src_install() {
	dodir "${ANT_SHARE}"
	 cp -Rp bin etc lib manual "${ED}/${ANT_SHARE}" || die "failed to copy"
	 java-pkg_regjar "${ED}/${ANT_SHARE}"/etc/*.jar
	java-pkg_regjar "${ED}/${ANT_SHARE}"/lib/*.jar
	 dodoc NOTICE README WHATSNEW INSTALL CONTRIBUTORS KEYS LICENSE
	 dodir /usr/bin
	dosym "${ANT_SHARE}/bin/ant" /usr/bin/ant-${SLOT}
	dosym /usr/bin/ant-${SLOT} /usr/bin/ant
}


# vim: filetype=ebuild
