/*******************************************************************************************************
Author       :   jrathod
Created Date :   Dec 29, 2021
JIRA         :   ESESP-5526
Description  :   Created this trigger to validate duplicate record creation
********************************************************************************************************
Jay         29-Dec-2021     ESESP-5526      Initial version
*/

trigger SC_CNSOnCaseTrigger on SC_CNSOnCase__c (before insert, before update) {

    new SC_CNSOnCaseTriggerHandler().process();

}