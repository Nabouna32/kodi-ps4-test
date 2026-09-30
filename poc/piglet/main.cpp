#include <EGL/egl.h>
#include <GLES2/gl2.h>
#include <orbis/Pigletv2VSH.h>
#include <orbis/Sysmodule.h>
#include <orbis/SystemService.h>
#include <cstdio>
#include <cstdint>
#include <cerrno>
#include <cstring>
#include <vector>

namespace {
constexpr int W=1920, H=1080;

bool Check(const char* what) {
  GLenum e=glGetError();
  if(e==GL_NO_ERROR) return true;
  std::printf("[FAIL] %s: GL 0x%04x\n",what,e);
  return false;
}
bool Read(const char* path,std::vector<std::uint8_t>& d) {
  FILE* f=std::fopen(path,"rb"); if(!f){std::printf("[FAIL] %s errno=%d\n",path,errno);return false;}
  std::fseek(f,0,SEEK_END); long n=std::ftell(f); std::rewind(f);
  if(n<4){std::fclose(f);return false;} d.resize((size_t)n);
  bool ok=std::fread(d.data(),1,d.size(),f)==d.size(); std::fclose(f); return ok;
}
bool Shader(GLuint id,const char* path) {
  std::vector<std::uint8_t> d; if(!Read(path,d)) return false;
  std::uint32_t format=0; std::memcpy(&format,d.data(),4);
  std::printf("[INFO] %s format=0x%08x payload=%zu\n",path,format,d.size()-4);
  glShaderBinary(1,&id,(GLenum)format,d.data()+4,(GLint)d.size()-4);
  return Check("glShaderBinary");
}
bool InitPiglet() {
  OrbisPglConfig c{}; c.size=sizeof(c);
  c.flags=ORBIS_PGL_FLAGS_USE_COMPOSITE_EXT|ORBIS_PGL_FLAGS_USE_FLEXIBLE_MEMORY;
  c.processOrder=1; c.systemSharedMemorySize=250*1024*1024;
  c.videoSharedMemorySize=512*1024*1024; c.maxMappedFlexibleMemory=170*1024*1024;
  c.drawCommandBufferSize=1024*1024; c.lcueResourceBufferSize=1024*1024;
  if(!scePigletSetConfigurationVSH(&c)){std::printf("[FAIL] Piglet configuration\n");return false;}
  return true;
}
bool InitEgl(EGLDisplay& d,EGLSurface& s,EGLContext& c) {
  d=eglGetDisplay(EGL_DEFAULT_DISPLAY); if(d==EGL_NO_DISPLAY) return false;
  EGLint major=0,minor=0; if(!eglInitialize(d,&major,&minor)) return false;
  std::printf("[PASS] EGL %d.%d\n",major,minor);
  if(!eglBindAPI(EGL_OPENGL_ES_API)) return false;
  const EGLint a[]={EGL_RED_SIZE,8,EGL_GREEN_SIZE,8,EGL_BLUE_SIZE,8,EGL_ALPHA_SIZE,8,
    EGL_DEPTH_SIZE,0,EGL_STENCIL_SIZE,0,EGL_SAMPLE_BUFFERS,0,EGL_SAMPLES,0,
    EGL_RENDERABLE_TYPE,EGL_OPENGL_ES2_BIT,EGL_SURFACE_TYPE,EGL_WINDOW_BIT,EGL_NONE};
  EGLConfig cfg=nullptr; EGLint count=0; if(!eglChooseConfig(d,a,&cfg,1,&count)||count!=1)return false;
  eglSwapInterval(d,0);
  OrbisPglWindow w{0,(khronos_uint32_t)W,(khronos_uint32_t)H};
  const EGLint sa[]={EGL_RENDER_BUFFER,EGL_BACK_BUFFER,EGL_NONE};
  s=eglCreateWindowSurface(d,cfg,&w,sa); if(s==EGL_NO_SURFACE)return false;
  const EGLint ca[]={EGL_CONTEXT_CLIENT_VERSION,2,EGL_NONE};
  c=eglCreateContext(d,cfg,EGL_NO_CONTEXT,ca); if(c==EGL_NO_CONTEXT)return false;
  if(!eglMakeCurrent(d,s,s,c))return false;
  std::printf("[PASS] GLES2 context current\n[INFO] vendor=%s\n[INFO] renderer=%s\n[INFO] version=%s\n[INFO] extensions=%s\n",
    glGetString(GL_VENDOR),glGetString(GL_RENDERER),glGetString(GL_VERSION),glGetString(GL_EXTENSIONS));
  return true;
}
bool Graphics() {
  GLuint vs=glCreateShader(GL_VERTEX_SHADER),fs=glCreateShader(GL_FRAGMENT_SHADER),p=glCreateProgram();
  if(!vs||!fs||!p)return false;
  if(!Shader(vs,"/app0/assets/shaders/vertex.bin")||!Shader(fs,"/app0/assets/shaders/fragment.bin"))return false;
  glAttachShader(p,vs);glAttachShader(p,fs);glLinkProgram(p);if(!Check("link"))return false;
  GLint linked=GL_FALSE;glGetProgramiv(p,GL_LINK_STATUS,&linked);
  if(linked!=GL_TRUE){char log[512]{};GLsizei n=0;glGetProgramInfoLog(p,511,&n,log);std::printf("[FAIL] link: %s\n",log);return false;}
  std::printf("[PASS] shader pair linked\n");
  GLuint tex=0;glGenTextures(1,&tex);glBindTexture(GL_TEXTURE_2D,tex);
  std::uint32_t px=0xffffffffu;glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,3,5,0,GL_RGBA,GL_UNSIGNED_BYTE,&px);
  if(!Check("NPOT texture"))return false;std::printf("[PASS] NPOT texture 3x5\n");
  GLuint fbo=0,color=0;glGenFramebuffers(1,&fbo);glBindFramebuffer(GL_FRAMEBUFFER,fbo);
  glGenTextures(1,&color);glBindTexture(GL_TEXTURE_2D,color);
  glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,W,H,0,GL_RGBA,GL_UNSIGNED_BYTE,nullptr);
  glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,color,0);
  GLenum status=glCheckFramebufferStatus(GL_FRAMEBUFFER);
  if(status!=GL_FRAMEBUFFER_COMPLETE){std::printf("[FAIL] FBO 0x%04x\n",status);return false;}
  std::printf("[PASS] color FBO complete\n");
  return true;
}
}
int main() {
  std::printf("Kodi PS4 R-002A Piglet POC\n");
  sceSysmoduleLoadModuleInternal(ORBIS_SYSMODULE_INTERNAL_SYSTEM_SERVICE);
  sceSystemServiceHideSplashScreen();
  if(!InitPiglet())return 1;
  EGLDisplay d=EGL_NO_DISPLAY;EGLSurface s=EGL_NO_SURFACE;EGLContext c=EGL_NO_CONTEXT;
  if(!InitEgl(d,s,c)||!Graphics())return 1;
  glViewport(0,0,W,H);glClearColor(.08f,.12f,.18f,1.f);glClear(GL_COLOR_BUFFER_BIT);
  if(!eglSwapBuffers(d,s)){std::printf("[FAIL] eglSwapBuffers 0x%04x\n",eglGetError());return 1;}
  std::printf("[PASS] first EGL presentation\n");
  return 0;
}
