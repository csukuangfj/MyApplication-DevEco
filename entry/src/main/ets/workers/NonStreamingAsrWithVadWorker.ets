import { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS';
import {
  OfflineRecognizer,
  OfflineRecognizerConfig,
  OfflineStream,
  readWave,
  readWaveFromBinary,
  SileroVadConfig,
  Vad,
  VadConfig
} from 'library';
import { Context } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

const workerPort: ThreadWorkerGlobalScope = worker.workerPort;

let recognizer: OfflineRecognizer;
let vad: Vad; // vad for decoding files
let vadMic: Vad; // vad for decoding samples from the micrphone

function initVad(context: Context): Vad {
  let mgr = context.resourceManager;
  const config = new VadConfig(
    new SileroVadConfig(
      'silero_vad.onnx',
      0.5,
      0.25,
      0.5,
      512,
    ),
    16000,
    true,
    1,
  );

  const bufferSizeInSeconds = 60;
  return new Vad(config, bufferSizeInSeconds, mgr);
}

function initNonStreamingAsr(context: Context): OfflineRecognizer {
  let mgr = context.resourceManager;
  const config = new OfflineRecognizerConfig();
  config.modelConfig.whisper.encoder = "sherpa-onnx-whisper-tiny.en/tiny.en-encoder.int8.onnx";
  config.modelConfig.whisper.decoder = "sherpa-onnx-whisper-tiny.en/tiny.en-decoder.int8.onnx";
  config.modelConfig.tokens = "sherpa-onnx-whisper-tiny.en/tiny.en-tokens.txt";
  config.modelConfig.debug = true;
  return new OfflineRecognizer(config, mgr)
}

function decode(filename: string): string {
  vad.reset();

  const fp = fileIo.openSync(filename);
  const stat = fileIo.statSync(fp.fd);
  const arrayBuffer = new ArrayBuffer(stat.size);
  fileIo.readSync(fp.fd, arrayBuffer);
  const data = new Uint8Array(arrayBuffer);

  const wave = readWaveFromBinary(data);

  console.log(`sample rate ${wave.sampleRate}`);
  console.log(`samples length ${wave.samples.length}`);
  const resultList: string[] = [];

  const windowSize = vad.config.sileroVad.windowSize;
  for (let i = 0; i < wave.samples.length; i += windowSize) {
    const thisWindow = wave.samples.subarray(i, i + windowSize)
    vad.acceptWaveform(thisWindow);
    if (i + windowSize >= wave.samples.length) {
      vad.flush();
    }
    while (!vad.isEmpty()) {
      const segment = vad.front();
      const _startTime = (segment.start / wave.sampleRate);
      const _endTime = _startTime + segment.samples.length / wave.sampleRate;

      if (_endTime - _startTime < 0.2) {
        vad.pop();
        continue;
      }

      const startTime = _startTime.toFixed(2);
      const endTime = _endTime.toFixed(2);

      const progress = (segment.start + segment.samples.length) / wave.samples.length * 100;

      workerPort.postMessage({ 'msgType': 'non-streaming-asr-vad-decode-progress', progress });

      const stream = recognizer.createStream();
      stream.acceptWaveform({ samples: segment.samples, sampleRate: wave.sampleRate });
      recognizer.decode(stream);
      const result = recognizer.getResult(stream);

      const text = `${startTime} -- ${endTime} ${result.text}`
      resultList.push(text);
      console.log(`partial result ${text}`);

      workerPort.postMessage({ 'msgType': 'non-streaming-asr-vad-decode-partial', text});

      vad.pop();
    }
  }

  return resultList.join('\n\n');
}

/**
 * Defines the event handler to be called when the worker thread receives a message sent by the host thread.
 * The event handler is executed in the worker thread.
 *
 * @param e message data
 */
workerPort.onmessage = (e: MessageEvents) => {
  const msgType = e.data['msgType'] as string;
  console.log(`msg-type: ${msgType}`)
  if (msgType == 'init-vad' && !vad) {
    const context = e.data['context'] as Context;
    vad = initVad(context);
    console.log('init vad done');
    workerPort.postMessage({ 'msgType': 'init-vad-done' });
  }

  if (msgType == 'init-vad-mic' && !vadMic) {
    const context = e.data['context'] as Context;
    vadMic = initVad(context);
    console.log('init vad mic done');
    workerPort.postMessage({ 'msgType': 'init-vad-mic-done' });
  }

  if (msgType == 'init-non-streaming-asr' && !recognizer) {
    const context = e.data['context'] as Context;
    recognizer = initNonStreamingAsr(context);
    console.log('init non streaming ASR done');
    workerPort.postMessage({ 'msgType': 'init-non-streaming-asr-done' });
  }

  if (msgType == 'non-streaming-asr-vad-decode') {
    const filename = e.data['filename'] as string;
    console.log(`decoding ${filename}`);
    try {
      const text = decode(filename);
      workerPort.postMessage({ msgType: 'non-streaming-asr-vad-decode-done', text });
    } catch (e) {
      workerPort.postMessage({ msgType: 'non-streaming-asr-vad-decode-error', text: `Failed to decode ${filename}` });
    }

    workerPort.postMessage({ 'msgType': 'non-streaming-asr-vad-decode-progress', progress: 100 });
  }
}

/**
 * Defines the event handler to be called when the worker receives a message that cannot be deserialized.
 * The event handler is executed in the worker thread.
 *
 * @param e message data
 */
workerPort.onmessageerror = (e: MessageEvents) => {
}

/**
 * Defines the event handler to be called when an exception occurs during worker execution.
 * The event handler is executed in the worker thread.
 *
 * @param e error message
 */
workerPort.onerror = (e: ErrorEvent) => {
}
