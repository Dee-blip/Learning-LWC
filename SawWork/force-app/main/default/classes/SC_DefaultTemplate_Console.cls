/*===================================================================================================================+

|  HISTORY  |                                                                            

|  DATE             DEVELOPER         CR        DESCRIPTION                               

|  ===========      =========       =======     =========== 
                                                       
|  17-SEP-2014      Aditya Sonam    2684757     This class is used to set Default template in Answer customer functionality for service
                                                cloud console - Case Setting to display "DefaultwithAKAMCaseID" Email Template
|                                       
|                                                       
+====================================================================================================================*/

Public class SC_DefaultTemplate_Console implements Support.EmailTemplateSelector {
    
    // The main interface method
    Public ID getDefaultEmailTemplateId(Id CaseID) {
          
        // get the template ID from the Custom Setting's Template Name
        List<EmailTemplate> ets = new List<EmailTemplate>();
        ets = [SELECT id FROM EmailTemplate WHERE DeveloperName = :SC_Smart_Template_Loader_Conf__c.getValues('DefaultTemplateNameConsole').Template_Name__c];
        
        //Return the ID of the template selected
        if (ets.size() > 0) {
           return ets[0].id;
        }

        return null;
   }
}