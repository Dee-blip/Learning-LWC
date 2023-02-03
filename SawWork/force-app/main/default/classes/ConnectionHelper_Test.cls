/*
Author: Sonia Sawhney
Description: Contains test cases for all ConnectionHelpder Class 
Created Date : 12/29/2016 
*/
@isTest
public class ConnectionHelper_Test {
    static testMethod void ConnectionHelperTests() {
        string connectionId = [Select Id from PartnerNetworkConnection where ConnectionStatus != 'Inactive' limit 1].Id;
       
        Environment_Setup__c environSetup = new Environment_Setup__c();
        environSetup.Environment_Type__c = 'Primary';
        environSetup.Akam_Id_Start_String__c = 'F-';
        environSetup.Active_Org__c = true;
        insert environSetup;       
        ConnectionHelper.getConnectionId();
        
        environSetup.ConnectionId__c = connectionId;
		update environSetup;
        ConnectionHelper.getConnectionId();

        ConnectionHelper.getActiveOrgFlag();
        ConnectionHelper.SubmitSyncJob();
        
        environSetup.Environment_Type__c = 'DR';
        update environSetup;
        ConnectionHelper.SubmitSyncJob();
    }
}