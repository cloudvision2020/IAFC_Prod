import { LightningElement, track, wire, api } from 'lwc';
import getRSGUser from '@salesforce/apex/authenticationRSGController.getRSGUser'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class Sample extends NavigationMixin(LightningElement) {

    // Flexipage provides recordId and objectApiName
    @api recordId;
    @api objectApiName = 'Account';
    @track contactRecordId = null;
    @track contactdetails;

    handleSelectChange(event){    
        alert(event);
    }

    @wire(getRSGUser, {contactId : '$contactRecordId'}) 
    RSGUser ({ error, data }) {  
        if (data) {
            this.contactdetails = data;
            this.recordId = data.AccountId;
            
            if(!this.contactdetails.Account.RSG_Registration_Complete__c){
                this[NavigationMixin.Navigate]({
                    "type": "comm__namedPage",
                    "attributes": {
                        name: 'authentication__c'
                    },
                    state: {
                        isrsguser: 'false'
                    }
                });
            }
            if(this.contactdetails.Account.RSG_Registration_Complete__c && this.contactdetails.Account.RSG_Status__c == 'Active'){
                this[NavigationMixin.Navigate]({
                    "type": "comm__namedPage",
                    "attributes": {
                        name: 'Home'
                    }
                });
            }
            if(this.contactdetails.Account.RSG_Registration_Complete__c && this.contactdetails.Account.RSG_Status__c != 'Active'){
                this[NavigationMixin.Navigate]({
                    "type": "comm__namedPage",
                    "attributes": {
                        name: 'Pending_Approval__c'
                    }
                });
            }
            
        } else if (error) { 
            this.error = error;
        }
    }
}