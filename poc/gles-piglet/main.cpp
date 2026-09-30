#include "PigletApplication.hpp"
#include <GLES2/gl2.h>
#include <cstdio>
#include <cstring>

namespace {
bool HasExtension(const char* extensions, const char* wanted)
{
  if (!extensions || !wanted) return false;
  const size_t wantedLength = std::strlen(wanted);
  const char* cursor = extensions;
  while (*cursor)
  {
    while (*cursor == ' ') ++cursor;
    const char* end = std::strchr(cursor, ' ');
    const size_t length = end ? static_cast<size_t>(end - cursor) : std::strlen(cursor);
    if (length == wantedLength && std::strncmp(cursor, wanted, wantedLength) == 0) return true;
    if (!end) break;
    cursor = end + 1;
  }
  return false;
}

bool CheckError(const char* stage)
{
  const GLenum error = glGetError();
  if (error == GL_NO_ERROR) return true;
  std::fprintf(stderr, "[POC] %s: GL error 0x%04x\n", stage, static_cast<unsigned>(error));
  return false;
}

void PrintCapabilities()
{
  const char* version = reinterpret_cast<const char*>(glGetString(GL_VERSION));
  const char* shading = reinterpret_cast<const char*>(glGetString(GL_SHADING_LANGUAGE_VERSION));
  const char* vendor = reinterpret_cast<const char*>(glGetString(GL_VENDOR));
  const char* renderer = reinterpret_cast<const char*>(glGetString(GL_RENDERER));
  const char* extensions = reinterpret_cast<const char*>(glGetString(GL_EXTENSIONS));

  std::fprintf(stderr, "[POC] GL_VERSION: %s\n", version ? version : "<null>");
  std::fprintf(stderr, "[POC] GLSL: %s\n", shading ? shading : "<null>");
  std::fprintf(stderr, "[POC] GL_VENDOR: %s\n", vendor ? vendor : "<null>");
  std::fprintf(stderr, "[POC] GL_RENDERER: %s\n", renderer ? renderer : "<null>");
  std::fprintf(stderr, "[POC] NPOT: %s\n", HasExtension(extensions, "GL_OES_texture_npot") ? "yes" : "no");
  std::fprintf(stderr, "[POC] FLOAT: %s\n", HasExtension(extensions, "GL_OES_texture_float") ? "yes" : "no");
  std::fprintf(stderr, "[POC] HALF_FLOAT: %s\n", HasExtension(extensions, "GL_OES_texture_half_float") ? "yes" : "no");
  std::fprintf(stderr, "[POC] HALF_FLOAT_COLOR: %s\n", HasExtension(extensions, "GL_EXT_color_buffer_half_float") ? "yes" : "no");
  std::fprintf(stderr, "[POC] FBO_MIPMAP: %s\n", HasExtension(extensions, "GL_OES_fbo_render_mipmap") ? "yes" : "no");
  std::fprintf(stderr, "[POC] PIGLET_SHADER_BINARY: %s\n", HasExtension(extensions, "GL_SCE_piglet_shader_binary") ? "yes" : "no");
}

bool TestNpot()
{
  GLuint texture = 0;
  glGenTextures(1, &texture);
  glBindTexture(GL_TEXTURE_2D, texture);
  const unsigned char pixels[3 * 5 * 4] = {};
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 3, 5, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
  const bool ok = CheckError("NPOT texture");
  glDeleteTextures(1, &texture);
  return ok;
}

bool TestFbo()
{
  GLuint texture = 0, fbo = 0;
  glGenTextures(1, &texture);
  glBindTexture(GL_TEXTURE_2D, texture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1280, 720, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
  glGenFramebuffers(1, &fbo);
  glBindFramebuffer(GL_FRAMEBUFFER, fbo);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
  const GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
  const bool ok = status == GL_FRAMEBUFFER_COMPLETE && CheckError("FBO");
  std::fprintf(stderr, "[POC] FBO status: 0x%04x (%s)\n", static_cast<unsigned>(status), ok ? "PASS" : "FAIL");
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  glDeleteFramebuffers(1, &fbo);
  glDeleteTextures(1, &texture);
  return ok;
}

bool TestFloatTexture()
{
  const char* ext = reinterpret_cast<const char*>(glGetString(GL_EXTENSIONS));
  if (!HasExtension(ext, "GL_OES_texture_float"))
  {
    std::fprintf(stderr, "[POC] Float texture: SKIP (extension absent)\n");
    return true;
  }
  GLuint texture = 0;
  glGenTextures(1, &texture);
  glBindTexture(GL_TEXTURE_2D, texture);
  const GLfloat pixels[4] = {1.0f, 0.5f, 0.25f, 1.0f};
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_FLOAT, pixels);
  const bool ok = CheckError("float texture");
  std::fprintf(stderr, "[POC] Float texture: %s\n", ok ? "PASS" : "FAIL");
  glDeleteTextures(1, &texture);
  return ok;
}
}

int main()
{
  static nik::PigletApplication& app = nik::GetPigletApplication();
  if (!app.Init())
  {
    std::fprintf(stderr, "[POC] PigletApplication::Init failed\n");
    return 1;
  }

  PrintCapabilities();
  const bool npot = TestNpot();
  const bool fbo = TestFbo();
  const bool floating = TestFloatTexture();
  std::fprintf(stderr, "[POC] RESULT NPOT=%s FBO=%s FLOAT=%s\n",
               npot ? "PASS" : "FAIL", fbo ? "PASS" : "FAIL", floating ? "PASS" : "FAIL");

  while (app.Logic())
    app.Render();
  return 0;
}
