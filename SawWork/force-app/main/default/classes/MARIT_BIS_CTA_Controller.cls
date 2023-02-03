public class MARIT_BIS_CTA_Controller {

    @AuraEnabled
    public Static String getAssociatedAccountFromCTA(String CTA_Lead_ID){

        /** Creating dynamic URL for BIS account recommendation list 
            For example:
            QA has url: https://akamai--qa--lbi.visualforce.com/apex/AccountRecommendationList?id=xyz_id;
            Prod has url: https://akamai--lbi.visualforce.com/apex/AccountRecommendationList?id=abc_id;
        **/
        Organization org = [SELECT InstanceName,Name, IsSandbox, OrganizationType FROM Organization limit 1];
        String siteFullUrl = 'https://akamai';
        if(org.IsSandbox == true) {
            siteFullUrl += '--'+UserInfo.getUserName().substringAfterLast('.');
        }
        siteFullUrl += '--lbi.visualforce.com/apex/AccountRecommendationList?id=';
        
        Lead LeadId = [select Id,Associated_Account__c from Lead where id = :CTA_Lead_ID limit 1 ];
        if(LeadId.Associated_Account__c!= null){
            return siteFullUrl + LeadId.Associated_Account__c;
        }
        return null;
    }

}