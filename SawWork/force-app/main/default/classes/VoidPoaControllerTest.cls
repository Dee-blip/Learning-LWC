@isTest(seeAllData=false)
public with sharing class VoidPoaControllerTest {
    
    @testSetUp 
    static void createData(){
        System.runAs(utilTestClass.getTestRunUser()){
                
                    new SobjectBuilder(Environment_Setup__c.sObjectType)
                            .put(Environment_Setup__c.Environment_Type__c, 'Primary')
                            .put(Environment_Setup__c.Active_Org__c, true)
                            .put(Environment_Setup__c.Akam_Id_Start_String__c, 'F-')
                            .create();
                     Account acc=new account();
                                      acc.type='Lead';
                                      acc.website='www.locate.com';
                                      acc.name='LocateName';
                                      insert acc;

                    List<User> partnerUsers = SObjectFactory.createPartnerUsers(1);
                    System.debug(LoggingLevel.DEBUG , partnerUsers);

                    Account partAccount = SobjectRepository.getPartnerAccount();
                    Channel_Mapping__c channelMapping = SObjectFactory.createChannelMapping(partAccount.Id);
                    Opportunity oppty = (Opportunity)new SobjectBuilder(Opportunity.sObjectType)
                            .eagerPopulate()
                            .put(Opportunity.AccountId, acc.Id)
                            .put(Opportunity.Deal_Type__c, 'Indirect')
                            .put(Opportunity.Partner_Involved__c, partAccount.Id)
                            .put(Opportunity.Channel_Manager__c, channelMapping.Id)
                            .create()
                            .getRecord();
                    System.debug(LoggingLevel.DEBUG, oppty);

    	}
    }    
    
        
    public static testmethod void voidPoaDocumentTest() {  
         User dmlUser = utilTestClass.getTestRunUser();
        System.runAs(dmlUser){
            Boolean profileAllowed = false;
            List<String> allowedProfileIds = GsmUtilClass.getGSMSettingValue('POA_ProfilesWithVoidPermissions').split(',');
			//System.debug(allowedProfileIds);
        	// Set<id> allowedProfileIdsSet = new set<id>();
        	// for (String allowedProfileId :allowedProfileIds){
            // 	allowedProfileIdsSet.add(allowedProfileId);
        	// }
            
        
        	id pid = userinfo.getProfileId();
            for(String allowedProfileId : allowedProfileIds){
                if(allowedProfileId==pid){
                    profileAllowed = true;
                }
            }
       		
    
		
            Test.startTest();
            Opportunity oppty = SobjectRepository.getOpportunity();
            ContentVersion conVer = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Name', 'Name', 'Body');
            Partner_Order_Acceptance_Document__c poad = new Partner_Order_Acceptance_Document__c();
            poad.Opportunity__c = oppty.Id;
            poad.Validation_Override__c = true;
            poad.Attachment__c = conVer.Id;
            poad.Order_Acceptance_Status__c = 'Pending Acceptance';
            
            insert poad;
            
            string poaId = string.valueof(poad.id);
           
            VoidPoaController.voidPoaDocument(poaId);
            Test.stopTest();
            // after the testing stops, assert records were deleted properly
            //System.assertEquals(0, [select count() from ContentVersion where isDuplicate__c = true]);
            List<Partner_Order_Acceptance_Document__c> poa = [Select id,Order_Acceptance_Status__c from Partner_Order_Acceptance_Document__c where id =: poaId];
            String status = String.valueof(poa[0].Order_Acceptance_Status__c);
            
            if(profileAllowed){
            	System.assertEquals('Voided',status, 'POA Voided');
            }
            else{
                System.assertNotEquals('Voided', status, 'POA not Voided');
            }
                  
        }
    }
    
    public static testmethod void voidPoaDocumentTest2(){
        String profileId = GsmUtilClass.getGSMSettingValue('POA_ProfilesWithVoidPermissions').split(',')[0];
        
     	User partnerUsr = new User(LastName = '1LIVESTON',
                           FirstName='1JASON',
                           Alias = 'j1liv',
                           Email = '1jason.liveston@akamai.com',
                           Username = '900jason123456.liveston@akamai.com',
                           ProfileId = (id)profileId,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                           );
		insert partnerUsr;
        
        System.runAs(partnerUsr){
            List<String> allowedProfileIds = GsmUtilClass.getGSMSettingValue('POA_ProfilesWithVoidPermissions').split(',');
			//System.debug(allowedProfileIds);
        	// Set<id> allowedProfileIdsSet = new set<id>();
        	// for (String allowedProfileId :allowedProfileIds){
            // 	allowedProfileIdsSet.add(allowedProfileId);
        	// }

            Boolean profileAllowed = false;
        
        	id pid = userinfo.getProfileId();
            for(String allowedProfileId : allowedProfileIds){
                if(allowedProfileId==pid){
                    profileAllowed = true;
                }
            }
       		
		
            Test.startTest();
            Opportunity oppty = SobjectRepository.getOpportunity();
            ContentVersion conVer = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Name', 'Name', 'Body');
            Partner_Order_Acceptance_Document__c poad = new Partner_Order_Acceptance_Document__c();
            poad.Opportunity__c = oppty.Id;
            poad.Validation_Override__c = true;
            poad.Attachment__c = conVer.Id;
            poad.Order_Acceptance_Status__c = 'Pending Acceptance';
            
            insert poad;
            
            string poaId = string.valueof(poad.id);
           
            VoidPoaController.voidPoaDocument(poaId);
            Test.stopTest();
            List<Partner_Order_Acceptance_Document__c> poa = [Select id,Order_Acceptance_Status__c from Partner_Order_Acceptance_Document__c where id =: poaId];
            String status = String.valueof(poa[0].Order_Acceptance_Status__c);
            
            if(profileAllowed){
            
            	System.assertEquals('Voided',status,'POA Voided');
            }
            else{
                System.assertNotEquals('Voided', status, 'POA not Voided');
            }
                  
        }
        
        
    
	}
}