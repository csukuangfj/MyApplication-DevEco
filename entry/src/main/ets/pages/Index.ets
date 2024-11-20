import {add} from "library";

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  copyRawFileToSandbox() {
    // see https://blog.csdn.net/weixin_44640245/article/details/142634846
    // https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/rawfile-guidelines-V5
    let uint8Array: Uint8Array = getContext().resourceManager.getRawFileContentSync('0.wav');
    console.log(`number of bytes: ${uint8Array.length}`);

  }

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
          .onClick(()=>{
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