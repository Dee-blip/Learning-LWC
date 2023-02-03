/* ========================================================================
    Author: Sonia Sawhney
    Description: Helper class used for fetching the connection id and owner
    Created Date : 07/17/2013
    Modification History:
    CR#            Developer     Comments
    CR 3535201     ssawhney      Removing query for getting the connection id and moving the same to Custom Setting 
    ======================================================================== */
    global class ConnectionHelper 
    {
        //Utility function to return connection id
        public static Id getConnectionId() {
    
            /*List<PartnerNetworkConnection> partnerNetConList = [Select id from PartnerNetworkConnection where connectionStatus = 'Accepted' and connectionName = :connectionName];
            if ( partnerNetConList.size()!= 0 ) {
                return partnerNetConList.get(0).Id;
            }*/
            
            Environment_Setup__c enviromentSetup = Environment_Setup__c.getInstance();
            if (enviromentSetup.ConnectionId__c != null) {
                return enviromentSetup.ConnectionId__c;
            }            
            
            return null;
        }
       
        
        //Utility function to return the connection Owner Id
        /*public static Id getConnectionOwnerId(String connectionName) {
    
            List<PartnerNetworkConnection> partnerNetConList = 
              [Select createdById from PartnerNetworkConnection where connectionStatus = 'Accepted' and connectionName =:connectionName];
        
            if ( partnerNetConList.size()!= 0 ) {
                return partnerNetConList.get(0).createdById;
            }    
            return null;
        }*/
        
        //Utility function for fetching Active Org Flag from Environment Setup custom settings
        public static boolean getActiveOrgFlag()
        {
            Environment_Setup__c enviromentSetupCustomSetting = Environment_Setup__c.getInstance();
            return enviromentSetupCustomSetting.Active_Org__c;
        }
        
        //This method is used to submit the job for pushing the data to Production
        webservice static string SubmitSyncJob(){
            Environment_Setup__c environmentSetup = Environment_Setup__c.getInstance();
            //Submit the job only if the DR environment is up
            if(environmentSetup.Environment_Type__c == 'DR' && environmentSetup.Active_Org__c == true)
            {
                BatchablePushCreatedRecordsToProd pushRecords = new BatchablePushCreatedRecordsToProd(); 
                database.executebatch(pushRecords);
                return 'Job Submitted Successfully';
            }
            else
            {
                return 'You can only run this job from DR org when it is active';
            }
        }
}