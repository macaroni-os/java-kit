# Distributed under the terms of the GNU General Public License v2
# Autogen by MARK Devkit

EAPI=7

DESCRIPTION="Virtual for Java Development Kit (JDK)"
SLOT="25"
KEYWORDS="*"
IUSE="headless-awt"
RDEPEND="|| (
	  dev-java/oracle-jdk-bin:${SLOT}[gentoo-vm(+),headless-awt=]
	  dev-java/openjdk-bin:${SLOT}[gentoo-vm(+),headless-awt=]
	  dev-java/openjdk:${SLOT}[gentoo-vm(+),headless-awt=]
	)
	
"

# vim: filetype=ebuild
