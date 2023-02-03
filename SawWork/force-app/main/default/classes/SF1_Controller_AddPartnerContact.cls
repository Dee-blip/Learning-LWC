public class SF1_Controller_AddPartnerContact
{
        @AuraEnabled
            public static String checkForPartnerAndOwner(String oppId)
    {
        Map<String,String> jsonMap = new Map<String,String>();
        PRMAddPartnerToSalesTeamController controller = new PRMAddPartnerToSalesTeamController ();
        Opportunity opp = controller.getOpportunity(oppId);
        if(opp.Partner_Involved__c == null)
        {
            jsonMap.put('message', 'Partner Involved Cannot be Null');
        }
        else
        {
            List<Id> salesTeamIdList = controller.getSalesTeamList(oppId,  opp.OwnerId);
            List<User> uList = controller.getUserList(salesTeamIdList, opp.Partner_Involved__c, opp.Partner_Involved__r.ParentId);
            if(uList == null || uList.size() == 0)
            {
                if(salesTeamIdList.size()!=1)
                    jsonMap.put('message', System.Label.PRM_OpportunityTeamMember_AddPartnerContact);
                else
                    jsonMap.put('message', 'No partner users found.');
            }
            else
            {
                jsonMap.put('message', '-');
            }
            
        }
        jsonMap.put('opptyName', opp.Name);
        jsonMap.put('ownerId', opp.OwnerId);
        jsonMap.put('partnerInvolvedId', opp.Partner_Involved__c);
        jsonMap.put('partnerInvolvedParentId', opp.Partner_Involved__r.ParentId);
         
        
        return JSON.serialize(jsonMap);
    }
        @AuraEnabled
        public static List<User> getUserContact(String oppId, String oppOwnerId, String partnerInvolvedId, String partnerInvolvedParentId)
        {
                PRMAddPartnerToSalesTeamController controller = new PRMAddPartnerToSalesTeamController ();
                return controller.getUserList(controller.getSalesTeamList(oppId, oppOwnerId), partnerInvolvedId, partnerInvolvedParentId);
        }
        @AuraEnabled
        public static String addUserToSalesTeam(String oppId, String userId)
        {
                String returnMessage = '';


                OpportunityTeamMember member = PRMAddPartnerToSalesTeamController.getOppTeamMember(oppId,userId);
                try
                {
                        insert member;
                        returnMessage = 'User Successfully added to sales team';
                }
                catch(Exception e)
                {
                        if(e.getMessage().contains('INACTIVE_OWNER_OR_USER'))
                        {
                                returnMessage = 'User cannot be added to the Sales team as Owner of the Opportunity is Inactive';
                        }
                        else if(e.getMessage().contains('DUPLICATE_VALUE'))
                        {
                                returnMessage = 'This User already exists in the Sales Team';
                        }
                        else
                        {
                                returnMessage = e.getMessage();
                        }
                }

                OpportunityShare oppshare = PRMAddPartnerToSalesTeamController.opptyUpdateShareTable(oppId,userId,'Edit');

                try
                {
                        insert oppshare;
                }
                catch(Exception ex)
                {

                }
                return returnMessage;
        }
        @AuraEnabled
        public static boolean isLightning()
        {
                if( UserInfo.getUiThemeDisplayed() == 'Theme4d')
                        return true;
                else
                        return false;
        }

}