import { LightningElement, track, wire, api } from 'lwc';
import getRSGUser from '@salesforce/apex/authenticationRSGController.getRSGUser'; 
import updateContact from '@salesforce/apex/authenticationRSGController.updateContact'; 
import updateEmail from '@salesforce/apex/authenticationRSGController.updateEmail';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import Header_Text from '@salesforce/label/c.Header_Text';

export default class AuthenticationRSG extends NavigationMixin(LightningElement) {

    label = {
        Header_Text
    };

    // Flexipage provides recordId and objectApiName
    @api recordId;
    @api isrsguser = 'true';
    @api objectApiName = 'Account';
    @track contactRecordId = null;
    @track contactdetails;
    @track showSpinner = false;
    @track isEmailSent = false;

    connectedCallback(){
        let params = new URLSearchParams(document.location.search);
        this.isrsguser = params.get("isrsguser");
        
    }   
    handleSelectChange(event){    
        alert(event);
    }

    handleLoad(event){
        let inputFields = this.template.querySelectorAll('lightning-input-field');
        inputFields.forEach(inputField => {
            inputField.reportValidity();
        });
    }

    @wire(getRSGUser, {contactId : '$contactRecordId'}) 
    RSGUser ({ error, data }) {  
        if (data) {
            this.contactdetails = data;
            this.recordId = data.AccountId;
            this.contactRecordId = data.Id;
            this.isEmailSent =  data.Is_Email__c;
            if(this.contactdetails.Account.RSG_Registration_Complete__c && this.isrsguser != null ){
                if(this.contactdetails.Account.RSG_Status__c == 'Active'){
                    this[NavigationMixin.Navigate]({
                        "type": "comm__namedPage",
                        "attributes": {
                            name: 'Home'
                        }
                    });
                }
              
                if(this.contactdetails.Account.RSG_Status__c != 'Active'){
                    this[NavigationMixin.Navigate]({
                        "type": "comm__namedPage",
                        "attributes": {
                            name: 'Pending_Approval__c'
                        }
                    });
                }
            }
        } else if (error) { 
            this.error = error;
        }
    }


    handleSuccess(event){  
        this.showSpinner = true;
        updateContact({contactId : this.contactRecordId})
        .then((result) => {
            if(result){
                this.showSpinner = false;
                if(result.RSG_Registration_Complete__c){
                    const evt = new ShowToastEvent({
                        title: 'Success',
                        message: 'Operation successful!',
                        variant: 'success',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                    //if(this.isrsguser == 'false'){
                        window.location.reload();        
                    //}
                }
            }
        })    
    }

    closeCountModalFromChild(event) {
        this.isEmailSent = true;
        updateEmail({contactId : this.contactRecordId})
        .then((result) => {
            
        })   
    }
}