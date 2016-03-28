# rsyslog: Log buffering and processing

find_package(CURL REQUIRED)
pkg_check_modules(LIBUUID REQUIRED uuid)

# Build libestr dependency for rsyslog, since Ubuntu 12.04's package is too old
# and CentOS 6's package has some pkg-config issues, so it's not picked up
# (https://bugzilla.redhat.com/show_bug.cgi?id=1152899).
ExternalProject_Add(
  libestr
  URL http://libestr.adiscon.com/files/download/libestr-${LIBESTR_VERSION}.tar.gz
  URL_HASH SHA256=${LIBESTR_HASH}
  BUILD_IN_SOURCE 1
  CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${INSTALL_PREFIX_EMBEDDED}
  INSTALL_COMMAND make install DESTDIR=${STAGE_DIR}
)

# Build json-c, since Ubuntu 12.04 doesn't offer this as a package, and once we
# upgrade to newer versions of rsyslog, we'll need to switch to libfastjson and
# build that from source anyway (since there are no system packages for that).
ExternalProject_Add(
  json-c
  URL https://s3.amazonaws.com/json-c_releases/releases/json-c-${JSON_C_VERSION}-nodoc.tar.gz
  URL_HASH SHA256=${JSON_C_HASH}
  BUILD_IN_SOURCE 1
  # Run autoreconf to fix issues with the bundled configure file being built
  # with specific versions of autoreconf and libtool that might be newer than
  # the default OS packages.
  CONFIGURE_COMMAND autoreconf --force --install -v
    COMMAND <SOURCE_DIR>/configure --prefix=${INSTALL_PREFIX_EMBEDDED}
  INSTALL_COMMAND make install DESTDIR=${STAGE_DIR}
)

ExternalProject_Add(
  librdkafka
  URL https://github.com/edenhill/librdkafka/archive/${LIBRDKAFKA_VERSION}.tar.gz
  URL_HASH MD5=${LIBRDKAFKA_HASH}
  BUILD_IN_SOURCE 1
  CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${INSTALL_PREFIX_EMBEDDED}
  INSTALL_COMMAND make install DESTDIR=${STAGE_DIR}
)

ExternalProject_Add(
  rsyslog
  DEPENDS libestr librdkafka
  URL http://www.rsyslog.com/download/files/download/rsyslog/rsyslog-${RSYSLOG_VERSION}.tar.gz
  URL_HASH SHA256=${RSYSLOG_HASH}
  BUILD_IN_SOURCE 1
  # --with-moddirs required to allow things to work in staged location, as well
  # as install location. Extra CFLAGS are needed when --with-moddirs is given
  # (since these default values go missing).
  CONFIGURE_COMMAND env "LIBESTR_LIBS=-L${STAGE_EMBEDDED_DIR}/lib -lestr" "LIBESTR_CFLAGS=-I${STAGE_EMBEDDED_DIR}/include" "CFLAGS=-I<SOURCE_DIR> -I<SOURCE_DIR>/grammar" LDFLAGS=-L${STAGE_EMBEDDED_DIR}/lib <SOURCE_DIR>/configure --prefix=${INSTALL_PREFIX_EMBEDDED} --with-moddirs=${STAGE_EMBEDDED_DIR}/lib/rsyslog --disable-liblogging-stdlog --disable-libgcrypt --enable-imptcp --enable-mmjsonparse --enable-mmutf8fix --enable-elasticsearch --enable-omkafka
  INSTALL_COMMAND make install DESTDIR=${STAGE_DIR}
)