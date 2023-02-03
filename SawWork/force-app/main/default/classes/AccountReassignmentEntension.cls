public class AccountReassignmentEntension
{
        //private Id recordId;
        private Account_Reassignment__c accReassign;
        private id accReassignId {get; set;}
        private String fromWhere {get; set;} // MOB-360 Changes
        public String sf1ReturnMessageJSON {get; set;} // MOB-360 Changes @ Nagaraj Desai

        public AccountReassignmentEntension(ApexPages.StandardController controller)
        {
                fromWhere = 'VFPage'; // MOB-360 Changes : set fromWhere to regonize if the call is from VFPage
                accReassign = (Account_Reassignment__c)controller.getRecord();
                accReassignId = accReassign.id;
        }

        public AccountReassignmentEntension(Id accountReassignmentID) { // MOB-360 Changes : added constructor to initialize separately for SF1
                fromWhere = 'SF1';
                accReassignId = accountReassignmentID;
                System.DEBUG('accReassignId : ' + accReassignId);
        }

        public String resultSetCustom (Boolean errorOccured, String returnMessage) { // MOB-360 changes : addedd a custom function to get JSON returnVal

                Map<String, String> mapObject = new Map<String, String>();
                if(errorOccured != null) {
                        mapObject.put('errorOccured', String.valueOf(errorOccured));
                }
                if(returnMessage != null) {
                        mapObject.put('returnMessage', returnMessage);
                }
                return JSON.serialize(mapObject);
        }

        public PageReference overrideCutOff()
        {
                List<Account_Reassignment_Config__mdt>  arrcRecords = [select Id,developerName, Value__c
                                                                       from Account_Reassignment_Config__mdt limit 50000];


                System.DEBUG('arrcRecords : ' + arrcRecords);

                Map<String,String> settings = new Map<String,String>();

                for (Account_Reassignment_Config__mdt s:arrcRecords) {
                        settings.put(s.developerName,s.Value__c);
                }

                System.DEBUG('settings : ' + settings);

                String overrideCutOffProfiles = settings.get('OverrideCutOffProfiles');

                System.DEBUG('overrideCutOffProfiles : ' + overrideCutOffProfiles);

                List<String> profilesList = overrideCutOffProfiles.split(',');
                Set<String> profiles = new Set<String>();
                profiles.addAll(profilesList);

                System.DEBUG('profiles : ' + overrideCutOffProfiles);

                String loggedInUserId = Userinfo.getProfileId();

                System.DEBUG('loggedInUserId : ' + loggedInUserId);

                if (!profiles.contains(loggedInUserId)) {
                        //return settings.get('InsufficientAccessMsg');
                        if(fromWhere == 'SF1') { // MOB-360 changes : Add apex messages only if not called from SF1, if from SF1 set 'sf1ReturnMessageJSON'
                                sf1ReturnMessageJSON = resultSetCustom(true, settings.get('InsufficientAccessMsg'));
                        }
                        else {
                                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,settings.get('InsufficientAccessMsg')));
                        }
                        return null;
                }

                Account_Reassignment__c request = AccountReassignmentInterfaceClass.getAccountReassignmentRecord(accReassignId);

                System.DEBUG('request : ' + request);

                if (request == null) {
                        //return settings.get('Invalid_Request_Id');
                        if(fromWhere == 'SF1') {
                                sf1ReturnMessageJSON = resultSetCustom(true, settings.get('Invalid_Request_Id'));
                        }
                        else {
                                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,settings.get('Invalid_Request_Id')));
                        }
                        return null;
                }

                if (request.Reassign_Status__c.equalsIgnoreCase('Accepted')) {
                        //return settings.get('Request_Completed_Message');
                        if(fromWhere == 'SF1') {
                                sf1ReturnMessageJSON = resultSetCustom(true, settings.get('Request_Completed_Message'));
                        }
                        else {
                                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,settings.get('Request_Completed_Message')));
                        }
                        return null;
                }

                if (request.Adhoc_Request__c) {
                        //return settings.get('Request_Already_Overridden_Msg');
                        if(fromWhere == 'SF1') {
                                sf1ReturnMessageJSON = resultSetCustom(true, settings.get('Request_Already_Overridden_Msg'));
                        }
                        else {
                                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,settings.get('Request_Already_Overridden_Msg')));
                        }
                        return null;
                }


                /*
                 * If approval are in progress, then set the Override Account Move Lock to true
                 */
                if (request.Approval_Level__c == null || (request.Approval_Level__c != null && !request.Approval_Level__c.equalsIgnoreCase('Reassignment Approved'))) {
                        request.Expedited_By__c = UserInfo.getUserId();
                        request.Adhoc_Request__c = true;
                        update request;

                        //return settings.get('Expedited_Before_Approval_Message');
                        if(fromWhere == 'SF1') {
                                sf1ReturnMessageJSON = resultSetCustom(false, settings.get('Expedited_Before_Approval_Message'));
                        }
                        else {
                                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,settings.get('Expedited_Before_Approval_Message')));
                        }

                } else if (request.Approval_Level__c.equalsIgnoreCase('Reassignment Approved')) {

                        //set the override cut off flag and update
                        request.Adhoc_Request__c = true;
                        request.Expedited_By__c = UserInfo.getUserId();
                        //update request;

                        //request = getAccountReassignmentRecord(request.id);

                        //call the accept method to accept the approval process
                        AccountReassignmentInterfaceClass.Accept(request);
                        try {
                                update request;
                        }
                        catch (Exception e) {
                                System.DEBUG('Exception : ' + e);
                        }
                        //AccountReassignmentInterfaceClass.AcceptButton(request.id);

                        //return settings.get('Expedited_Successfully_Message');
                        if(fromWhere == 'SF1') {
                                sf1ReturnMessageJSON = resultSetCustom(false, settings.get('Expedited_Successfully_Message'));
                        }
                        else {
                                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,settings.get('Expedited_Successfully_Message')));
                        }

                }
                return null;
                //String redirectURL = '/'+accReassignId;
                //return new PageReference(redirectURL);
        }

        public PageReference backToRecord() {
                PageReference nextPage = new PageReference('/' + accReassignId);
                return nextPage;
        }

}