import {add, readWave, readRawFile,
  VadConfig,
  SileroVadConfig,
  CircularBuffer,
  Vad,
} from "library";
import {fileIo} from '@kit.CoreFileKit';
import { buffer } from '@kit.ArkTS';
import File from '@system.file';



@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  copyRawFileToSandbox() {
    // see https://blog.csdn.net/weixin_44640245/article/details/142634846
    // https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/rawfile-guidelines-V5
    let uint8Array: Uint8Array = getContext().resourceManager.getRawFileContentSync('0.wav');
    console.log(`number of bytes: ${uint8Array.length}`);

    let sandboxPath: string = getContext().getApplicationContext().filesDir;
    let filepath = sandboxPath + "/0.wav";
    const fp = fileIo.openSync(filepath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    let n = fileIo.writeSync(fp.fd, buffer.from(uint8Array).buffer)
    fileIo.close(fp.fd);
    console.log(`wrote ${n} bytes to ${filepath}`);


  }

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
          .onClick(()=>{
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
            this.copyRawFileToSandbox()

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
/*
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

            console.log(`number of threads ${config.numThreads}`);
*/
            let number = add(2, 3);
            console.log(`number is ${number}`)
            this.copyRawFileToSandbox();
          })
      }
      .width('100%')
    }
    .height('100%')
  }
}