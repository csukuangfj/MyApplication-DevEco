import { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS';
import { OnlineRecognizer, OnlineRecognizerConfig, readWave } from 'library';
import { resourceManager } from '@kit.LocalizationKit';

const workerPort: ThreadWorkerGlobalScope = worker.workerPort;

/**
 * Defines the event handler to be called when the worker thread receives a message sent by the host thread.
 * The event handler is executed in the worker thread.
 *
 * @param e message data
 */
workerPort.onmessage = (e: MessageEvents) => {
  console.log(`mgr: ${e.data['msg']}`);

  let context: Context = e.data['context'] as Context;
  let mgr = context.resourceManager;
  const config = new OnlineRecognizerConfig();
  config.modelConfig.transducer.encoder = "sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20/encoder-epoch-99-avg-1.int8.onnx";
  config.modelConfig.transducer.decoder = "sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20/decoder-epoch-99-avg-1.onnx";
  config.modelConfig.transducer.joiner = "sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20/joiner-epoch-99-avg-1.int8.onnx";
  config.modelConfig.tokens = "sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20/tokens.txt";
  config.modelConfig.debug = true;

  const recognizer = new OnlineRecognizer(config, mgr)

  const sandboxPath: string = e.data['sandboxPath'] as string;
  console.log(`sandboxpath: ${sandboxPath}`);
  const filepath = sandboxPath + "/zh.wav";
  const wave = readWave(filepath, false);
  console.log(`sample rate ${wave.sampleRate}`);
  console.log(`samples length ${wave.samples.length}`);

  console.log('creating stream');
  const stream = recognizer.createStream();
  console.log('accept waveform');
  stream.acceptWaveform({samples: wave.samples, sampleRate: wave.sampleRate});
  console.log('decode');
  while (recognizer.isReady(stream)) {
    recognizer.decode(stream);
  }
  console.log('get result');
  const result = recognizer.getResult(stream);
  console.log(`result is ${result.json}`);

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