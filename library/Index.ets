import { JSON } from '@kit.ArkTS';

import {
  acceptWaveformOffline,
  acceptWaveformOnline,
  circularBufferGet,
  circularBufferHead,
  circularBufferPop, circularBufferPush,
  circularBufferReset,
  circularBufferSize,
  createCircularBuffer,
  createOfflineRecognizer,
  createOfflineStream,
  createOnlineRecognizer,
  createOnlineStream,
  createVoiceActivityDetector,
  decodeOfflineStream,
  decodeOnlineStream,
  getOfflineStreamResultAsJson,
  getOnlineStreamResultAsJson,
  inputFinished,
  isEndpoint,
  isOnlineStreamReady,
  reset,
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
export {add, readWave, readRawFile, readWaveFromBinary} from "liblibrary.so";


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
  private handle: object;
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
  private handle: object;
  public config: VadConfig;

  constructor(config: VadConfig, bufferSizeInSeconds?: number, mgr?: object) {
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
  public handle: object;
  constructor(handle: object) {
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
  public handle: object;
  public config: OfflineRecognizerConfig;

  constructor(config: OfflineRecognizerConfig , mgr?: object) {
    this.handle = createOfflineRecognizer(config, mgr);
    this.config = config
  }

  createStream(): OfflineStream {
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

export class OnlineStream {
  public handle: object;
  constructor(handle: object) {
    this.handle = handle;
  }

  // obj is {samples: samples, sampleRate: sampleRate}
  // samples is a float32 array containing samples in the range [-1, 1]
  // sampleRate is a number
  acceptWaveform(obj: Samples) {
    acceptWaveformOnline(this.handle, obj)
  }

  inputFinished() {
    inputFinished(this.handle)
  }
}

export class OnlineTransducerModelConfig {
  public encoder: string = '';
  public decoder: string = '';
  public joiner: string = '';
};

export class OnlineParaformerModelConfig {
  public encoder: string = '';
  public decoder: string = '';
};

export class OnlineZipformer2CtcModelConfig {
  public model: string = '';
};

export class OnlineModelConfig {
  public transducer: OnlineTransducerModelConfig = new OnlineTransducerModelConfig();
  public paraformer: OnlineParaformerModelConfig = new OnlineParaformerModelConfig();
  public zipformer2_ctc: OnlineZipformer2CtcModelConfig = new OnlineZipformer2CtcModelConfig();
  public tokens: string = '';
  public numThreads: number = 1;
  public provider: string = "cpu";
  public debug: boolean = false;
  public modelType: string = '';
  public modelingUnit: string = "cjkchar";
  public bpeVocab: string = '';
};

export class OnlineCtcFstDecoderConfig {
  public graph: string = '';
  public maxActive: number = 3000;
};

export class OnlineRecognizerConfig {
  public featConfig: FeatureConfig = new FeatureConfig();
  public modelConfig: OnlineModelConfig = new OnlineModelConfig();

  public decodingMethod: string = "greedy_search";

  public maxActivePaths: number = 4;

  public enableEndpoint: boolean = false;

  public rule1MinTrailingSilence: number = 2.4;

  public rule2MinTrailingSilence: number = 1.2;

  public rule3MinUtteranceLength: number = 20;

  public hotwordsFile: string = '';

  public hotwordsScore: number = 1.5;

  public ctcFstDecoderConfig: OnlineCtcFstDecoderConfig = new OnlineCtcFstDecoderConfig();
  public ruleFsts: string = '';
  public ruleFars: string = '';
  public blankPenalty: number = 0;
};

interface OnlineRecognizerResultJson {
  text: string;
  timestamps: number[];
  tokens: string[];
}

export class OnlineRecognizerResult {
  public text: string = '';
  public tokens: string[] = [];
  public timestamps: number[] = [];
  public json: string = '';
};

export class OnlineRecognizer {
  public handle: object;
  public config: OnlineRecognizerConfig
  constructor(config: OnlineRecognizerConfig, mgr?: object) {
    this.handle = createOnlineRecognizer(config, mgr);
    this.config = config
  }

  createStream(): OnlineStream {
    const handle = createOnlineStream(this.handle);
    return new OnlineStream(handle);
  }

  isReady(stream: OnlineStream): boolean {
    return isOnlineStreamReady(this.handle, stream.handle);
  }

  decode(stream: OnlineStream) {
    decodeOnlineStream(this.handle, stream.handle);
  }

  isEndpoint(stream: OnlineStream): boolean {
    return isEndpoint(this.handle, stream.handle);
  }

  reset(stream: OnlineStream) {
    reset(this.handle, stream.handle);
  }

  getResult(stream: OnlineStream): OnlineRecognizerResult {
    const jsonStr =
      getOnlineStreamResultAsJson(this.handle, stream.handle);

    let o = JSON.parse(jsonStr) as OnlineRecognizerResultJson;

    const r = new OnlineRecognizerResult()
    r.text = o.text
    r.timestamps = o.timestamps;
    r.tokens = o.tokens;
    r.json = jsonStr;

    return r;
  }
}
