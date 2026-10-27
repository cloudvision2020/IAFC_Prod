import { LightningElement } from 'lwc';
export default class Technologycouncil extends LightningElement {
    connectedCallback(){
         const url='https://www.iafc.org/tsi';
         window.open(url, '_blank');
        //window.location.href ='https://www.iafc.org/tsi';
    }
            
        
    

}