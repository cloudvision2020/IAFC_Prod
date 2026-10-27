public with sharing class IAFC_Invoke_SendWelcomeEmail {
 
    @InvocableMethod
    public static List<Contact> SendWelcomeEmail(List<Contact> contacts)
    { 
        IAFC_RealMagnetClient client = new IAFC_RealMagnetClient(); 
        client.SendWelcomeEmail(contacts);
        
        return contacts;
	} 
}