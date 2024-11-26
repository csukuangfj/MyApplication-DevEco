import {add, readWave, readRawFile,
  VadConfig,
  SileroVadConfig,
  CircularBuffer,
  Vad,
  OfflineRecognizerConfig,
  OfflineRecognizer,
  OnlineRecognizerConfig,
  OnlineRecognizer,
} from "library";
import {fileIo} from '@kit.CoreFileKit';
import { buffer } from '@kit.ArkTS';
import File from '@system.file';

import worker from '@ohos.worker';

let workerInstance: worker.ThreadWorker = new worker.ThreadWorker('entry/ets/workers/StreamingAsrWorker.ets', {
  name: 'Streaming ASR Worker'
});


@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  copyRawFileToSandbox(src: string, dst: string) {
    // see https://blog.csdn.net/weixin_44640245/article/details/142634846
    // https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/rawfile-guidelines-V5
    let uint8Array: Uint8Array = getContext().resourceManager.getRawFileContentSync(src);
    console.log(`number of bytes: ${uint8Array.length}`);

    let sandboxPath: string = getContext().getApplicationContext().filesDir;
    let filepath = sandboxPath + `/${dst}`;
    const fp = fileIo.openSync(filepath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    let n = fileIo.writeSync(fp.fd, buffer.from(uint8Array).buffer)
    fileIo.close(fp.fd);
    console.log(`wrote ${n} bytes to ${filepath}`);
  }

  testVad() {
    let mgr = getContext().resourceManager;
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
    const vad = new Vad(config, bufferSizeInSeconds, mgr);

    let sandboxPath: string = getContext().getApplicationContext().filesDir;
    let filepath = sandboxPath + "/0.wav";
    let wave = readWave(filepath, false);
    console.log(`sample rate ${wave.sampleRate}`);
    console.log(`samples length ${wave.samples.length}`);
    const windowSize = vad.config.sileroVad.windowSize;
    for (let i = 0; i < wave.samples.length; i+= windowSize) {
      const thisWindow = wave.samples.subarray(i, i + windowSize)
      vad.acceptWaveform(thisWindow);
      while (!vad.isEmpty()) {
        const segment = vad.front();
        const _startTime = (segment.start / wave.sampleRate);
        const _endTime = _startTime + segment.samples.length / wave.sampleRate;

        const startTime = _startTime.toFixed(2);
        const endTime = _endTime.toFixed(2);
        console.log(`${startTime} -- ${endTime}`);

        vad.pop();
      }
    }
  }

  testCircularBuffer() {
    const buffer = new CircularBuffer(5);
    console.log(`buffer size: ${buffer.size()}`);
    console.log(`buffer head: ${buffer.head()}`);
    buffer.push(Float32Array.from([0, 10, 20]));
    console.log(`buffer size: ${buffer.size()}`);
    console.log(`buffer head: ${buffer.head()}`);
    console.log(`buffer get: ${buffer.get(0, 1)}`);
    console.log(`buffer get: ${buffer.get(0, 2)}`);
    buffer.push(Float32Array.from([30, 40, 50, 60]));
    console.log(`buffer size: ${buffer.size()}`);
    console.log(`buffer head: ${buffer.head()}`);
    buffer.pop(4);
    console.log(`buffer get: ${buffer.get(buffer.head(), 2)}`);
    buffer.pop(1);
    console.log(`buffer size: ${buffer.size()}`);
    console.log(`buffer head: ${buffer.head()}`);
    console.log(`buffer get: ${buffer.get(buffer.head(), 2)}`);
    buffer.pop(2);
    buffer.push(Float32Array.from([100, 200, 300, 400, 500]));
    console.log(`buffer size: ${buffer.size()}`);
    console.log(`buffer head: ${buffer.head()}`);

    buffer.pop(4);
    console.log(`buffer size: ${buffer.size()}`);
    console.log(`buffer head: ${buffer.head()}`);

    buffer.push(Float32Array.from([600, 700]));
    console.log(`buffer size: ${buffer.size()}`);
    console.log(`buffer head: ${buffer.head()}`);
    console.log(`buffer get: ${buffer.get(buffer.head(), 3)}`);

    buffer.pop(3);
    console.log(`buffer size: ${buffer.size()}`);
    console.log(`buffer head: ${buffer.head()}`);

    buffer.reset();
    console.log(`buffer size: ${buffer.size()}`);
    console.log(`buffer head: ${buffer.head()}`);
  }

  testNonStreamingAsr() {
    let mgr = getContext().resourceManager;
    const config = new OfflineRecognizerConfig();
    config.modelConfig.whisper.encoder = "sherpa-onnx-whisper-tiny.en/tiny.en-encoder.int8.onnx";
    config.modelConfig.whisper.decoder = "sherpa-onnx-whisper-tiny.en/tiny.en-decoder.int8.onnx";
    config.modelConfig.tokens = "sherpa-onnx-whisper-tiny.en/tiny.en-tokens.txt";
    config.modelConfig.debug = true;
    const recognizer = new OfflineRecognizer(config, mgr)

    const sandboxPath: string = getContext().getApplicationContext().filesDir;
    const filepath = sandboxPath + "/en.wav";
    const wave = readWave(filepath, false);
    console.log(`sample rate ${wave.sampleRate}`);
    console.log(`samples length ${wave.samples.length}`);

    console.log('creating stream');
    const stream = recognizer.createStream();
    console.log('accept waveform');
    stream.acceptWaveform({samples: wave.samples, sampleRate: wave.sampleRate});
    console.log('decode');
    recognizer.decode(stream);
    console.log('get result');
    const result = recognizer.getResult(stream);
    console.log(`result is ${result.json}`);
  }

  testStreamingAsr() {
    let mgr = getContext().resourceManager;
    let context = getContext()
    const sandboxPath: string = getContext().getApplicationContext().filesDir;
    console.log(`here sandboxpath: ${sandboxPath}`);
    workerInstance.postMessage({msg: 'start', mgr, sandboxPath, context});
    return

  }

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
          .onClick(()=>{

            this.copyRawFileToSandbox('0.wav', '0.wav');
            this.copyRawFileToSandbox('en.wav', 'en.wav');
            this.copyRawFileToSandbox('zh.wav', 'zh.wav');


            this.testStreamingAsr();
            // this.testNonStreamingAsr();
            // this.testVad();
            // this.testCircularBuffer();
          })
      }
      .width('100%')
    }
    .height('100%')
  }
}