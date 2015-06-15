#include "stdbool.h"
#include "stdio.h"
#include "stdlib.h"
#include "assert.h"
#include "inttypes.h"
#if __POPCNT__
#include "popcntintrin.h"
#endif

// Block of cached bit count.
// Fields:
//   chunks: payload of a bit vector separated into 4 chunks
//   large:  cached bit count of a bit vector
//   ext:    extension of the `large` field; 32 bits + 8 bits = 40 bits
//   smalls: block-local bit count; smalls[i] stores the number of 1s in chunks[i] for i=0,1,2
// The extended large bit count can be computed as:
//   (ext << sizeof(large)) + large
// The maximum number of 1s in a bit vector is:
//   2^40 (extended large block) + 2^8 (small block) = 1,099,511,628,032 ≈ 1 Gbits.
// The extra bits are:
//   (32 + 8 + 8*3) / 64*4 (payload) = 0.25 bits/bit
typedef struct block_s {
    uint64_t chunks[4];
    uint32_t large;
    uint8_t ext;
    // small blocks
    uint8_t smalls[3];
} block_t;

// Bit vector
typedef struct sucvector_s {
    int64_t len;
    block_t* blocks;
} sucvector_t;

inline uint8_t count_ones(uint64_t x)
{
#if __POPCNT__
    // SSE4 (-msse4) is needed.
    return _mm_popcnt_u64(x);
#else
    x = ((x & 0xaaaaaaaaaaaaaaaaUL) >> 1)
      +  (x & 0x5555555555555555UL);
    x = ((x & 0xccccccccccccccccUL) >> 2
      +  (x & 0x3333333333333333UL);
    x = ((x & 0xf0f0f0f0f0f0f0f0UL) >> 4)
      +  (x & 0x0f0f0f0f0f0f0f0fUL);
    x = ((x & 0xff00ff00ff00ff00UL) >> 8)
      +  (x & 0x00ff00ff00ff00ffUL);
    x = ((x & 0xffff0000ffff0000UL) >> 16)
      +  (x & 0x0000ffff0000ffffUL);
    x = ((x & 0xffffffff00000000UL) >> 32)
      +  (x & 0x00000000ffffffffUL);
    return x;
#endif
}

const int bits_per_chunk =  64;
const int bits_per_block = 256;

block_t make_block(uint64_t* chunks, int len, int64_t offset)
{
    // do not make an empty block
    assert(1 <= len && len <= 4);
    block_t block = { .large = offset, .ext = (uint8_t)(offset >> 32) };
    // fill chunks
    for (size_t i = 0; i < len; i++)
        block.chunks[i] = chunks[i];
    // fill small blocks
    uint8_t cumsum = 0;
    for (size_t i = 0; i < len-1; i++) {
        cumsum += (uint8_t)count_ones(chunks[i]);
        block.smalls[i] = cumsum;
    }
    return block;
}

sucvector_t* make_sucvector(void)
{
    sucvector_t* sucvector = malloc(sizeof(sucvector_t));
    sucvector->blocks = NULL;
    sucvector->len = 0;
    return sucvector;
}

void delete_sucvector(sucvector_t* v)
{
    free(v->blocks);
    free(v);
}

// a bit vector is fed into the sucvector `v` from the `chunks` (`len` bits)
int read_chunks(sucvector_t* v, uint64_t chunks[], size_t len)
{
    assert(v->blocks == NULL && v->len == 0);
    if (len == 0)
        return 0;
    size_t n_blocks = (len - 1) / bits_per_block + 1;
    block_t* blocks = malloc(sizeof(block_t) * n_blocks);
    if (blocks == NULL)
        return -1;  // malloc failed
    size_t n_chunks = (len - 1) / bits_per_chunk + 1;
    int64_t offset = 0;
    for (size_t i = 0; i < n_blocks; i++) {
        int r;  // the number of chunks fed into the current block
        if (i == n_blocks - 1 && n_chunks % 4 != 0)
            r = n_chunks % 4;  // 1-3 chunks
        else
            r = 4;
        blocks[i] = make_block(chunks + i * 4, r, offset);
        for (size_t j = 0; j < 4; j++)
            offset += count_ones(chunks[i * 4 + j]);
    }
    // set members
    v->blocks = blocks;
    v->len = len;
    return 0;
}

// Return length of `v`.
int64_t length(sucvector_t* v)
{
    return v->len;
}

// Return the `i`-th significant bit of `chunk`.
inline bool bitat(uint64_t chunk, int64_t i)
{
    return (chunk >> (63 - i) & 1) == 1;
}

// Return the `i`-th bit of `v`.
bool access(sucvector_t* v, int64_t i)
{
    int64_t q = i / bits_per_block;
    int64_t r = i % bits_per_block;
    block_t block = v->blocks[q];
    q = r / bits_per_chunk;
    r = r % bits_per_chunk;
    uint64_t chunk = block.chunks[q];
    return bitat(chunk, r);
}

// Return the number of 1s in v[0,i).
int64_t rank1(sucvector_t* v, int64_t i)
{
    if (i < 0)
        return 0;
    int64_t q = i / bits_per_block;
    int64_t r = i % bits_per_block;
    block_t block = v->blocks[q];
    int64_t ret = 0;
    // large block
    ret += ((int64_t)block.ext << sizeof(block.large)) + block.large;
    // small block
    q = r / bits_per_chunk;
    r = r % bits_per_chunk;
    // TODO: is it possible to remove this branch?
    if (q > 0) {
        ret += block.smalls[q-1];
    }
    // remaining bits
    uint64_t chunk = block.chunks[q];
    uint64_t mask = UINT64_MAX << (63 - r);
    ret += count_ones(chunk & mask);
    return ret;
}
