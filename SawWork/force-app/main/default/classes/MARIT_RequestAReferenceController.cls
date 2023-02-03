// MARIT-307 Added by Himanshu Verma on 14th Feb 2020
// This class handles Request a reference action
public class MARIT_RequestAReferenceController {
    public class ReferenceInfo { 
        Boolean isOpptyValid;
        String opptyId;
        String opptyName;
        String orgId;
        String userId;
        string APISessionId;
        string APIPartnerServerURL90;
        
        public ReferenceInfo () {
            this.isOpptyValid = false;
            this.opptyId = '';
            this.opptyName = '';
            this.orgId = '';
            this.userId = '';
            this.APISessionId = '';
            this.APIPartnerServerURL90 = '';
        }
    }
    
    @AuraEnabled
    public static String FetchOpportunity (String recordId) {
        ReferenceInfo refInfo = new ReferenceInfo();
        if (recordId == null) {
            return JSON.serialize(refInfo);
        }
        String OpptyStageToBeconsidered = MarketingUtilClass.getMarketingSettingsValue('OpportunityStageToBeConsidered');
        Opportunity op = [select Id, StageName, Name from Opportunity where id = :recordId];
        if (op != null && OpptyStageToBeconsidered != null && !String.isEmpty(OpptyStageToBeconsidered) && OpptyStageToBeconsidered.contains(op.StageName)) {
            refInfo.isOpptyValid = true;
            refInfo.APIPartnerServerURL90 = EncodingUtil.URLENCODE(URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/9.0/' + UserInfo.getOrganizationId(), 'UTF-8');	
            refInfo.APISessionId = EncodingUtil.URLENCODE(UserInfo.getSessionId().substring(0), 'UTF-8');
            refInfo.opptyId = op.Id;
            refInfo.opptyName = op.Name;
            refInfo.orgId = UserInfo.getOrganizationId();
            refInfo.userId = UserInfo.getUserId();
        }
        return JSON.serialize(refInfo);
    }
}