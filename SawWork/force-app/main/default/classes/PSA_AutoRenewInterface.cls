/*
 * CR: FFPSA-636
 * Developer: Suhas Jain
 * Automated Renewal of projects: This is the interface which the individual products class will implement
 * Date: 04th Aug 2020
 * 
 */ 
public interface PSA_AutoRenewInterface 
{
    PSA_AutogenObjectList renewProjects(Map<pse__Proj__c,Project_Contract_Line_Item__c> projectsToPCLIMap, Map<String,Map<String,Merge_Contract_Detail__c>> contractSetupMap);
}