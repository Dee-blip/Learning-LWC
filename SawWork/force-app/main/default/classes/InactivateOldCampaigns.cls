/***
    InactivateOldCampaigns
    @author : Karteek Mekala <kmekala@akamai.com>
    @Description :  This class implements the Schedulable interface thus enabling it to run as a scheduled class.
                    CR 613171 Please Auto Update Status on Campaigns.
                    Once the End Date on a campaign has passed, please change the status from Active to Inactive.
                    Job to run weekly.
                    
    @History
    --Developer           --Date            --Change
    Karteek Kumar M       06/05/10          Created the class.   
                                            CR 613171 Please Auto Update Status on Campaigns
    Chandra Lohani		  23/06/2011        Modified for CR 1168849-Bugfix for inactivate Old Campaign Scheduled Job
                                            added condition "and Active_Duration__c !='Never Ending'"                                                
*/
global class InactivateOldCampaigns
{
    public static String InactivateOldCampaigns()
    {
        // Get all the Campaigns that need to be inactivated.
        List<Campaign> updateCampaigns = [select Id
                                                ,Validation_Override__c
                                                ,IsActive 
                                           from  Campaign 
                                           where IsActive = true
                                             and Active_Duration__c !='Never Ending' 
                                             and EndDate < :Date.today() LIMIT 9000];
        
        String resStr = '1:';
        
        try
        {
            for(Campaign cmpg : updateCampaigns)
            {
                cmpg.Validation_Override__c = true;
                cmpg.IsActive = false;
                resStr = resStr + cmpg.Id +',';
            }
            if(updateCampaigns.size()>0)
            {
                update updateCampaigns; 
            }
            resStr = resStr + '\nCount is '+updateCampaigns.size();
            return resStr;                
        }
        catch (exception e)
        {
            resStr = '0#' + e;
            return resStr;
        }
    }
}