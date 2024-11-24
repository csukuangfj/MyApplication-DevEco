// scripts/node-addon-api/src/wave-reader.cc
//
// Copyright (c)  2024  Xiaomi Corporation

#include <algorithm>
#include <sstream>

#include "napi.h"  // NOLINT
#include "sherpa-onnx/c-api/c-api.h"
#include <rawfile/raw_file_manager.h>


#include "hilog/log.h"

#undef LOG_DOMAIN 
#undef LOG_TAG 

// https://gitee.com/openharmony/docs/blob/145a084f0b742e4325915e32f8184817927d1251/en/contribute/OpenHarmony-Log-guide.md#hilog-api-usage-specifications
#define LOG_DOMAIN 0x6666
#define LOG_TAG "sherpa_onnx" 

static Napi::Object ReadWaveWrapper(const Napi::CallbackInfo &info) {
  // 11-22 03:17:27.244   26876-26876   A03200/sherpa_onnx              com.examp...lication  E     int 10 str:hello, float 3.14.  
  OH_LOG_DEBUG(LOG_APP, "int %{public}d str:%{public}s, float %{public}3.2f.", 10, "hello", 3.14);
  OH_LOG_INFO(LOG_APP, "int %{public}d str:%{public}s, float %{public}3.2f.", 10, "hello", 3.14);
  OH_LOG_WARN(LOG_APP, "int %{public}d str:%{public}s, float %{public}3.2f.", 10, "hello", 3.14);
  OH_LOG_ERROR(LOG_APP, "int %{public}d str:%{public}s, float %{public}3.2f.", 10, "hello", 3.14);
  OH_LOG_FATAL(LOG_APP, "int %{public}d str:%{public}s, float %{public}3.2f.", 10, "hello", 3.14);

  Napi::Env env = info.Env();
  if (info.Length() > 2) {
    std::ostringstream os;
    os << "Expect only 2 arguments. Given: " << info.Length();

    Napi::TypeError::New(env, os.str()).ThrowAsJavaScriptException();

    return {};
  }

  if (!info[0].IsString()) {
    Napi::TypeError::New(env, "Argument 0 should be a string")
        .ThrowAsJavaScriptException();

    return {};
  }

  std::string filename = info[0].As<Napi::String>().Utf8Value();

  bool enable_external_buffer = true;
  if (info.Length() == 2) {
    if (info[1].IsBoolean()) {
      enable_external_buffer = info[1].As<Napi::Boolean>().Value();
    } else {
      Napi::TypeError::New(env, "Argument 1 should be a boolean")
          .ThrowAsJavaScriptException();

      return {};
    }
  }

  const SherpaOnnxWave *wave = SherpaOnnxReadWave(filename.c_str());
  if (!wave) {
    std::ostringstream os;
    os << "Failed to read '" << filename << "'";
    Napi::TypeError::New(env, os.str()).ThrowAsJavaScriptException();

    return {};
  }

  if (enable_external_buffer) {
    Napi::ArrayBuffer arrayBuffer = Napi::ArrayBuffer::New(
        env, const_cast<float *>(wave->samples),
        sizeof(float) * wave->num_samples,
        [](Napi::Env /*env*/, void * /*data*/, const SherpaOnnxWave *hint) {
          SherpaOnnxFreeWave(hint);
        },
        wave);
    Napi::Float32Array float32Array =
        Napi::Float32Array::New(env, wave->num_samples, arrayBuffer, 0);

    Napi::Object obj = Napi::Object::New(env);
    obj.Set(Napi::String::New(env, "samples"), float32Array);
    obj.Set(Napi::String::New(env, "sampleRate"), wave->sample_rate);
    return obj;
  } else {
    // don't use external buffer
    Napi::ArrayBuffer arrayBuffer =
        Napi::ArrayBuffer::New(env, sizeof(float) * wave->num_samples);

    Napi::Float32Array float32Array =
        Napi::Float32Array::New(env, wave->num_samples, arrayBuffer, 0);

    std::copy(wave->samples, wave->samples + wave->num_samples,
              float32Array.Data());

    Napi::Object obj = Napi::Object::New(env);
    obj.Set(Napi::String::New(env, "samples"), float32Array);
    obj.Set(Napi::String::New(env, "sampleRate"), wave->sample_rate);

    SherpaOnnxFreeWave(wave);

    return obj;
  }
}

// https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/rawfile-guidelines-V5
static void ReadRawFile(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
    
  if (info.Length() != 2) {
    std::ostringstream os;
    os << "Expect only 2 arguments. Given: " << info.Length();

    Napi::TypeError::New(env, os.str()).ThrowAsJavaScriptException();
        
        
    return ;
  }
    
  std::unique_ptr<NativeResourceManager, decltype(&OH_ResourceManager_ReleaseNativeResourceManager)> mgr (OH_ResourceManager_InitNativeResourceManager(env, info[0]), &OH_ResourceManager_ReleaseNativeResourceManager);
    
  if (!info[1].IsString()) {
    Napi::TypeError::New(env, "Argument 1 should be a string")
        .ThrowAsJavaScriptException();

    return ;
  }
    
  std::string filename = info[1].As<Napi::String>().Utf8Value();
  OH_LOG_DEBUG(LOG_APP, "read rawfile %{public}s", filename.c_str());
    
  std::unique_ptr<RawFile, decltype(&OH_ResourceManager_CloseRawFile)> fp(OH_ResourceManager_OpenRawFile(mgr.get(), filename.c_str()), OH_ResourceManager_CloseRawFile);
  if (!fp) {
    OH_LOG_ERROR(LOG_APP, "read raw file: %{public}s failed", filename.c_str());
    return;
  } 
    
  long len = OH_ResourceManager_GetRawFileSize(fp.get());
  std::vector<int8_t> data(len);
  int n = OH_ResourceManager_ReadRawFile(fp.get(), data.data(), len);
  if (n != len) {
    OH_LOG_ERROR(LOG_APP, "read raw file: %{public}s failed. %{public}d read, expected: %{public}d",
        filename.c_str(), n, (int32_t)len);
    return;
  }
    OH_LOG_DEBUG(LOG_APP, "read %{public}d bytes",(int)data.size());
    for (int i = 0; i < 10; ++i) {
        OH_LOG_DEBUG(LOG_APP, "%{public}d: %{public}02x",i, (int)data[i]);
    }
}

void InitWaveReader(Napi::Env env, Napi::Object exports) {
  exports.Set(Napi::String::New(env, "readWave"),
              Napi::Function::New(env, ReadWaveWrapper));
    
  exports.Set(Napi::String::New(env, "readRawFile"),
              Napi::Function::New(env, ReadRawFile));
}
