import { LightningElement, api } from "lwc";

export default class IAFC_AppLauncherLWC extends LightningElement {
  @api input;

  get items() {
    if(this.input){
      return JSON.parse(this.input); 
  }

  return []; 
  }

  // constructor() {
  //   super();
  //   this.items.forEach(item=>{
  //     if(item.text.length > this.maxlen){  this.maxlen = item.text.length; }
  //   });
  //   this.items.forEach(item=>{
  //     if(item.text.length < this.maxlen){
  //       for(let i=item.text.length; i < this.maxlen; i++){ item.text += ' '; }
  //     }
  //   });
  // }
}