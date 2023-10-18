#!/bin/sh

case ${0##*/} in build.sh)
	set -eu
	cd "${0%/*}" || exit
	[ -w . ] || {
		printf %s\\n "no write permissions for PWD"
		exit 3
	}
esac




{
	_reponame=arg
	_ghUrl=https://github.com/denisde4ev/$_reponame
	_ghstats=$(curl -s "https://api.github.com/repos/denisde4ev/$_reponame/commits/master")
	#_commit_date=$(printf %s\\n "$_ghstats" | jq -r '.commit.committer.date[0:10]')
	_commit_date=$(printf %s\\n "$_ghstats" | jq -r '(.commit.committer.date | strptime("%Y-%m-%dT%H:%M:%SZ") | strftime("%Y_%m_%d"))')
	_commit_sha=$(printf %s\\n "$_ghstats" | jq -r '.sha[0:8]')
}

{ # PKGBUILD vars/fns
	# TODO: check this with (Alpine, Ubunto AUR, search for other) build system

	pkgname=denisde4ev-arg-clang-git
	pkgver=${_commit_date}.${_commit_sha}
	case $pkgver in 20[0-9][0-9]_[0-9][0-9]_[0-9][0-9].[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]) ;; *)
		printf %s\\n >&2 "bad pkgver=$pkgver"
		exit 3
	esac
	pkgrel=1

	pkgdesc=$(printf %s \
		"arg output: (count of args):(len of args) (...quoted arguments)" \
		"; " \
		"(this package provides C language implementation, compiled)" \
	)
	#groups=arg
	license='WTFPL'

	arch=any
	#depends='tcc'
	#makedepends='clang' # idk
	makedepends='tcc'
	#checkdepends=''
	#optdepends=''
	provides=arg

	url=$_ghUrl
	sources=$_ghUrl/raw/master/arg.c
	#noextract=''
	md5sums=SKIP


	case ${makepkg_version+x} in x) eval '
		set -f # note: does not detect if is set or not before unsetting
		arch=($arch)
		source=($sources) # note: in Arch should be `source` insted of `sources` even tho its array
		md5sums=($md5sums)
		depends=($depends)
		makedepends=($makedepends)
		license=($license)
		provides=($provides)
		set +f
	'; esac



	prepare() {
		cd "${srcdir?}"
		case ${makepkg_version+makepkg} in
			makepkg)
				[ -e ./arg.c ]
				[ -L ./arg.c ] && [ -f "$startdir/arg.c" ] && \
				case $(readlink -f ./arg.c) in "$(readlink -f "$startdir/arg.c")") ;; *) false; esac && {
					rm ./arg.c
					mv -fT "$startdir/arg.c" ./arg.c
				}
			;;
			# todo: detect build systems Ubuntu/Debian AUR, Alpine, search for more
			*) printf %s\\n >&2 "unsupported build system"; return 3;;
		esac
	}

	build() {
		cd "${srcdir?}"
		tcc ./arg.c -o ./arg
	}

	check() {
		cd "${srcdir?}"
		case $(./arg '1 2' 3) in
			"'1 2' '3'") ;;
			*) false;;
		esac
	}

	package() {
		cd "${srcdir?}"
		mkdir -p "${pkgdir?}/usr/bin"
		cp -T ./arg "${pkgdir?}"/usr/bin/arg 
	}



}

{ # non PKGBUILD
	_prepare() {
		cd "$srcdir"
		for i in ${sources}; do
			 wget "$i"
		done
		unset i
	}
}



# if standalone packaging
case ${0##*/} in package.sh)
	[ -d out ] || mkdir out
	[ -d src ] || mkdir src
	[ -d pkg ] || mkdir pkg
	startdir=$PWD
	pkgdir=$PWD/pkg
	srcdir=$PWD/src
	_prepare; cd "$startdir"
	build; cd "$startdir"
	check; cd "$startdir"
	package; cd "$startdir"
	( cd pkg; tar -cvf - . ) > ./out/"$pkgname@$pkgver-$pkgrel.pkg.tar"
esac
