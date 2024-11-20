import {add} from "library";

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
          .onClick(()=>{
            let number = add(2, 3);
            console.log(`number is ${number}`)
          })
      }
      .width('100%')
    }
    .height('100%')
  }
}