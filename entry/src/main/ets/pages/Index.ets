import {
  readWave,
  VadConfig,
  SileroVadConfig,
  Vad,
} from "library";

import audio from '@ohos.multimedia.audio';
import { fileIo } from '@kit.CoreFileKit';
import { buffer } from '@kit.ArkTS';
import { picker } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

import worker, { MessageEvents } from '@ohos.worker';
import { LengthUnit } from '@kit.ArkUI';


@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  private controller: TabsController = new TabsController()
  private workerInstance?: worker.ThreadWorker
  private readonly scriptURL: string = 'entry/ets/workers/NonStreamingAsrWithVadWorker.ets'
  @State message: string = 'To be implemented';
  @State resultFromFile: string = '';
  @State progressForFile: number = 0;

  @State selectFileBtnEnabled: boolean = false;

  // microphone related
  private audioCapturer?: audio.AudioCapturer;

  initMicrophone() {
    const audioStreamInfo: audio.AudioStreamInfo = {
      // Please don't change the sample rate unless you know what you are doing.
      samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,

      // We support only a single channel
      channels: audio.AudioChannel.CHANNEL_1,

      // each sample should be normalized to the range [-1, 1]
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_F32LE,
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW,
    };

    const audioCapturerInfo: audio.AudioCapturerInfo = {
      source: audio.SourceType.SOURCE_TYPE_MIC,
      capturerFlags: 0,
    };

    const audioCapturerOptions: audio.AudioCapturerOptions = {
      streamInfo: audioStreamInfo,
      capturerInfo: audioCapturerInfo,
    };

    audio.createAudioCapturer(audioCapturerOptions, (err, capturer) => {
      if (err) {
        console.error(`Invoke createAudioCapturer failed, code is ${err.code}, message is ${err.message}`);
        return;
      }
      console.log(`audio capturer created!`);
      this.audioCapturer = capturer;
    })
  }

  aboutToAppear(): void {
    this.workerInstance = new worker.ThreadWorker(this.scriptURL, {
      name: 'NonStreaming ASR worker'
    });

    this.workerInstance.onmessage = (e: MessageEvents) => {
      const msgType = e.data['msgType'] as string;
      console.log(`received data ${msgType}`);

      if (msgType == 'init-non-streaming-asr-done') {
        this.selectFileBtnEnabled = true;
      }

      if (msgType == 'non-streaming-asr-vad-decode-done') {
        this.resultFromFile = e.data['text'] as string + '\n';
      }

      if (msgType == 'non-streaming-asr-vad-decode-partial') {
        if (this.resultFromFile == '') {
          this.resultFromFile = e.data['text'] as string;
        } else {
          this.resultFromFile += '\n\n' + e.data['text'] as string;
        }
      }

      if (msgType == 'non-streaming-asr-vad-decode-error') {
        this.resultFromFile = e.data['text'] as string;
      }

      if (msgType == 'non-streaming-asr-vad-decode-progress') {
        this.progressForFile = e.data['progress'] as number;

        this.selectFileBtnEnabled = this.progressForFile >= 100;
      }
    }

    const context = getContext();
    this.workerInstance.postMessage({ msgType: 'init-vad', context });
    this.workerInstance.postMessage({ msgType: 'init-non-streaming-asr', context });

    this.workerInstance.postMessage({ msgType: 'init-vad-mic', context });

    this.initMicrophone();
  }

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
    for (let i = 0; i < wave.samples.length; i += windowSize) {
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

  onPageShow(): void {
    console.log('on page show is called');
  }

  onPageHide(): void {
    console.log('on page hide is called');
  }

  onBackPress(): boolean | void {
    console.log('on back press is called');
  }

  @Builder
  TabBuilder(title: string, targetIndex: number, selectedImg: Resource, normalImg: Resource) {
    Column() {
      Image(this.currentIndex == targetIndex ? selectedImg : normalImg)
        .size({ width: 25, height: 25 })
      Text(title)
        .fontColor(this.currentIndex == targetIndex ? '#28bff1' : '#8a8a8a')
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = targetIndex;
      this.controller.changeIndex(this.currentIndex);
    })
  }

  build() {
    Column() {
      Tabs({ barPosition: BarPosition.End, controller: this.controller }) {
        TabContent() {
          Column({space: 10}) {
            Text('Next-gen Kaldi: VAD + ASR')
              .fontColor('#182431')
              .fontSize(25)
              .lineHeight(41)
              .fontWeight(500)

            Button('Select .wav 文件 (英文识别) ')
              .enabled(this.selectFileBtnEnabled)
              .fontSize(13)
              .width(296)
              .height(60)
              .onClick(() => {
                this.resultFromFile = '';
                this.progressForFile = 0;

                const documentSelectOptions = new picker.DocumentSelectOptions();
                documentSelectOptions.maxSelectNumber = 1;
                documentSelectOptions.fileSuffixFilters = ['.wav'];
                const documentViewPicker = new picker.DocumentViewPicker();
                documentViewPicker.select(documentSelectOptions).then((result: Array<string>) => {
                  console.log(`Result: ${result}`);

                  if (!result[0]) {
                    this.resultFromFile = 'Please select a file to decode';
                    this.selectFileBtnEnabled = true;
                    return;
                  }

                  if (this.workerInstance) {
                    this.workerInstance.postMessage({
                      msgType: 'non-streaming-asr-vad-decode',
                      filename: result[0],
                    });
                  } else {
                    console.log(`this worker instance is undefined ${this.workerInstance}`);
                  }
                }).catch((err: BusinessError) => {
                  console.error(`Failed to select file, code is ${err.code}, message is ${err.message}`);
                })
              })

            if (this.progressForFile > 0) {
              Row() {
                Progress({ value: 0, total: 100, type: ProgressType.Capsule })
                  .width('80%')
                  .height(20)
                  .value(this.progressForFile);

                  Text(`${this.progressForFile.toFixed(2)}%`).width('15%')
              }.width('100%').justifyContent(FlexAlign.Center)
            }

            TextArea({text: this.resultFromFile}).width('100%').lineSpacing({value: 10, unit: LengthUnit.VP});
          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Start)
        }.tabBar(this.TabBuilder('From file', 0, $r('app.media.icon_doc'), $r('app.media.icon_doc_default')))

        TabContent() {
          Column() {
            Text(this.message)
              .fontSize(50)
              .fontWeight(FontWeight.Bold)
              .onClick(() => {

                // this.copyRawFileToSandbox('0.wav', '0.wav');
                // this.copyRawFileToSandbox('en.wav', 'en.wav');
                // this.copyRawFileToSandbox('Obama.wav', 'Obama.wav');
/*
                if (this.workerInstance) {
                  const sandboxPath: string = getContext().getApplicationContext().filesDir;
                  const filename = sandboxPath + `/en.wav`;
                  this.workerInstance.postMessage({
                    msgType: 'non-streaming-asr-vad-decode',
                    filename: filename,
                  });
                }
*/

                // this.testStreamingAsr();
                // this.testNonStreamingAsr();
                // this.testVad();
                // this.testCircularBuffer();
              })
          }
        }
        .tabBar(this.TabBuilder('From mic', 1, $r('app.media.ic_public_input_voice'),
          $r('app.media.ic_public_input_voice_default')))

        TabContent() {
          Column() {
            Text("Everything is open-sourced");
            Divider();
            Text("It runs locally, without accessing the network");
            Divider();
            Text("See also https://github.com/k2-fsa/sherpa-onnx");
            Divider();
            Text("and https://k2-fsa.github.io/sherpa/social-groups.html");
          }
        }
        .tabBar(this.TabBuilder('Help', 2, $r('app.media.info_circle'),
          $r('app.media.info_circle_default')))
      }.scrollable(false)
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
  }
}