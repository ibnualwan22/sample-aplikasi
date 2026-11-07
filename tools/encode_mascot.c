/* Runtime format conversion. Preserve the owner's PNG originals in docs.
 * Build: cc tools/encode_mascot.c -o /tmp/encode_mascot -ldl
 * Usage: /tmp/encode_mascot input.png output.webp
 * Uses distribution GdkPixbuf and libwebp, no runtime app dependency.
 */
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
int main(int argc, char **argv) {
  if (argc != 3) return 1;
  void *g = dlopen("libgdk_pixbuf-2.0.so.0", RTLD_NOW);
  void *w = dlopen("libwebp.so.7", RTLD_NOW);
  if (!g || !w) return 2;
  void *(*load)(const char*, void**) = dlsym(g, "gdk_pixbuf_new_from_file");
  int (*width)(void*) = dlsym(g, "gdk_pixbuf_get_width");
  int (*height)(void*) = dlsym(g, "gdk_pixbuf_get_height");
  int (*stride)(void*) = dlsym(g, "gdk_pixbuf_get_rowstride");
  int (*alpha)(void*) = dlsym(g, "gdk_pixbuf_get_has_alpha");
  uint8_t *(*pixels)(void*) = dlsym(g, "gdk_pixbuf_get_pixels");
  size_t (*rgb)(const uint8_t*,int,int,int,float,uint8_t**) = dlsym(w,"WebPEncodeRGB");
  size_t (*rgba)(const uint8_t*,int,int,int,float,uint8_t**) = dlsym(w,"WebPEncodeRGBA");
  void (*release)(void*) = dlsym(w,"WebPFree");
  void *pix = load(argv[1], NULL);
  if (!pix) return 3;
  uint8_t *output = NULL;
  size_t size = (alpha(pix) ? rgba : rgb)(pixels(pix), width(pix), height(pix), stride(pix), 88, &output);
  if (!size) return 4;
  FILE *f = fopen(argv[2],"wb");
  if (!f) { release(output); return 5; }
  size_t written = fwrite(output,1,size,f);
  fclose(f); release(output);
  return written == size ? 0 : 6;
}
