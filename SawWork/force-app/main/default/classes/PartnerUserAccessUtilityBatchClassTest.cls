@isTest(seeAllData=false)
public class PartnerUserAccessUtilityBatchClassTest {

    static User dmlUser = new User(id=UserInfo.getUserId());

        @testSetUp static void insertCustomSettingsAndCreateData()
        {
                System.runAs(utilTestClass.getTestRunUser())
                {
                Map<String, String> objectToCustomSettingResource = new Map<String, String>{
                        'Environment_Setup__c' => 'CS_Environment_Setup'
                };
                utilTestClass.insertCustomSettings(objectToCustomSettingResource);
                insert new Features_Toggle__c(name='isCronErrorMailViaCode',Toggle__c=false);
                insert new PRM_Settings__c(name='NonLitePermissionSets', Value__c='Has_DealRegistration_Access__c,Has_PartnerPlans_Access__c');
                SObjectFactory.createPartnerUsers(1);
                User partnerUser = SobjectRepository.getPartnerUser();
                // create master CM for MDF_Approver__c
                SobjectFactory.createDealRegUnsubmitted(partnerUser.Contact.AccountId);
                }
        }
    
    	static testmethod void testPartnerMDFRelatedAccess()
        {
                
                User partnerUser = SobjectRepository.getPartnerUser();
                
                System.runAs(partnerUser)
                {
                    SFDC_Channel_Account_Plan__c cap = (SFDC_Channel_Account_Plan__c)new SobjectBuilder(SFDC_Channel_Account_Plan__c.sObjectType)
                            .eagerPopulate()
                            .put(SFDC_Channel_Account_Plan__c.Partner_Account__c, partnerUser.Contact.AccountId)
                            .create()
                            .getRecord();
    
                    Partner_Marketing_Plan__c pmp = (Partner_Marketing_Plan__c)new SobjectBuilder(Partner_Marketing_Plan__c.sObjectType)
                            .eagerPopulate()
                            .put(Partner_Marketing_Plan__c.Business_Plan__c, cap.Id)
                            .create()
                            .getRecord();
    
                    Partner_Marketing_Activity__c pma = (Partner_Marketing_Activity__c)new SobjectBuilder(Partner_Marketing_Activity__c.sObjectType)
                            .eagerPopulate()
                            .put(Partner_Marketing_Activity__c.Partner_Marketing_Plan__c, pmp.Id)
                            .create()
                            .getRecord();
    
                    pmp.Plan_Status__c = 'Approved';
                    update pmp;
                    pma = SobjectRepository.getPMA();
                    
                    Id accountId = partnerUser.Contact.AccountId;
                    List<AccountShare> accountSharesList = [Select id, AccountId , UserOrGroupId , RowCause, AccountAccessLevel 
                                                             From AccountShare where AccountId =:accountId and 
                                                            						AccountAccessLevel = 'Edit' and
                                                           							RowCause = 'Manual'];
                    
                    System.assert(accountSharesList.size() > 0);
                    
                    System.runAs(dmlUser) {
                    	//Delete the existing account share to test the job
                    	Database.delete(accountSharesList);
                    }
                    
                    //Make sure the shares are deleted
                    List<AccountShare> accountSharesListAfterDeletion = [Select AccountId , UserOrGroupId , RowCause, AccountAccessLevel 
                                                             From AccountShare where AccountId =:accountId and 
                                                                         				AccountAccessLevel = 'Edit' and 
                                                                        				RowCause = 'Manual'];
                    
                    System.assertEquals(accountSharesListAfterDeletion.size(), 0);
                    
                    Test.startTest();
                    PartnerUserAccessUtilityBatchClass job = new PartnerUserAccessUtilityBatchClass();
                    Database.executeBatch(job);
                    Test.stopTest();
                    
                }

        }
    
}