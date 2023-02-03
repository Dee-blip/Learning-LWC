public class L2Q_PartnerPlanCreationController {
    
	public pagereference RedirectCheck()
    {
        Boolean redirectPartner = false;
        Set<String> profiles = new Set<String>();
        profiles.add('Partner Community Admin');
        profiles.add('Partner Community User');
        List<Profile> profileList = [Select id From Profile where name IN:profiles];
        Set<Id> profileIds = new Set<Id>();
        if (profileList != null && profileList.size() > 0) {
            for (Profile p:profileList) {
                profileIds.add(p.id);
            }
        } 
        if (profileIds.contains(UserInfo.getProfileId())) {
            redirectPartner = true;
        }
        
        String partnerPlanUrl;
        String hostname = ApexPages.currentPage().getHeaders().get('Host');
        if (redirectPartner) {
            Id accId = getLoginInUserPartnerAccountId(UserInfo.getUserId());
            partnerPlanUrl = '/a1x/e?retURL=%2Fa1x%2Fo&CF00NA0000007i3Km='+getAccountName(accId)+'&CF00NA0000007i3Km_lkid='+accId+'&nooverride=1';
        } else {
            partnerPlanUrl = '/a1x/e?retURL=%2Fa1x%2Fo&nooverride=1';
        }
        pagereference pageref = new pagereference(partnerPlanUrl);
        pageref.setredirect(true);
        return pageref;
    }
    
    public static string getLoginInUserPartnerAccountId(Id userId) {
        return [Select id, Contact.AccountId From User where id =:userId].Contact.AccountId;
        
    }
    public static string getAccountName(Id accId) {
        return [Select id, Name From Account where id =:accId].name;
        
    }
    
    public L2Q_PartnerPlanCreationController(ApexPages.StandardController stdController) {
    }
}