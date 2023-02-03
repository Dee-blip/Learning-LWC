global class L2Q_Sales_ProcessInactiveUser implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute

        String query = 'SELECT Id FROM User where Sales_Team_Member_Inactive_Proccessed__c = true';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<User> userList) {

        // process each batch of records default size is 200
        List<Id> userIdList = new List<Id>();
        for(User u : userList) {
            // Update the Account Name
            u.Sales_Team_Member_Inactive_Proccessed__c = false;
            userIdList.add(u.Id);
        }

        try {
            // Update the Account Record
            List<AccountTeamMember> ATM = [select id from AccountTeamMember
                                           where UserId in :userIdList and TeamMemberRole  != 'Sales - Primary'];
            List<OpportunityTeamMember> OTM = [select id from OpportunityTeamMember
                                           where UserId in :userIdList and TeamMemberRole  != 'Sales - Primary'];

            GSMUtilClass.doDatabaseDelete(ATM, 'L2Q_Sales_ProcessInactiveUser', 'ATM Remove Inactive User');
            GSMUtilClass.doDatabaseDelete(OTM, 'L2Q_Sales_ProcessInactiveUser', 'OTM Remove Inactive User');
            update userList;

        } catch(Exception e) {
            System.debug(e);
        }

    }

    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
    }
}