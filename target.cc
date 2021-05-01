#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <unistd.h>

#include "libxml/xmlversion.h"
#include "libxml/parser.h"
#include "libxml/HTMLparser.h"
#include "libxml/tree.h"

void ignore (void * ctx, const char * msg, ...) {}

void usage(const char *argv[]) {
    fprintf(stderr, "usage: %s XML_FILE\n", argv[0]);
    exit(1);
}

void hex_dump(unsigned char* buf, size_t len)
{
    printf("(size = %lx)\n", len);
    for (size_t i = 0; i < len && i < 0x100; i += 0x10) {
        printf("%04lx: ", i / 0x10 * 0x10);
        for (int j = 0; j < 0x10 && i + j < len; j += 1){
            printf("%02x ", buf[i + j]);
            if (j == 7) printf("   ");
        }
        printf("\n");
    }
}

int main(int argc, const char* argv[]) {
    if (argc < 2) {
        usage(argv);
    }
    const char *xml_file_path = argv[1];

    // Open file
    FILE* file = fopen(xml_file_path, "rb");
    if (!file) {
        perror("Cannot open");
        exit(1);
    }

    // Get file size
    struct stat file_stat;
    fstat(fileno(file), &file_stat);
    size_t buf_size = file_stat.st_size;
    // printf("[*] Size of file %s: %ld\n", xml_file_path, buf_size); // DEBUG:

    // Map file to read-only memory
    void *buf = mmap(NULL, buf_size, PROT_READ, MAP_SHARED, fileno(file), 0);
    if (buf == MAP_FAILED) {
        perror("Failed to mmap file");
        exit(1);
    }

    // hex_dump(reinterpret_cast<unsigned char *>(buf), buf_size); // DEBUG:

    // xmlSetGenericErrorFunc(NULL, &ignore);

    if (auto doc = xmlReadMemory(
        reinterpret_cast<const char *>(buf), buf_size,
        xml_file_path, NULL, 0)
        )
    xmlFreeDoc(doc);

    return 0;
}