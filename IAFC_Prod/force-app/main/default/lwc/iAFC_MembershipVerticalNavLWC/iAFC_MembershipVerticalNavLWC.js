import { LightningElement, api, track } from 'lwc';

export default class IAFC_MembershipVerticalNavLWC extends LightningElement {

    @api input;
    @track menudata
 
    get items() {
        if(this.input){
            this.menudata = JSON.parse(this.input);
            
            this.menudata.forEach(section => {
                section.content.forEach(item => {
                    item.css = "slds-nav-vertical__item";
                    if(item.isActive === true){ item.css += " slds-is-active" } 
                    if(item.newWindow === true){ item.target += "_blank" } 
                });
            });

            return this.menudata;
        }
  
        return []; 
    }

/* DEFAULT SETUP

    [
        {
            "title": "Manage My Membership",
            "content": [
                {
                  "link": "/s/myprofile",
                  "text": "Update My Information", 
                  "isActive": true
                },
                {
                  "link": "/membership",
                  "text": "My Subscription",
                  "newWindow": true
                }, 
    
                {
                  "link": "https://www.iafc.org/divisions",
                  "text": "Contact My Division",
                  "newWindow": true
                },
                {
                  "link": "https://www.iafc.org/getinvolved",
                  "text": "Get Involved",
                  "newWindow": true
                },
                {
                  "link": "https://www.iafc.org/membership",
                  "text": "Contact Member Services",
                  "newWindow": true
                }
                
            ] 
        },
        {
            "title": "Tools and Resources",
            "content": [
                {
                  "link": "https://www.iafcacademy.org",
                  "text": "IAFC Acacdemy",
                  "newWindow": true
                },
                {
                  "link": "https://knowledge.iafc.org/home",
                  "text": "KnowlegeNet",
                  "newWindow": true
                },
                {
                  "link": "https://careers.iafc.org/",
                  "text": "Career Center",
                  "newWindow": true
                },
                {
                  "link": "https://www.iafc.org/conferences",
                  "text": "Conferences & Events",
                  "newWindow": true
                },
                {
                  "link": "http://www.blogtalkradio.com/ichiefs_podcasts",
                  "text": "Podcasts",
                  "newWindow": true
                },
                {
                  "link": "https://www.iafc.org/topics-and-tools/bugle-brief",
                  "text": "Bugle Brief",
                  "newWindow": true
                }			
            ] 
        }
    ]

*/








    /*
    handleSelect(event) {
        const selectedName = event.detail.name;

        
        if(selectedName === 'information'){
            window.location = '/s/memberhome';
        }
        else if(selectedName === 'subscription'){
            window.location = '/membership';
        }
        else if(selectedName === 'renew'){
            window.location = '/s/join';
        }
        else if(selectedName === 'get-involved'){
            window.open('http://www.iafc.org/getinvolved', '_blank');
        }
        else if(selectedName === 'contact'){
            window.open('https://www.iafc.org/membership', '_blank');
        }
        else if(selectedName === 'division'){
            window.open('https://www.iafc.org/divisions', '_blank');
        }
        else if(selectedName === 'password'){
            window.location = '/s/login/ForgotPassword';
        }
        else if(selectedName === 'academy'){
            window.open('https://www.iafcacademy.org','_blank');
        }
        else if(selectedName === 'knowledge'){
            window.open('https://knowledge.iafc.org/home', '_blank');
        }
        else if(selectedName === 'career'){
            window.open('http://www.careerwebsite.com/distrib/jobs/rss.cfm?code=eGHk9YrT5C9P3Dubzc4LauVfWgRn4XJP', '_blank');
        }
        else if(selectedName === 'conferences'){
            window.open('www.iafc.org/conferences', '_blank');
        }
        else if(selectedName === 'podcasts'){
            window.open('http://www.blogtalkradio.com/ichiefs_podcasts', '_blank');
        }
        else if(selectedName === 'bugle'){
            window.open('https://www.iafc.org/topics-and-tools/bugle-brief ', '_blank');
        }
        else if(selectedName === 'knowledge'){
            window.location = 'https://knowledge.iafc.org/home ';
        }
    }
    */
}