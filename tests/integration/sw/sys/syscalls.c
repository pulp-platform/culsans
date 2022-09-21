// See LICENSE for license details.

#include <stdarg.h>
#include <stdio.h>
#include <limits.h>
#include <sys/signal.h>

#include <string.h>

#include <stddef.h>
#include <stdint.h>

#include "list.h"


#ifdef __riscv
#include "encoding.h"
#endif

#define static_assert(cond) switch(0) { case 0: case !!(long)(cond): ; }

#define SYS_write 64

#undef strcmp

extern volatile uint64_t tohost;
extern volatile uint64_t fromhost;

static uintptr_t syscall(uintptr_t which, uint64_t arg0, uint64_t arg1, uint64_t arg2)
{
  volatile uint64_t magic_mem[8] __attribute__((aligned(64)));
  magic_mem[0] = which;
  magic_mem[1] = arg0;
  magic_mem[2] = arg1;
  magic_mem[3] = arg2;
  __sync_synchronize();

  tohost = (uintptr_t)magic_mem;
  while (fromhost == 0)
    ;
  fromhost = 0;

  __sync_synchronize();
  return magic_mem[0];
}

void __attribute__((noreturn)) tohost_exit(uintptr_t code)
{
  tohost = (code << 1) | 1;
  asm volatile("fence");
  while (1);
}

uintptr_t __attribute__((weak)) handle_trap(uintptr_t cause, uintptr_t epc, uintptr_t regs[32])
{
  tohost_exit(1337);
}

void exit(int code)
{
  tohost_exit(code);
}

void abort()
{
  exit(128 + SIGABRT);
}

void __attribute__((weak)) thread_entry(int cid, int nc)
{
  // multi-threaded programs override this function.
  // for the case of single-threaded programs, only let core 0 proceed.
  while (cid != 0);
}

int __attribute__((weak)) main(int argc, char** argv)
{
  // single-threaded programs override this function.

  return -1;
}

static void init_tls()
{
  register void* thread_pointer asm("tp");
  extern char _tls_data;
  extern __thread char _tdata_begin, _tdata_end, _tbss_end;
  size_t tdata_size = &_tdata_end - &_tdata_begin;
  memcpy(thread_pointer, &_tls_data, tdata_size);
  size_t tbss_size = &_tbss_end - &_tdata_end;
  memset(thread_pointer + tdata_size, 0, tbss_size);
}

void _init(int cid, int nc)
{
  init_tls();
  thread_entry(cid, nc);

  // only single-threaded programs should ever get here.
  int ret = main(0, 0);

  exit(ret);
}

void* memcpy(void* dest, const void* src, size_t len)
{
  if ((((uintptr_t)dest | (uintptr_t)src | len) & (sizeof(uintptr_t)-1)) == 0) {
    const uintptr_t* s = src;
    uintptr_t *d = dest;
    while (d < (uintptr_t*)(dest + len))
      *d++ = *s++;
  } else {
    const char* s = src;
    char *d = dest;
    while (d < (char*)(dest + len))
      *d++ = *s++;
  }
  return dest;
}

void* memset(void* dest, int byte, size_t len)
{
  if ((((uintptr_t)dest | len) & (sizeof(uintptr_t)-1)) == 0) {
    uintptr_t word = byte & 0xFF;
    word |= word << 8;
    word |= word << 16;
    word |= word << 16 << 16;

    uintptr_t *d = dest;
    while (d < (uintptr_t*)(dest + len))
      *d++ = word;
  } else {
    char *d = dest;
    while (d < (char*)(dest + len))
      *d++ = byte;
  }
  return dest;
}

size_t strlen(const char *s)
{
  const char *p = s;
  while (*p)
    p++;
  return p - s;
}

size_t strnlen(const char *s, size_t n)
{
  const char *p = s;
  while (n-- && *p)
    p++;
  return p - s;
}

int strcmp(const char* s1, const char* s2)
{
  unsigned char c1, c2;

  do {
    c1 = *s1++;
    c2 = *s2++;
  } while (c1 != 0 && c1 == c2);

  return c1 - c2;
}

char* strcpy(char* dest, const char* src)
{
  char* d = dest;
  while ((*d++ = *src++))
    ;
  return dest;
}

long atol(const char* str)
{
  long res = 0;
  int sign = 0;

  while (*str == ' ')
    str++;

  if (*str == '-' || *str == '+') {
    sign = *str == '-';
    str++;
  }

  while (*str) {
    res *= 10;
    res += *str++ - '0';
  }

  return sign ? -res : res;
}

#define ALIGN_SIZE(sz, align) (((sz) + ((align)-1)) & ~((align)-1))
typedef struct alloc_node
{
	struct list_head node;
	size_t size;
	char* block;
} alloc_node_t;

/* allocation metadata size */
#define ALLOC_HEADER_SZ __builtin_offsetof(alloc_node_t, block)

/* minimum allocation size of 32 bytes */
#define MIN_ALLOC_SZ ALLOC_HEADER_SZ + 32

/* free list */
static LIST_HEAD(free_list);

static void coalesce_free_list(void)
{
	alloc_node_t *b, *lb = NULL, *t;

	list_for_each_entry_safe(b, t, &free_list, node)
	{
		if (lb)
		{
			/* coalesce adjacent blocks */
			if ((((uintptr_t)&lb->block) + lb->size) == (uintptr_t)b)
			{
				lb->size += sizeof(*b) + b->size;
				list_del(&b->node);
				continue;
			}
		}
		lb = b;
	}
}

void* malloc(size_t size)
{
	void* ptr = NULL;
	alloc_node_t* blk = NULL;

	if (size > 0)
	{
		/* Align the pointer */
		size = ALIGN_SIZE(size, sizeof(void*));

		/* try to find a big enough block */
		list_for_each_entry(blk, &free_list, node)
		{
			if (blk->size >= size)
			{
				ptr = &blk->block;
				break;
			}
		}

		if (ptr)
		{
			/* split block if possible */
			if ((blk->size - size) >= MIN_ALLOC_SZ)
			{
				alloc_node_t* new_blk;
				new_blk = (alloc_node_t*)((uintptr_t)(&blk->block) + size);
				new_blk->size = blk->size - size - ALLOC_HEADER_SZ;
				blk->size = size;
				list_add(&new_blk->node, &blk->node);
			}

			list_del(&blk->node);
		}

	}

	return ptr;
}

void free(void* ptr)
{
	alloc_node_t *blk, *free_blk;

	if (ptr)
	{
		blk = container_of(ptr, alloc_node_t, block);

		/* add block to free list in ascending order by pointer */
		list_for_each_entry(free_blk, &free_list, node)
		{
			if (free_blk > blk)
			{
				list_add_tail(&blk->node, &free_blk->node);
				goto blockadded;
			}
		}
		list_add_tail(&blk->node, &free_list);

	blockadded:
		coalesce_free_list();
	}
}

void _malloc_addblock(void* addr, size_t size)
{
	alloc_node_t* blk;

	/* pointer align the block */
	blk = (alloc_node_t*)ALIGN_SIZE((uintptr_t)addr, sizeof(void*));

	/* calculate usable size */
	blk->size = (uintptr_t)addr + size - (uintptr_t)blk - ALLOC_HEADER_SZ;

	/* add the block to the free list */
	list_add(&blk->node, &free_list);
}







