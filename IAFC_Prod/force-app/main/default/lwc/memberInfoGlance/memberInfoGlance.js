import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi'; 
import Id from '@salesforce/user/Id';  
//import USERNAME_FIELD from '@salesforce/schema/User.Username';
//import CONTACTID_FIELD from '@salesforce/schema/User.ContactId';

const userfields = [
    'User.Username'
    ,'User.ContactId'
];

const contactfields = [ 
     'Contact.Name'
    ,'Contact.Title'
    ,'Contact.Phone'
    ,'Contact.Email'
    ,'Contact.Membership_Expiration__c'
    ,'Contact.Original_Join_Date__c'
    ,'Contact.Rejoin_Date__c'
    ,'Contact.Has_Small_Community_Membership__c'
    ,'Contact.Has_Group_Membership__c'
    ,'Contact.Account.Name'
    ,'Contact.Division__c'
    ,'Contact.Sections__c'
    ,'Contact.iMIS_Legacy_Id__c'
]

export default class MemberInfoGlance extends LightningElement {
    userId = Id;   

    @wire(getRecord, { recordId: '$userId', fields: userfields })
    user; 
    
    @wire(getRecord, { recordId: '$user.data.fields.ContactId.value', fields: contactfields })
    contact;

  
    get membershipExpiration() {
        return this.contact.data.fields.Membership_Expiration__c.displayValue;
    }

    get originalJoinDate() {
        return this.contact.data.fields.Original_Join_Date__c.displayValue;
    }

    get division() {
        return this.contact.data.fields.Division__c.value;
    }

    get sections() {
        return this.contact.data.fields.Sections__c.value;
    }

    get iMISLegacyId() {
        return this.contact.data.fields.iMIS_Legacy_Id__c.value;
    }

    get debugcontact() { 
        //this.contact = this.user.data.fields.Contact.value;
        return JSON.stringify(this.contact,null,4);
    }

    get debuguser() {
        return JSON.stringify(this.user,null,4);
    }

    constructor(){
        super(); 
    }
}