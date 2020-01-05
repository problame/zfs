#!/bin/ksh -p
#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#

#
# Copyright 2017, loli10K <ezomori.nozomu@gmail.com>. All rights reserved.
# Copyright 2019, 2020 by Christian Schwarz. All rights reserved.
#

. $STF_SUITE/include/libtest.shlib

#
# DESCRIPTION:
# 'zfs bookmark' should work with both full and short arguments.
#
# STRATEGY:
# 1. Create initial snapshot
#
# 2. Verify we can create a bookmark specifying snapshot and bookmark full paths
# 3. Verify we can create a bookmark specifying the short snapshot name
# 4. Verify we can create a bookmark specifying the short bookmark name
# 5. Verify at least a full dataset path is required and both snapshot and
#    bookmark name must be valid
#
# 6. Verify we can copy a bookmark by specifying the source bookmark and new
#    bookmark full paths.
# 7. Verify we can copy a bookmark specifying the short source name
# 8. Verify we can copy a bookmark specifying the short new name
# 9. Verify two short paths are not allowed, and test empty paths
# 10. Verify we cannot copy a bookmark if the new bookmark already exists
# 11. Verify that copying a bookmark only works if new and source name
#     have the same dataset
#

verify_runnable "both"

function cleanup
{
	if snapexists "$DATASET@$TESTSNAP"; then
		log_must zfs destroy "$DATASET@$TESTSNAP"
	fi
	if bkmarkexists "$DATASET#$TESTBM"; then
		log_must zfs destroy "$DATASET#$TESTBM"
	fi
	if bkmarkexists "$DATASET#$TESTBMCOPY"; then
		log_must zfs destroy "$DATASET#$TESTBMCOPY"
	fi
}

log_assert "'zfs bookmark' should work only when passed valid arguments."
log_onexit cleanup

DATASET="$TESTPOOL/$TESTFS"
TESTSNAP='snapshot'
TESTSNAP2='snapshot2'
TESTBM='bookmark'
TESTBMCOPY='bookmark_copy'


# Create initial snapshot
log_must zfs snapshot "$DATASET@$TESTSNAP"

#
# Bookmark creation tests
#

# Verify we can create a bookmark specifying snapshot and bookmark full paths
log_must zfs bookmark "$DATASET@$TESTSNAP" "$DATASET#$TESTBM"
log_must eval "bkmarkexists $DATASET#$TESTBM"
log_must zfs destroy "$DATASET#$TESTBM"

# Verify we can create a bookmark specifying the snapshot name
log_must zfs bookmark "@$TESTSNAP" "$DATASET#$TESTBM"
log_must eval "bkmarkexists $DATASET#$TESTBM"
log_must zfs destroy "$DATASET#$TESTBM"

# Verify we can create a bookmark specifying the bookmark name
log_must zfs bookmark "$DATASET@$TESTSNAP" "#$TESTBM"
log_must eval "bkmarkexists $DATASET#$TESTBM"
log_must zfs destroy "$DATASET#$TESTBM"

# Verify at least a full dataset path is required and both snapshot and
# bookmark name must be valid
log_mustnot zfs bookmark "@$TESTSNAP" "#$TESTBM"
log_mustnot zfs bookmark "$TESTSNAP" "#$TESTBM"
log_mustnot zfs bookmark "@$TESTSNAP" "$TESTBM"
log_mustnot zfs bookmark "$TESTSNAP" "$TESTBM"
log_mustnot zfs bookmark "$TESTSNAP" "$DATASET#$TESTBM"
log_mustnot zfs bookmark "$DATASET" "$TESTBM"
log_mustnot zfs bookmark "$DATASET@" "$TESTBM"
log_mustnot zfs bookmark "$DATASET" "#$TESTBM"
log_mustnot zfs bookmark "$DATASET@" "#$TESTBM"
log_mustnot zfs bookmark "$DATASET@$TESTSNAP" "$TESTBM"
log_mustnot zfs bookmark "@" "#$TESTBM"
log_mustnot zfs bookmark "@" "#"
log_mustnot zfs bookmark "@$TESTSNAP" "#"
log_mustnot zfs bookmark "@$TESTSNAP" "$DATASET#"
log_mustnot zfs bookmark "@$TESTSNAP" "$DATASET"
log_mustnot zfs bookmark "$TESTSNAP" "$DATASET#"
log_mustnot zfs bookmark "$TESTSNAP" "$DATASET"
log_mustnot eval "bkmarkexists $DATASET#$TESTBM"

#
# Bookmark copying tests
#

# create the source bookmark
log_must zfs bookmark "$DATASET@$TESTSNAP" "$DATASET#$TESTBM"

# Verify we can copy a bookmark by specifying the source bookmark
# and new bookmark full paths.
log_must eval "bkmarkexists $DATASET#$TESTBM"
log_must zfs bookmark "$DATASET#$TESTBM" "$DATASET#$TESTBMCOPY"
log_must eval "bkmarkexists $DATASET#$TESTBMCOPY"
## validate destroy once (should be truly independent bookmarks)
log_must zfs destroy "$DATASET#$TESTBM"
log_mustnot eval "bkmarkexists $DATASET#$TESTBM"
log_must eval "bkmarkexists $DATASET#$TESTBMCOPY"
log_must zfs destroy "$DATASET#$TESTBMCOPY"
log_mustnot eval "bkmarkexists $DATASET#$TESTBMCOPY"
log_mustnot eval "bkmarkexists $DATASET#$TESTBM"
## recreate the source bookmark
log_must zfs bookmark "$DATASET@$TESTSNAP" "$DATASET#$TESTBM"

# Verify we can copy a bookmark specifying the short source name
log_must zfs bookmark "#$TESTBM" "$DATASET#$TESTBMCOPY"
log_must eval "bkmarkexists $DATASET#$TESTBMCOPY"
log_must zfs destroy "$DATASET#$TESTBMCOPY"

# Verify we can copy a bookmark specifying the short bookmark name
log_must zfs bookmark "$DATASET#$TESTBM" "#$TESTBMCOPY"
log_must eval "bkmarkexists $DATASET#$TESTBMCOPY"
log_must zfs destroy "$DATASET#$TESTBMCOPY"

# Verify two short paths are not allowed, and test empty paths
log_mustnot zfs bookmark "#$TESTBM" "#$TESTBMCOPY"
log_mustnot zfs bookmark "#$TESTBM" "#"
log_mustnot zfs bookmark "#"        "#$TESTBMCOPY"
log_mustnot zfs bookmark "#"        "#"
log_mustnot zfs bookmark "#"        ""
log_mustnot zfs bookmark ""         "#"
log_mustnot zfs bookmark ""         ""

# Verify that copied 'normal' bookmarks are independent of the original bookmark
log_must zfs bookmark "$DATASET#$TESTBM" "$DATASET#$TESTBMCOPY"
log_must zfs destroy "$DATASET#$TESTBM"
log_must eval "zfs send $DATASET@$TESTSNAP > $TEST_BASE_DIR/zfstest_datastream.$$"
log_must eval "destroy_dataset $TESTPOOL/$TESTFS/recv"
log_must eval "zfs recv -o mountpoint=none $TESTPOOL/$TESTFS/recv < $TEST_BASE_DIR/zfstest_datastream.$$"
log_must zfs snapshot "$DATASET@$TESTSNAP2"
log_must eval "zfs send -i \#$TESTBMCOPY $DATASET@$TESTSNAP2 > $TEST_BASE_DIR/zfstest_datastream.$$"
log_must eval "zfs recv $TESTPOOL/$TESTFS/recv < $TEST_BASE_DIR/zfstest_datastream.$$"
# cleanup
log_must eval "destroy_dataset $DATASET@$TESTSNAP2"
log_must zfs destroy "$DATASET#$TESTBMCOPY"
log_must zfs bookmark "$DATASET@$TESTSNAP" "$DATASET#$TESTBM"

# Verify that copied redaction bookmarks are independent of the original bookmark
## create redaction bookmark
log_must zfs destroy "$DATASET#$TESTBM"
log_must zfs destroy "$DATASET@$TESTSNAP"
log_must eval "echo secret > $TESTDIR/secret"
log_must zfs snapshot "$DATASET@$TESTSNAP"
log_must eval "echo redacted > $TESTDIR/secret"
log_must zfs snapshot "$DATASET@$TESTSNAP2" # TESTSNAP2 is the redaction snapshot
log_must zfs list -t all -o name,createtxg,guid,mountpoint,written
log_must zfs redact "$DATASET@$TESTSNAP" "$TESTBM" "$DATASET@$TESTSNAP2"
## copy the redaction bookmark, destroy original
log_must zfs bookmark "$DATASET#$TESTBM" "#$TESTBMCOPY"
log_must zfs destroy "$DATASET#$TESTBM"
log_must eval 'echo foo | grep bar'
## try to use the copy
log_must eval "zfs send --redact "$TESTBM" $DATASET@$TESTSNAP > $TEST_BASE_DIR/zfstest_datastream.$$"
log_must eval "destroy_dataset $TESTPOOL/$TESTFS/recv"
log_must eval "zfs recv -o mountpoint=none $TESTPOOL/$TESTFS/recv < $TEST_BASE_DIR/zfstest_datastream.$$"
log_must eval "zfs send -i @$TESTSNAP $DATASET@$TESTSNAP2 > $TEST_BASE_DIR/zfstest_datastream.$$"
log_must eval "zfs recv $TESTPOOL/$TESTFS/recv < $TEST_BASE_DIR/zfstest_datastream.$$"
## cleanup
log_must eval "destroy_dataset $DATASET@$TESTSNAP2"
log_must zfs destroy "$DATASET#$TESTBMCOPY"
log_must zfs snapshot "$DATASET@$TESTSNAP"
log_must zfs bookmark "$DATASET@$TESTSNAP" "$DATASET#$TESTBM"

log_pass "'zfs bookmark' works as expected only when passed valid arguments."
