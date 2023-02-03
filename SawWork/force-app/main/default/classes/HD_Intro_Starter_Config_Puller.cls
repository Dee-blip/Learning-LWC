/*
* File Name: HD_Intro_Starter_Config_Puller
* Description : 
* @author :
* Modification Log ===============================================================
* Date 				Author 				Modification
* Aug 08th, 2020    Aneesh Budnar       PRTORES-1810 - Code scanner fixes
*/
public class HD_Intro_Starter_Config_Puller {

  @AuraEnabled
  public static List<HD_Intro_Starter_Config__c>  getIntroConfig()
  {
      return [select id , datastep__c, dataauraclass__c, dataintro__c  from HD_Intro_Starter_Config__c ORDER BY datastep__c LIMIT 500];
  }
  
    /* This methods enables or disables the intro started menu based on it lable i.e custom setting
     * Usage @ to disable use : HD Intro Starter Config_disabled
     *         to Enable  use : HD Intro Starter Config
     */
  @AuraEnabled
  public static boolean getIntroStartedFlag()
  {
      DescribeSObjectResult describe = SObjectType.HD_Intro_Starter_Config__c;
      String Label = describe.getLabel();
      system.debug(Label);
      if(Label.containsIgnoreCase('disabled'))
      {
          return false;
      }
      return true;
  }
    
}