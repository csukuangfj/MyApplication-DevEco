export const add: (a: number, b: number) => number;

export const readWave: (filename: string, enableExternalBuffer: boolean = true) => {samples: Float32Array, sampleRate: number};
export const readRawFile: (mgr: object, filename: string) => void;
export const createCircularBuffer: (capacity: number) => number;
export const circularBufferPush: (handle: number, samples: Float32Array) => void;
export const circularBufferGet: (handle: number, index: number, n: number, enableExternalBuffer: boolean = true) => Float32Array;
export const circularBufferPop: (handle: number, n: number) => void;
export const circularBufferSize: (handle: number) => number;
export const circularBufferHead: (handle: number) => number;
export const circularBufferReset: (handle: number) => void;

export const createVoiceActivityDetector: (config: object, bufferSizeInSeconds: number, mgr?: object) => number;
export const voiceActivityDetectorAcceptWaveform: (handle: number, samples: Float32Array) => void;
export const voiceActivityDetectorIsEmpty: (handle: number) => boolean;
export const voiceActivityDetectorIsDetected: (handle: number) => boolean;
export const voiceActivityDetectorPop: (handle: number) => void;
export const voiceActivityDetectorClear: (handle: number) => void;
export const voiceActivityDetectorFront: (handle: number, enableExternalBuffer: boolean = true) => {samples: Float32Array, start: number};
export const voiceActivityDetectorReset: (handle: number) => void;
export const voiceActivityDetectorFlush: (handle: number) => void;
