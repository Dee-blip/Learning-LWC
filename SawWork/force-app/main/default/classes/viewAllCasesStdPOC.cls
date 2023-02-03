/***************************************************************************************************
* @author       Ashin Louis
* @date         7/FEB/2022
* @Class name   viewAllCasesStdPOC
* @JIRA         ESESP-6647
* @description  This class is used as test class for 'viewAllCasesStdPOC' Apex class
* @team         GSS
* Ver     Date           Author      Modification
* 1.0   09-20-2021     Ashin Louis   Created new test class for 'viewAllCasesStdPOC' Apex class
*****************************************************************************************************/
public class viewAllCasesStdPOC {
    @AuraEnabled(Cacheable = true)
    public static List<Case> getCases(Id chId) {
        return [SELECT CaseNumber, Chime_Case_Type__c, Owner.Name,PST_Case_Product__c
                FROM Case WHERE Chime_Form__c=:chId ];
    }
}