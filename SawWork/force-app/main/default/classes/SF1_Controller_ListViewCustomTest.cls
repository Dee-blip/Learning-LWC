@isTest(seeAllData=false)
public class SF1_Controller_ListViewCustomTest {
    
     private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    
    //static User
    static User dmlUser = utilTestClass.getTestRunUser();
    
    static testmethod void getListViewLabelsTest(){
     List<String> listViewNamesList = new List<String>();
      listViewNamesList=SF1_Controller_ListViewCustom.getListViewLabels('Account',true);
      listViewNamesList=SF1_Controller_ListViewCustom.getListViewLabels('Activity',false);
            listViewNamesList=SF1_Controller_ListViewCustom.getListViewLabels('Account',false);

      SF1_Enabled_ListViews__c sens=new SF1_Enabled_ListViews__c();
      sens.Enabled_LV_Ids_1__c='avsd,account';
      sens.Enabled_Objects__c='account';
      sens.Enabled_LV_Ids_2__c='sample';
      insert sens;
      SF1_Controller_ListViewCustom.getAvailableListViews();
    }
    
    static testmethod void getDetailsTest(){
    User accOwnerUser;
    system.runas(dmlUser){
    //Account Creation
                Test.loadData(globalDescribe.get('Environment_Setup__c'), 'CS_Environment_Setup');

            accOwnerUser = utilTestClass.CreateUser('newUser', GsmUtilClass.getGSMSettingValue('User_Role'), 'Sales Operations');
            insert accOwnerUser;
    }
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.Vertical__c = 'Gaming'; 
            acc.Sub_Vertical__c = 'Console Mfs';
            insert acc;
        List<SObject> opplist = new List<SObject>();
        
        task tk=new task();
        tk.status ='Not Started';
        tk.Subject = 'Request for Contract Entry';
        Task oppTask = utilTestClass.createTask(accOwnerUser.id,'Request for Contract Entry','Not Started','Meeting',acc.id);

        insert oppTask;
        
        opplist=SF1_Controller_ListViewCustom.getDetails('My Accounts', 'Account','0','20');
        opplist=SF1_Controller_ListViewCustom.getDetails('Pending Deal Registrations', 'Opportunity','0','20');
        opplist=SF1_Controller_ListViewCustom.getDetails('CMG Contracts Not Started', 'Activity','0','20');
        opplist=SF1_Controller_ListViewCustom.getDetails('Credit Check Activities', 'Activity','0','20');
        opplist=SF1_Controller_ListViewCustom.getDetails('DD Activities', 'Activity','0','20');
        opplist=SF1_Controller_ListViewCustom.getDetails('Legal Activities', 'Activity','0','20');
        opplist=SF1_Controller_ListViewCustom.getDetails('Fund Request', 'Fund Request','0','20');

    }
    
}