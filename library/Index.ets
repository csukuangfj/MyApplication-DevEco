import { circularBufferGet,
  circularBufferHead,
  circularBufferPop, circularBufferPush,
  circularBufferReset,
  circularBufferSize,
  createCircularBuffer,
  createVoiceActivityDetector,
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
