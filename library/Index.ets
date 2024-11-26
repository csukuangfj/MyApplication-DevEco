import { JSON } from '@kit.ArkTS';

import {
  acceptWaveformOffline,
  circularBufferGet,
  circularBufferHead,
  circularBufferPop, circularBufferPush,
  circularBufferReset,
  circularBufferSize,
  createCircularBuffer,
  createOfflineRecognizer,
  createOfflineStream,
  createVoiceActivityDetector,
  decodeOfflineStream,
  getOfflineStreamResultAsJson,
  voiceActivityDetectorAcceptWaveform,
  voiceActivityDetectorClear,
  voiceActivityDetectorFlush,
  voiceActivityDetectorFront,
  voiceActivityDetectorIsDetected,
  voiceActivityDetectorIsEmpty,
  voiceActivityDetectorPop,
  voiceActivityDetectorReset,
} from "liblibrary.so";
export { MainPage } from './src/main/ets/components/MainPage';
export {add, readWave, readRawFile} from "liblibrary.so";


export class SileroVadConfig {
  public model: string;
  public threshold: number;
  public minSpeechDuration: number;
  public minSilenceDuration: number;
  public windowSize: number;

  public constructor(model: string, threshold: number, minSpeechDuration: number, minSilenceDuration: number, windowSize: number) {
    this.model = model;
    this.threshold = threshold;
    this.minSpeechDuration = minSpeechDuration;
    this.minSilenceDuration = minSilenceDuration;
    this.windowSize = windowSize;
  }
}

export class VadConfig {
  public sileroVad: SileroVadConfig;
  public sampleRate: number;
  public debug: boolean;
  public numThreads: number;

  public constructor(sileroVad: SileroVadConfig, sampleRate: number, debug: boolean, numThreads: number) {
    this.sileroVad = sileroVad;
    this.sampleRate = sampleRate;
    this.debug = debug;
    this.numThreads = numThreads;
  }
}
export class CircularBuffer {
  private handle: number;
  constructor(capacity: number) {
    this.handle = createCircularBuffer(capacity);
  }

  // samples is a float32 array
  push(samples: Float32Array) {
    console.log(`here samples: ${samples}`);
    circularBufferPush(this.handle, samples);
  }

  // return a float32 array
  get(startIndex: number, n: number, enableExternalBuffer: boolean = true) {
    return circularBufferGet(
      this.handle, startIndex, n, enableExternalBuffer);
  }

  pop(n: number) {
    return circularBufferPop(this.handle, n);
  }

  size(): number {
    return circularBufferSize(this.handle);
  }

  head(): number {
    return circularBufferHead(this.handle);
  }

  reset() {
    circularBufferReset(this.handle);
  }
}

export interface SpeechSegment {
  samples: Float32Array;
  start: number;
}

export class Vad {
  private handle: number;
  public config: VadConfig;
  constructor(config: VadConfig, bufferSizeInSeconds: number, mgr: object) {
    this.handle =
      createVoiceActivityDetector(config, bufferSizeInSeconds, mgr);
    this.config = config;
  }

  acceptWaveform(samples: Float32Array): void {
    voiceActivityDetectorAcceptWaveform(this.handle, samples);
  }

  isEmpty() : boolean{
    return voiceActivityDetectorIsEmpty(this.handle);
  }

  isDetected() : boolean{
    return voiceActivityDetectorIsDetected(this.handle);
  }

  pop() : void{
    voiceActivityDetectorPop(this.handle);
  }

  clear() : void{
    voiceActivityDetectorClear(this.handle);
  }

  front(enableExternalBuffer = true): SpeechSegment {
    return voiceActivityDetectorFront(this.handle, enableExternalBuffer);
  }

  reset() : void{
    voiceActivityDetectorReset(this.handle);
  }

  flush() : void{
    voiceActivityDetectorFlush(this.handle);
  }
}

export interface Samples {
  samples: Float32Array;
  sampleRate: number;
}

export class OfflineStream {
  public handle: number;
  constructor(handle: number) {
    this.handle = handle;
  }

  // obj is {samples: samples, sampleRate: sampleRate}
  // samples is a float32 array containing samples in the range [-1, 1]
  // sampleRate is a number
  acceptWaveform(obj: Samples) {
    acceptWaveformOffline(this.handle, obj)
  }
}

export class FeatureConfig {
 public sampleRate: number = 16000;;
 public featureDim: number = 80;
}

export class OfflineTransducerModelConfig {
  public encoder: string = '';
  public decoder: string = '';
  public joiner: string = '';
}

export class  OfflineParaformerModelConfig {
  public model: string = '';
}

export class OfflineNemoEncDecCtcModelConfig {
  public model: string = '';
}

export class OfflineWhisperModelConfig {
  public encoder: string = '';
  public decoder: string = '';
  public language: string = '';
  public task: string = 'transcribe';
  public tailPaddings: number = -1;
}

export class OfflineTdnnModelConfig {
  public model: string = '';
};

export class OfflineSenseVoiceModelConfig {
  public model: string = '';
  public language: string = '';
  public useItn: boolean = false;
};

export class OfflineMoonshineModelConfig {
  public preprocessor: string = '';
  public encoder: string = '';
  public uncachedDecoder: string = '';
  public cachedDecoder: string = '';
};

export class OfflineModelConfig {
  public transducer: OfflineTransducerModelConfig = new OfflineTransducerModelConfig();
  public paraformer: OfflineParaformerModelConfig = new OfflineParaformerModelConfig();
  public nemoCtc: OfflineNemoEncDecCtcModelConfig = new OfflineNemoEncDecCtcModelConfig();
  public whisper: OfflineWhisperModelConfig = new OfflineWhisperModelConfig();
  public tdnn: OfflineTdnnModelConfig = new OfflineTdnnModelConfig();

  public tokens: string = '';
  public numThreads: number = 1;
  public debug: boolean = false;
  public provider: string = "cpu";
  public modelType: string = '';
  public modelingUnit: string = "cjkchar";
  public bpeVocab: string = '';
  public telespeechCtc: string = '';
  public senseVoice: OfflineSenseVoiceModelConfig = new OfflineSenseVoiceModelConfig();
  public moonshine: OfflineMoonshineModelConfig = new OfflineMoonshineModelConfig();
};

export class OfflineLMConfig {
  public model: string = '';
  public scale: number = 1.0;
};

export class OfflineRecognizerConfig {
   public featConfig: FeatureConfig = new FeatureConfig();
   public modelConfig: OfflineModelConfig = new OfflineModelConfig();
   public lmConfig: OfflineLMConfig = new OfflineLMConfig();

  public decodingMethod: string = "greedy_search";
  public maxActivePaths: number = 4;

  public hotwordsFfile: string = '';

  public hotwordsScore: number = 1.5;
  public ruleFsts: string = '';
  public ruleFars: string = '';
  public blankPenalty: number = 0;
};

export class OfflineRecognizerResult {
  public text: string = '';
  public timestamps: number[] = [];
  public tokens: string[] = [];
  public json = '';
  public lang: string = '';
  public emotion: string = '';
  public event: string = '';
};


interface OfflineRecognizerResultJson {
  text: string;
  timestamps: number[];
  tokens: string[];
  lang: string;
  emotion: string;
  event: string;
}

export class OfflineRecognizer {
  public handle: number;
  public config: OfflineRecognizerConfig

  constructor(config: OfflineRecognizerConfig, mgr: object) {
    this.handle = createOfflineRecognizer(config, mgr);
    this.config = config
  }

  createStream() {
    const handle = createOfflineStream(this.handle);
    return new OfflineStream(handle);
  }

  decode(stream: OfflineStream) {
    decodeOfflineStream(this.handle, stream.handle);
  }

  getResult(stream: OfflineStream): OfflineRecognizerResult {
    const jsonStr = getOfflineStreamResultAsJson(stream.handle);

    let o = JSON.parse(jsonStr) as OfflineRecognizerResultJson;

    const r = new OfflineRecognizerResult()
    r.text = o.text
    r.timestamps = o.timestamps;
    r.tokens = o.tokens;
    r.json = jsonStr;
    r.lang = o.lang;
    r.emotion = o.emotion;
    r.event = o.event;

    return r;
  }
}
