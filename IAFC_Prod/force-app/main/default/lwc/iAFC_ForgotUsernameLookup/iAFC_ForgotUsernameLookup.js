/* eslint-disable no-alert */
import { LightningElement,  track, api } from 'lwc';
import userLoginLookup from '@salesforce/apex/IAFC_UserSearch.userLoginLookup';
//import { refreshApex } from '@salesforce/apex'; 
export default class IAFC_ForgotUsernameLookup extends LightningElement {
    @api showDebug = false;
    columns = [
        {label: 'Name', fieldName: 'LastName', type: 'text'},  
        {label: 'Title', fieldName: 'Title', type: 'text'},
        {label: 'Username Hint', fieldName: 'Email', type: 'text'}
   ];
    
    @track error;
    @api last = '';
    @api postal = ''; 
    @track users = [];
    @track searching = false;
    @track searchResult;

    handleLastChange(e) {
        this.last = e.target.value;
    }
    handlePostalChange(e) {
        this.postal = e.target.value;
    }
    //get last() { return '${this.last}'; }
    //get postal() { return '${this.postal}'; }
    /*
    @wire(userLoginLookup, { last: '$last', postal : '$postal' }) 
    userFetch(result){
        this.searchResult = result;
        if(result.data){
            this.users = result.data;
            this.error = undefined;
        }
        else if (result.error) {
            this.error = result.error;
            this.users = undefined;
        }
    }
    */
    handleSearch(){
        this.searching = true;
        userLoginLookup({  last: this.last, postal : this.postal })
            .then(result =>{
                this.searching = false;
                this.users = result;
                //alert(JSON.stringify(result,null,4));
            }).catch(error => {
                this.error = error;
                //alert(error);
            }); 
    }

    get size(){ return this.users.length; }

    get debuginfo(){

        return JSON.stringify(
            {
                users: this.users,
                last: this.last,
                postal: this.postal,
                count: this.users.length
            },null,4);
    }

    handleChange(event) {
        this.greeting = event.target.value;
    }

    /*
    handleKeyChange(event) {
        
            // Debouncing this method: Do not update the reactive property as long as this function is
            // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
            window.clearTimeout(this.delayTimeout);
            const last = event.target.value;
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this.delayTimeout = setTimeout(() => {
                this.last = last;
                //this.postal = postal;
            }, 1000);  
    }
    */

    get hasData(){
        return this.users.length > 0;
    }
}