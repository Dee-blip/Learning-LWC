/**
 * @description       : Test Class for ScJarvisSurvey
 * @author            : Vishnu Vardhan
 * @group             : 
 * @last modified on  : 02-25-2022
 * @last modified by  : Vishnu Vardhan
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   02-25-2022   Vishnu Vardhan   Initial Version
**/
@isTest
public with sharing class ScJarvisSurveyTest {
    
    /**
    * @description 
    * @author Vishnu Vardhan | 02-25-2022 
    **/
    @isTest static void testSurvey() {
        AuraHandledException aex;
        try{
            ScJarvisSurvey.getSurveyInvitationLink('communitysurvey', 'feedbackCategory', 'pageName');
        } catch(AuraHandledException ex) {
            aex = ex;
        }
        System.assertNotEquals(aex, null);

        String surveyId;
        ScJarvisSurvey.getNewSurveyInvitation('communitysurveyinv123', surveyId, 'feedbackCategory', 'pageName');
        
    }
}