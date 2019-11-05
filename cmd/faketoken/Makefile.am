include $(top_srcdir)/config/Rules.am

sbin_PROGRAMS = faketoken

faketoken_SOURCES = \
	faketoken.c

faketoken_LDADD = \
	$(top_builddir)/lib/libnvpair/libnvpair.la \
	$(top_builddir)/lib/libuutil/libuutil.la \
	$(top_builddir)/lib/libzfs/libzfs.la \
	$(top_builddir)/lib/libzfs_core/libzfs_core.la \
	$(top_builddir)/lib/libzpool/libzpool.la
