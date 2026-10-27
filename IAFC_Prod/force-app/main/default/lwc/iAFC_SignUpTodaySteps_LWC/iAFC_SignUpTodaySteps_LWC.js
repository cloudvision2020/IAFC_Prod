/* eslint-disable no-useless-escape */
/* eslint-disable @lwc/lwc/no-inner-html */
import { LightningElement, api  } from 'lwc';  
export default class IAFC_SignUpTodaySteps_LWC extends LightningElement {
 

    @api input; 
    
    default = {
        "alert1": "",
        "alert2": "",
        "title": "Ready to Join?",
        "button_text": "Membership Prices",
        "button_link_target": "https://www.iafc.org/membershipDues",
        "marketing_text_1": "Choose your member type below. Then join online, submit an application or <a href=\"mailto:membership@iafc.org\">request an invoice<\/a>. Interested in adding your entire department at once? Choose <a href=\"https://www.iafc.org/membership/group-membership\" target=\"_blank\">group membership<\/a>. Do you serve a community of less than 10,000? Consider <a href=\"https://www.iafc.org/membership/departmental\" target=\"_blank\">small community membership.<\/a>",
        "product_boxes": [
            {
                "product_title": "FULL",
                "product_price": "$195",
                "product_sale_price": "",
                "price_note": "+ division dues",
                "button_text": "Join Online",
                "button_disabled": false,
                "button_link": "https://community.iafc.org/s/join?utm_source=Helix&utm_medium=JoinBtn-Full&utm_campaign=Web",
               // "application_link": "https://www.iafc.org/docs/default-source/1mbrship/mbrship_applic_full.pdf?utm_source=Helix&utm_medium=JoinText-Full&utm_campaign=Web",
                //"application_link_text" : "Application", //
                "product_description": "Perfect membership for all chiefs and all chief officers.",
                "container_style": "background-color:#fff;; border-right: 2px solid #f3f3f3",
                "container_class": "slds-col slds-large-size_3-of-12 slds-medium-size_6-of-12 slds-small-size_12-of-12 slds-var-p-around_small"
            },
            {
                "product_title": "BASIC",
                "product_price": "$103",
                "product_sale_price": "",
                "price_note": "+ division dues",
                "button_text": "Join Online",
                "button_disabled": false,
                "button_link": "https://community.iafc.org/s/join?utm_source=Helix&utm_medium=JoinBtn-Basic&utm_campaign=Web",
                //"application_link": "https://www.iafc.org/docs/default-source/1mbrship/mbrship_applic_basic.pdf?utm_source=Helix&utm_medium=JoinText-Basic&utm_campaign=Web",
                //"application_link_text" : "Application", //
                "product_description": "Perfect for all chief officers (2 or 3 bugles).",
                "container_style": "background-color:#fff;; border-right: 2px solid #f3f3f3",
                "container_class": "slds-col slds-large-size_3-of-12 slds-medium-size_6-of-12 slds-small-size_12-of-12 slds-var-p-around_small"
            },
            {
                "product_title": "AFFILIATE",
                "product_price": "$77.50",
                "product_sale_price": "",
                "price_note": "+ division dues",
                "button_text": "Join Online",
                "button_disabled": false,
                "button_link": "https://community.iafc.org/s/join?utm_source=Helix&utm_medium=JoinBtn-Affil&utm_campaign=Web",
               // "application_link": "https://www.iafc.org/docs/default-source/1mbrship/mbrship_applic_affiliate.pdf?utm_source=Helix&utm_medium=JoinText-Affil&utm_campaign=Web",
                //"application_link_text" : "Application",//
                "product_description": "For company officers, firefighters, paramedics and EMTs.",
                "container_style": "background-color:#fff;; border-right: 2px solid #f3f3f3",
                "container_class": "slds-col slds-large-size_3-of-12 slds-medium-size_6-of-12 slds-small-size_12-of-12 slds-var-p-around_small"
            },
            {
                "product_title": "ASSOCIATE",
                "product_price": "$195",
                "product_sale_price": "",
                "price_note": "+ division dues",
                "button_text": "Join Online",
                "button_disabled": false,
                "button_link": "https://community.iafc.org/s/join?utm_source=Helix&utm_medium=JoinBtn-Assoc&utm_campaign=Web",
                //"application_link": "https://www.iafc.org/docs/default-source/1mbrship/mbrship_applic_associate.pdf?utm_source=Helix&utm_medium=JoinText-Assoc&utm_campaign=Web",
                //"application_link_text" : "Application", //
                "product_description": "For industry professionals, community officials and educators.",
                "container_style": "background-color:#fff;; border-right: 2px solid #f3f3f3",
                "container_class": "slds-col slds-large-size_3-of-12 slds-medium-size_6-of-12 slds-small-size_12-of-12 slds-var-p-around_small"
            },
            {
                "product_title": "SMALL COMMUNITY",
                "product_price": "$195",
                "product_sale_price": "",
                "price_note": "+ division dues",
                "button_text": "Join Online",
                "button_disabled": true,
                "button_link": "https://community.iafc.org/s/join?utm_source=Helix&utm_medium=JoinBtn-Assoc&utm_campaign=Web",
               // "application_link": "https://www.iafc.org/docs/default-source/1mbrship/mbrship_applic_associate.pdf?utm_source=Helix&utm_medium=JoinText-Assoc&utm_campaign=Web",
               // "application_link_text" : "Application",//
                "product_description": "For industry professionals, community officials and educators.",
                "container_style": "background-color:#fff;; border-top: 2px solid #f3f3f3",
                "container_class": "slds-col slds-large-size_6-of-12 slds-medium-size_12-of-12 slds-small-size_12-of-12 slds-var-p-around_small"
            }
        ]
    };
 
    // renderedCallback(){
    //     if(!this.loaded){
    //         const marketing = document.createElement('div'); 
    //         marketing.innerHTML('Hello');
    //         this.template.querySelector('.marketing_text_1').appendChild(marketing);
    //         this.loaded = true;
    //     }
    // }

    
    get config() {
        if(this.input){ 
          return JSON.parse(this.input); 
        }
    
      return this.default; 
    }
    

    get alert1(){
        if(this.config.alert1.length > 0){
            return this.config.alert1;
        }
        return null;
    }

    get alert2(){
        if(this.config.alert2.length > 0){
            return this.config.alert2;
        }
        return null;
    }

    get title(){
        if(this.config.title.length > 0){
            return this.config.title;
        }
        return "Ready to join?";
    }

    get marketing_text_1(){
        if(this.config.marketing_text_1.length > 0){ 
            return this.config.marketing_text_1;
        }
        return "Choose your member type below. Then join online, submit an application or <a href=\"mailto:membership@iafc.org\">request an invoice<\/a>. Interested in adding your entire department at once? Choose <a href=\"https://www.iafc.org/membership/group-membership\" target=\"_blank\">group membership<\/a>. Do you serve a community of less than 10,000? Consider <a href=\"https://www.iafc.org/membership/departmental\" target=\"_blank\">small community membership.<\/a>";
    }

    get debug(){
        if(this.config){
            return JSON.stringify(this.config, null, 4);
        }
        return "no config";
    }
}