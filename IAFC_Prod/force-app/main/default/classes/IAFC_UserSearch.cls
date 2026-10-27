public  class IAFC_UserSearch {
    public IAFC_UserSearch() { }
    
    @AuraEnabled(cacheable=true)
    public static List<Contact> userLoginLookup(String last, String postal)  {
        //String key = '%' + last + '%'; 
        List<Contact> lookupresults = new List<Contact>();
        if(last.length() > 0 && postal.length() > 0){
            postal = postal +'%';
            lookupresults = [
                SELECT Id, Firstname, Lastname, Title, Email
                FROM Contact 
                WHERE Lastname = :last  
                    AND Email != null
                    AND MailingPostalCode like :postal 
                    LIMIT 10
            ];

            for(Contact u : lookupresults){
                string domain = u.Email.split('@')[1];
                string pre = u.Email.split('@')[0];//x.split('\\.'); 
                if(pre.length() == 1){
                    pre = '*';
                }
                else if(pre.length() == 2){
                    pre = pre.substring(0,1) + '*';
                }
                else if(pre.length() <= 8){
                    pre = pre.substring(0,1) + pre.substring(1,1).rightPad((pre.length() - 2),'*') + pre.substring(pre.length() - 1);
                }
                else
                {
                    integer cnt = Integer.valueOf((pre.length() - 2)*.5);                
                    pre = pre.substring(0,1) + pre.substring(1,cnt).rightPad((pre.length() - 2),'*') + pre.substring(pre.length() - 1);
                } 

                //System.debug(x);
                u.Lastname = u.Firstname.substring(0,1) + '. ' + u.Lastname;
                u.Email = pre + '@'+ domain; // pre[pre.size()-1];
                u.FirstName = '';
                //System.debug(u.Username);
            }
        }

        return lookupresults;
    }
}