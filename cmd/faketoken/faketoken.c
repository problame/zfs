#include <inttypes.h>
#include <sys/zio_compress.h>
#include <zfs_fletcher.h>
#include <sys/zio_checksum.h>
#include <sys/zfs_ioctl.h>

#include <sys/nvpair.h>
#include <stdlib.h>
#include <zlib.h>

int main(int argc, char *argv[]) {

    uint64_t fromguid = 0;
    uint64_t object = 0;
    uint64_t offset = 0;
    uint64_t bytes = 0;
    uint64_t toguid = 9652651086130804799ULL;
    char *toname = "p1/secret@a";
    // uint64_t num_redact_snaps = 0;
    // uint64_t *redact_snaps = NULL;
    // uint64_t num_book_redact_snaps = 0;
    // uint64_t *book_redact_snaps = NULL;

    size_t packed_size, compressed_size;
    void *packed;
    uint8_t *compressed;

    // from get_receive_resume_stats_impl
    nvlist_t *token_nv = fnvlist_alloc();
    fnvlist_add_uint64(token_nv, "fromguid", fromguid);
    fnvlist_add_uint64(token_nv, "object", object);
    fnvlist_add_uint64(token_nv, "offset", offset);
    fnvlist_add_uint64(token_nv, "bytes", bytes);
    fnvlist_add_uint64(token_nv, "toguid", toguid);
    fnvlist_add_string(token_nv, "toname", toname);
    // fnvlist_add_boolean(token_nv, "largeblockok");
    // fnvlist_add_boolean(token_nv, "embedok");
    // fnvlist_add_boolean(token_nv, "compressok");
    // fnvlist_add_boolean(token_nv, "rawok");
    // fnvlist_add_uint64_array(token_nv, "redact_snaps",
    // 			    redact_snaps, num_redact_snaps);
    // fnvlist_add_uint64_array(token_nv, "book_redact_snaps",
    // 			    book_redact_snaps, num_book_redact_snaps);

	packed = fnvlist_pack(token_nv, &packed_size);
    fnvlist_free(token_nv);
    compressed = malloc(packed_size);

    compressed_size = gzip_compress(packed, compressed,
        packed_size, packed_size, 6);

    zio_cksum_t cksum;
    fletcher_4_native_varsize(compressed, compressed_size, &cksum);

    char *str = malloc(compressed_size * 2 + 1);
    for (int i = 0; i < compressed_size; i++) {
        (void) sprintf(str + i * 2, "%02x", compressed[i]);
    }
    str[compressed_size * 2] = '\0';
    char *propval;
    asprintf(&propval, "%u-%llx-%llx-%s",
        ZFS_SEND_RESUME_TOKEN_VERSION,
        (longlong_t)cksum.zc_word[0],
        (longlong_t)packed_size, str);
    printf("%s\n", propval);
}