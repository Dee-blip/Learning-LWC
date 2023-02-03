@isTest
public class OEMContactCustomControllerTest {
    static{
        utilTestClass.insertCustomSettings();
    }
    private static Account accPass;
    private static Account accFail;
    private static Contact conPass;
    private static Contact conFail;
    private static OEM_Opportunity__c  oemOpptyObj;
    private static OEM_Opportunity__c  oemOpptyObjSec;
    public static Map<String,GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();
    
   private static User salesOemUser;
    private static User salesRepUser;
    static User dmlUser = new User(id=UserInfo.getUserId());
    public static void init(){
        accPass = utilTestClass.CreateAccount('oemOpptyAccP');

        Organization orgDetails = [SELECT Division FROM Organization 
                                                WHERE Id = :UserInfo.getOrganizationId()];

            accPass.AKAM_Account_ID__c = 'F-AC-2024113';  
        
        insert accPass;
        accFail = utilTestClass.CreateAccount('oemOpptyAccF');
        accFail.AKAM_Account_ID__c = 'F-AC-7654321';
        insert accFail;
        conPass = utilTestClass.CreateContact('TestFirstP','TestLastP');
        conPass.AccountId = accPass.id;
        conFail = utilTestClass.CreateContact('TestFirstFa','TestLastFa');
        conFail.AccountId = accFail.id;

        
        User opptyOwnerUser = utilTestClass.CreateUser('nwUser', testcaseCustomSettings.get('User_Role').Value__c, 'Sales - OEM');
        System.runAs(dmlUSer)
        {
           insert opptyOwnerUser;
        }

        oemOpptyObj = new OEM_Opportunity__c(Name='oemTestOppty');
        oemOpptyObj.Account_Name__c = accPass.id;
        oemOpptyObj.OEM_Partner__c = 'Cisco';
        oemOpptyObj.Stage__c = '1-Target Account List';
        oemOpptyObj.Forecast_Category__c = 'Pipeline'; 
        oemOpptyObj.Close_Date__c = date.today();
        oemOpptyObj.OwnerId = opptyOwnerUser.Id;

        oemOpptyObjSec = new OEM_Opportunity__c(Name='oemTestOppty');
        oemOpptyObjSec.Account_Name__c = accFail.id;
        oemOpptyObjSec.OEM_Partner__c = 'Cisco';
        oemOpptyObjSec.Stage__c = '1-Target Account List';
        oemOpptyObjSec.Forecast_Category__c = 'Pipeline'; 
        oemOpptyObjSec.Close_Date__c = date.today();
        oemOpptyObjSec.OwnerId = opptyOwnerUser.Id;
            
    }
     public static OEM_Contact__c getOemContact(Id oemOpptyId, ID contactId){
        OEM_Contact__c oemContactObj = new OEM_Contact__c (OEM_Opportunity__c = oemOpptyId, Contact__c = contactId);
        return oemContactObj;
    }
    public static testMethod void testOemOppty(){
        //Perform the data creation
        init();
        Test.startTest();
        //insert OEM Opportunity

        insert oemOpptyObj;                
        insert conPass;
        insert conFail;
        //create an OEM Contact Object with account id that does not belong to associated OEM Oppty account. -> Fail

        // Removed validation rule as part of CR 3205251
        OEM_Contact__c oemContact = getOemContact(oemOpptyObj.id,conFail.id);
        try{
            insert oemContact;
        }//Catch(DmlException ex){
        //    System.assert(ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        //}
        Catch(Exception e){
           // System.assertNotEquals(e.getMessage(),null);
        }
        //create an OEM Contact Object with account id that belongs to associated OEM Oppty account. -> Pass
        oemContact = getOemContact(oemOpptyObj.id,conPass.id);
        insert oemContact;
        Test.stopTest();
    }
    public static testMethod void testOEMContactCustomController() {
       /* init();
        Test.startTest();
        insert oemOpptyObj;
        insert conPass;
        insert conFail;
        
        PageReference pageRef = Page.OEMContactCustomPage;
        pageRef.getParameters().put('pId',oemOpptyObj.id);
        Test.setCurrentPage(pageRef);
        
        OEMContactCustomController controller = new OEMContactCustomController(new ApexPages.StandardController(oemOpptyObj));
        ApexPages.currentPage().getParameters().put('accountId',accPass.id);
        ApexPages.currentPage().getParameters().put('lksrch','test');
        OEMContactCustomContactLookupController oemLookupController = new OEMContactCustomContactLookupController();
        oemLookupController.search();
        oemLookupController.getFormTag();
        oemLookupController.getTextBox();
        
        //create an OEM Contact Object with account id that does not belong to associated OEM Oppty account. -> Fail
        OEM_Contact__c oemContact = getOemContact(oemOpptyObj.id,conFail.id);
            
        //controller.setoemContact(oemContact);
        controller.oemContact = oemContact;
        PageReference nextErrorPage = controller.save();
        System.assertEquals(nextErrorPage,null);
        //check for OEM contact, that it is not inserted
        List<OEM_Contact__c> oemContactCheckList = [Select id from OEM_Contact__c where OEM_Opportunity__c = :oemOpptyObj.id];
        System.assertEquals(oemContactCheckList.size(),0);
        
        //create an OEM Contact Object with account id that belongs to associated OEM Oppty account. -> Pass
        oemContact = getOemContact(oemOpptyObj.id,conPass.id);
            
        //controller.setoemContact(oemContact);
        controller.oemContact = oemContact;
        PageReference nextPage = controller.save();
        System.assertNotEquals(nextPage,null);
        //check for OEM contact, that it actually got inserted
        oemContact = [Select id from OEM_Contact__c where OEM_Opportunity__c = :oemOpptyObj.id];
        System.assertNotEquals(oemContact,null);
        Test.stopTest();
        */
    }
    //create a bulk test method
    public static testMethod void testOemOpptyBulk(){
        //Perform the data creation
        init();
        //insert OEM Opportunity 
        Test.startTest();
        insert oemOpptyObj; 
        insert oemOpptyObjSec;               
        insert conPass;
        insert conFail;
        List<OEM_Contact__c> oemContactList = new List<OEM_Contact__c>();

        for(Integer i=0; i<50;i++){
            //create an OEM Contact Object with account id that does not belong to associated OEM Oppty account. -> Fail
            OEM_Contact__c oemContact = getOemContact(oemOpptyObj.id,conFail.id); 
            oemContactList.add(oemContact);   
            OEM_Contact__c oemContactSec = getOemContact(oemOpptyObjSec.id,conFail.id); 
            oemContactList.add(oemContactSec);   
        }
        
        // Removed validation rule as part of CR 3205251
            insert oemContactList;
         //check for OEM contact, that it is not inserted
        oemContactList = [Select id from OEM_Contact__c where (OEM_Opportunity__c = :oemOpptyObj.id OR OEM_Opportunity__c = :oemOpptyObjSec.id)];
        //System.assertEquals(oemContactList.size(),0);

        //create an OEM Contact Object with account id that belongs to associated OEM Oppty account. -> Pass
        oemContactList=new List<OEM_Contact__c>();
        for(Integer i=0; i<50;i++){
            //create an OEM Contact Object with account id that does not belong to associated OEM Oppty account. -> Fail
            OEM_Contact__c oemContact = getOemContact(oemOpptyObj.id,conPass.id); 
            oemContactList.add(oemContact);   
            OEM_Contact__c oemContactSec = getOemContact(oemOpptyObjSec.id,conPass.id); 
            oemContactList.add(oemContactSec);   
        }        
        insert oemContactList;
        //check for OEM contact, that it is inserted
        oemContactList = [Select id from OEM_Contact__c where (OEM_Opportunity__c = :oemOpptyObj.id OR OEM_Opportunity__c = :oemOpptyObjSec.id)];
       // System.assertNotEquals(oemContactList,null);
        //System.assertEquals(oemContactList.size(),100);
        Test.stopTest();
    }
    //public static String getRandomString(Integer len) {
    //    //Define set of character to be chosen from
    //    final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    //    //Define a random string to be made
    //    String randomString = '';
    //    while (randomString.length() < len) {
    //        //get a random number by Crypto class, take mod of it from length of 'chars' to randomly select a character
    //        Integer randomNo = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
    //        randomString += chars.substring(randomNo, randomNo+1);
    //    }
    //    return randomString; 
    //}
}