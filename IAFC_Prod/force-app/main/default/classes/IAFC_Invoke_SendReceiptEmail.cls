global class IAFC_Invoke_SendReceiptEmail {
    @InvocableMethod 
    public static List<FlowOutput> SendReceiptEmail(List<FlowInput> input ) //test rec a1C1k000000ByVmEAK
    {
        List<string> emails = new List<string>();
        String e = input[0].email;
        emails.add(e);
        string id = input[0].receipt.Id; 
        
        //IAFC_RealMagnetClient client = new IAFC_RealMagnetClient();  
        List<FlowOutput> results = new List<FlowOutput>();
        FlowOutput output = new FlowOutput(); 
        //output.response = client.SendReceiptEmail(id,emails);'
        try{
            IAFC_RealMagnetClient.SendReceiptEmailAsync(id,emails); // MUST USE ASYNC FOR CALLOUTS w/ TRIGGERS
            output.response = 'Email Sent';
        }catch(Exception ex){
            output.response = 'Error: ' + ex.getMessage();
        }
        results.add(output);
        return results;
	}

     //input details that comes to apex from flow
    public class FlowInput{
    
        @InvocableVariable
        public OrderApi__Receipt__c receipt;
        
        @InvocableVariable
        public String email;
        
    }
    
    //output details which goes from apex to flow
    public class FlowOutput{ 
        @InvocableVariable
        public String response;
         
    }
}