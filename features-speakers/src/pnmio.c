#include <stdio.h>
#include <stdarg.h>
#include <ctype.h>
#include "bips.h"

void
fatal(char* fmt, ...)
{
   va_list args;
   va_start(args,fmt);
   fputs("Fatal error: ",stderr);
   vfprintf(stderr,fmt,args);
   fputc('\n',stderr);
   exit(1);
}
void
warning(char* fmt, ...)
{
   va_list args;
   va_start(args,fmt);
   fputs("Warning: ",stderr);
   vfprintf(stderr,fmt,args);
   fputc('\n',stderr);
}

void
fskip_comments(FILE* f, int comment_start)
{
   int c;
   for(;;) {
      do c=getc(f); while (isspace(c));
      if (c!=comment_start) break;
      do { if ((c=getc(f))==EOF) return; } while (c!='\n');
   };
   ungetc(c,f);
}

int
fscanf_pnm_header(FILE* in, const char* filename, 
		  int *magic, int *width, int *height, int *maxval) 
{
   static const char *fieldname[] = 
      { "magic-number","width","height","max-value","first pixel" };
   int *arg[4],i,c;
   arg[0]=magic, arg[1]=width, arg[2]=height, arg[3]=maxval;
   for (i=0; i<4; i++) {
      fskip_comments(in,'#');
      if (i==0 && getc(in)!='P') goto badformat;
      if (fscanf(in,"%d",arg[i])!=1) goto badformat;
   }
   do { 
      if ((c=getc(in))==EOF) goto badformat; 
   } while (c!='\n');

   if (*magic<=0 || *magic>=10
       || *width<0 || *height<0
       || *maxval<1) {
      fatal("PNM image file `%s': garbage in header",filename);
      return EOF;
   }
   return 0;

 badformat:
   fatal("PNM file `%s': can't read %s",filename,fieldname[i]);
   return EOF;
}

u8*
fread_u8_pnm(const char* file, int* _nx, int* _ny, int* _nc)
{
   FILE* in=fopen(file,"r");
   int magic,maxval;
   long l=0,len=0;
   int nx,ny,nc=1, x,y,c, v;
   u8* out=0;
   if (!in) fatal("Can't open PNM file `%s'",file);
   if (fscanf_pnm_header(in,file,&magic,&nx,&ny,&maxval)) 
      goto badread;
   nc = (magic==6 || magic==3)? 3 : 1;
   len = nc*nx*ny;
   switch(magic) {
   case 5: case 6:
      if (maxval>=256) 
	 fatal("PNM file `%s': max-value %d too big for u8 image",file,maxval);
      out = ALLOC(u8,len);
      if ((l=fread(out,1,len,in))!=len) 
	 goto badread;
      break;
   case 2: case 3:
      out = ALLOC(u8,len);
      if (maxval<256) {
	 for (y=0; y<ny; y++) {
	    for (x=0; x<nx; x++) {
	       for (c=0; c<nc; c++) {
		  if (fscanf(in,"%d",&v)!=1) goto badread;
		  out[c+nc*(x+nx*y)] = u8_LIMIT(v);
	       }
	    }
	 }
      } else {
	 double scale = 256.0/(maxval+1.0);
	 warning("PNM file `%s': max-value %d too big for u8 image: scaling gray values",
		 file,maxval);
	 for (y=0; y<ny; y++) {
	    for (x=0; x<nx; x++) {
	       for (c=0; c<nc; c++) {
		  if (fscanf(in,"%d",&v)!=1) goto badread;
		  out[c+nc*(x+nx*y)] = u8_LIMIT((scale*v+0.49999));
	       }
	    }
	 }
      }
      break;
   default:
      fatal("PNM file `%s': image format `P%d' not implemented",file,magic);
   }
   do c=getc(in); while (isspace(c));
   if (c != EOF) 
      warning("PNM file `%s': ignoring unused bytes at end of file",file);
   fclose(in);
   *_nx = nx;
   *_ny = ny;
   *_nc = nc;
   return out;
 badread:
   if (out) FREE(out);
   fclose(in);
   fatal("PNM file `%s': couldn't read pixel %ld/%ld",file,l,len);
   return 0;
}

u8*
u8_rgb_to_grey(int nx, int ny, 
	       u8 out[/*0:nx-1@1,0:ny-1@dy*/], int dxo, int dyo,
	       const u8 in[/*0:nx-1@dxi,0:ny-1@dyi,0:nc-1@dci*/], 
	       int dxi, int dyi, int dci)
{
   int x,y;
   if (!out && !(out = ALLOC(u8,nx*ny)))
      return 0;
   for (y=0; y<ny; y++) {
      for (x=0; x<nx; x++) {
	 const u8* ixy = &in[x*dxi+y*dyi];
	 out[x*dxo+y*dyo] = (u8)(0.299*ixy[0] + 0.587*ixy[dci] + 0.144*ixy[2*dci]);
      }
   }
   return out;
}

u8*
fread_u8_pgm(const char* file, int* _nx, int* _ny)
{
   int nx=0,ny=0,nc=0;
   u8* im = fread_u8_pnm(file,&nx,&ny,&nc);
   if (!im) return 0;
   if (nc > 1) {
      u8* img = u8_rgb_to_grey(nx,ny, 0,1,nx, im,nc,nc*nx,1);
      FREE(im);
      im = img;
   }
   *_nx = nx;
   *_ny = ny;
   return im;
}

#if 0
void
fwrite_u8_pgm(const char* file, int nx, int ny, 
	      u8* im, int dx, int dy)
{
   FILE* out=fopen(file,"w");
   int x,y;
   if (!out || fprintf(out,"P5\n%d %d\n%d\n",nx,ny,255)<=0) 
      goto fail;

   if (dx!=1) {
      for (y=0; y<ny*dy; y+=dy)
	 for (x=0; x<nx*dx; x+=dx)
	    if (putc(im[x+y],out)==EOF) goto fail;
   }
   else if (dy!=nx) {
      for (y=0; y<ny; y++)
	 if (fwrite(im+y*dy,sizeof(u8),nx,out)!=nx) goto fail;
   }
   else {
      if (fwrite(im,sizeof(u8),nx*ny,out)!=nx*ny) {
      fail:
	 fatal("Can't write PNM image file `%s'",file);
      }
   }
   fclose(out);
}
#endif

void
fwrite_u8_pnm(const char* file, int nx, int ny, int nc, 
	      const u8 im[/*0:nx-1@dx,0:ny-1@dy,0:nc-1@dc*/], int dx, int dy, int dc)
{
   FILE* out=(file)? fopen(file,"w") : stdout;
   if (!out || (nc!=1 && nc!=3)
       || fprintf(out,"P%d\n%d %d\n%d\n",(nc==3)?6:5,nx,ny,255)<=0) {
   fail:
      fatal("Can't write PNM image file `%s'",file);
      return;
   }
   if (dc==1 && dx==nc && dy==nc*nx) {
      if ((int) fwrite(im,sizeof(u8),nc*nx*ny,out)!=nc*nx*ny) 
	 goto fail;
   } else {
      int x,y,c;
      for (y=0; y<ny; y++) {
	 for (x=0; x<nx; x++) {
	    for (c=0; c<nc; c++) {
	       if (putc(im[c*dc+x*dx+y*dy],out)==EOF) 
		  goto fail;
	    }
	 }
      }
   }
   if (out && file) fclose(out);
}

void
fwrite_f32_pgm(const char* file, int nx, int ny, 
	       f32* im, int dx, int dy,
	       f32 lo, f32 hi, int verbose)
{
   FILE* out=(file)? fopen(file,"w") : stdout;
   f32 scale;
   int x,y;
   if (!out || fprintf(out,"P5\n%d %d\n%d\n",nx,ny,255)<=0) {
   fail:
      fatal("Can't write PNM image file `%s'",file);
   }
   if (lo == hi) {
      /* Auto-scale to range of image */
      for (lo=hi=im[0],y=0; y<ny*dy; y+=dy) {
	 for (x=0; x<nx*dx; x+=dx) {
	    f32 t = im[x+y];
	    if (lo > t) lo = t;
	    if (hi < t) hi = t;	   
	 }
      }
      if (verbose) {
	 fprintf(stdout,"%s: lo=%f hi=%f\n",file?file:"STDOUT",lo,hi);
      }
   }
   scale = (lo == hi)? 1.0 : 256.0/(hi-lo);
   for (y=0; y<ny*dy; y+=dy) {
      for (x=0; x<nx*dx; x+=dx) {
	 f32 t = scale * (im[x+y] - lo) + 0.5;
	 if (t<0.0) t=0.0; else if (t>=255.0) t=255.0;
	 if (putc((int)t,out)==EOF) goto fail;
      }
   }
   fclose(out);
}
