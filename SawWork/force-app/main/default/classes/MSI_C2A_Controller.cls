// MARIT-10 or MARIT-140 Added by Ujjawal Somani on 17th Oct 2019
// MARIT-637:Ujjawal Somani -> Changing logic to first check for Contact record and then for parent lead if Contact record is not present.
public class MSI_C2A_Controller {

    @AuraEnabled
    public Static String getParentLeadFromC2A(String C2A_Lead_ID){
            
        Lead ParentLeadId = [select Parent_Lead__c,Associated_Contact__c from Lead where id = :C2A_Lead_ID limit 1 ];
        if(ParentLeadId.Associated_Contact__c!= null){
            /** Creating dynamic URL for mkto sales insight **/
            Organization org = [SELECT InstanceName,Name, IsSandbox, OrganizationType FROM Organization limit 1];
            String siteFullUrl = 'https://akamai';
            if(org.IsSandbox == true) {
                siteFullUrl += '--'+UserInfo.getUserName().substringAfterLast('.');
            }
            siteFullUrl += '--mkto-si.' + org.InstanceName + '.visual.force.com/apex/Contact?id=';

            return siteFullUrl+ParentLeadId.Associated_Contact__c;
        }
        else if(ParentLeadId.Parent_Lead__c!= null){
            /** Creating dynamic URL for mkto sales insight **/
            Organization org = [SELECT InstanceName,Name, IsSandbox, OrganizationType FROM Organization limit 1];
            String siteFullUrl = 'https://akamai';
            if(org.IsSandbox == true) {
                siteFullUrl += '--'+UserInfo.getUserName().substringAfterLast('.');
            }
            siteFullUrl += '--mkto-si.' + org.InstanceName + '.visual.force.com/apex/Lead?id=';

            return siteFullUrl+ParentLeadId.Parent_Lead__c;
        }
        return null;
    }

}