public class HD_ChangeRequestTestDataFactory {
    Public static Map<String, String> statusMap = new Map<String, String>();
    Public static LIST<HD_CMR_SETTINGS__c> CMRSettingList = new  LIST<HD_CMR_SETTINGS__c>();

    public HD_ChangeRequestTestDataFactory()
    {
        setUpStatuses();
        updateOutages();
        setUpCustomSettings();
    }

    private static void setUpStatuses() {

    
    List<BMCServiceDesk__Status__c> status_list = new List<BMCServiceDesk__Status__c>();
    List<String> status_names = new List<String> {'APPROVAL REQUESTED', 'APPROVED',
        'AUTHORIZED', 'AUTO FAILED', 'CANCELLED',
        'CHANGE FAILED', 'CLOSED', 'COMPLETED',
        'IN PROGRESS', 'ON HOLD', 'OPENED','PENDING APPROVAL', 
        'REGISTERED','REJECTED','RISK & IMPACT'
        };//
    
    for (String status_name : status_names) {
          BMCServiceDesk__Status__c new_status = new BMCServiceDesk__Status__c(Name = status_name);
          new_status.BMCServiceDesk__appliesToChange__c = true;
          new_status.BMCServiceDesk__appliesToTask__c = true;
          new_status.BMCServiceDesk__inactive__c = false;
          status_list.add(new_status);
        
      }
    	insert status_list;
   
    for ( BMCServiceDesk__Status__c status : status_list) {
      statusMap.put(status.Name, status.id);

    }
  }
    
    private static void updateOutages() {

    List<BMCServiceDesk__Projected_Service_Outage__c> psouts = [SELECT Name, BMCServiceDesk__End_Date__c, BMCServiceDesk__Start_Date__c FROM BMCServiceDesk__Projected_Service_Outage__c where BMCServiceDesk__Inactive__c = false];
    Boolean rtval = false;

    for ( BMCServiceDesk__Projected_Service_Outage__c pso : psouts) {

      pso.BMCServiceDesk__End_Date__c = System.now().addDays(801);
      pso.BMCServiceDesk__Start_Date__c = System.now().addDays(800);

    }
    update psouts;
  }





  public static BMCServiceDesk__Change_Request__c getChange() {
	
    
    BMCServiceDesk__Change_Request__c  change = new BMCServiceDesk__Change_Request__c();
    change.Service_Element_Impact_duration__c = '00:10';
    change.BMCServiceDesk__Scheduled_End_Date__c = System.now().addDays(30);
    change.BMCServiceDesk__Scheduled_Start_Date__c = System.now().addDays(29);
    change.HD_TestRecord__c = true;

    List<User> usr = [select Id, username from User where Profile.name = 'ServiceDesk Staff' and HD_CMR_TAG__C = 'SPONSOR' and isActive = true limit 2];
    //usr.HD_CMR_TAG__C = 'SPONSOR';
    //update usr;
    change.HD_Sponsor__c = usr[0].id;
    change.Change_Coordinator_Primary__c = usr[1].id;
    return change;

  }
    
    private static void setUpCustomSettings() {
        
    
        HD_CMR_SETTINGS__c SETTING_CABQueueId =   HD_CMR_SETTINGS__c.getInstance('CAB_Queue_Id');
    HD_CMR_SETTINGS__c SETTING_AUTOLOCK   =   HD_CMR_SETTINGS__c.getInstance('Auto_Lock');
      HD_CMR_SETTINGS__c SETTING_TESTMODE  =   HD_CMR_SETTINGS__c.getInstance('Test_Mode');
      HD_CMR_SETTINGS__c SETTING_TESTEMAILS  =   HD_CMR_SETTINGS__c.getInstance('Test_Emails');



    if ( SETTING_CABQueueId == NULL || SETTING_CABQueueId.Value__c == NULL) {
      SETTING_CABQueueId  = new HD_CMR_SETTINGS__c();
      SETTING_CABQueueId.Name = 'CAB_Queue_Id';
      SETTING_CABQueueId.Value__c = [SELECT ID, NAME FROM Group WHERE TYPE = 'Queue' and NAME = 'CAB MANAGERS'][0].id;
      CMRSettingList.add(SETTING_CABQueueId);
    }

    if ( SETTING_AUTOLOCK == NULL || SETTING_AUTOLOCK.Value__c == NULL) {
      SETTING_AUTOLOCK  = new HD_CMR_SETTINGS__c();
      SETTING_AUTOLOCK.Name = 'Auto_Lock';
      SETTING_AUTOLOCK.Value__c = 'true';
      CMRSettingList.add(SETTING_AUTOLOCK);
    }
	if ( SETTING_TESTMODE == NULL || SETTING_TESTMODE.Value__c == NULL) {
      SETTING_TESTMODE  = new HD_CMR_SETTINGS__c();
      SETTING_TESTMODE.Name = 'Test_Mode';
      SETTING_TESTMODE.Value__c = 'NONE';
      CMRSettingList.add(SETTING_TESTMODE);
    }
      if ( SETTING_TESTEMAILS == NULL) {
      SETTING_TESTEMAILS  = new HD_CMR_SETTINGS__c();
      SETTING_TESTEMAILS.Name = 'Test_Emails' ;
      CMRSettingList.add(SETTING_TESTEMAILS);
    }





    if (CMRSettingList.size() > 0)
      insert CMRSettingList;
    }

}