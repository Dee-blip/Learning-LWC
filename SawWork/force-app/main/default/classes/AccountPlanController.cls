/**
 * @description       : controller class for Aura Component 'overrideNewAccountPlan'
 * @author            : apyati
 * @group             : L2Q
 * @last modified on  : 08-23-2021
 * @last modified by  : apyati
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   06-25-2021   apyati                             Initial Version
**/
public without sharing class AccountPlanController {

  /* THIS METHOD IS USED TO CHECK for ACTIVE ACCOUNT PLANS  */
  @AuraEnabled
  public static string hasActivePlans(String recordId){
    string message ='';
    try{ 
        Id accountId = String.escapeSingleQuotes(recordId);
        Integer count = [SELECT count() FROM Account_Plan__c WHERE Account__c = :accountId and Archived__c = false ];
        if( count >0){
          message = GsmUtilClass.getGsmSettingValue('NewAccountPlanWarning');
        }
      } catch (Exception e) {
          throw new AuraHandledException(e.getMessage());
      }
    return message;
  }

}