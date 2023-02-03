/*
 * Test class for HD_Resolved_State_to_Closed.cls and HD_Batchable_Resolved_State_to_Closed.cls
 * Created by : Nisarga Madhav
 * Modification Log ===============================================================
 * Date               Author            Modification
 * Oct 18th, 2021     Aneesh Budnar     PRTORES-977 - Fix Test class failures
*/
@isTest(SeeAllData=false)
public class HD_Test_Resolved_to_Closed {

    public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    private static BMCServiceDesk__Incident__c Incident;
    static Integer numberofdaysforclose;
    static Map<String,BMCServiceDesk__Category__c> categoryMap = new Map<String,BMCServiceDesk__Category__c>();
    static Map<String,String> urgencyMap = new Map<String,String>();
    static List<String> urgencyname = new List<String>{'Severity 1','Severity 2','Severity 3','Severity 4'};
    static List<String> impactname = new List<String>{'LOW'};
    static Map<String,String> impactmap = new Map<String,String>();
    static Map<String,String> statusMapNametoID;
    static List<BMCServiceDesk__Category__c>  child_catList = new List<BMCServiceDesk__Category__c>();
    static Map<String,String> child_category = new Map<String,String>();
    static List<String> cattypeNames = new List<String>{'Q_ABI-DEV','Q_COGS_IT','Q_Corporate_DataCenter','Q_CORP_SVC','Q_CORP_SVC_BLR','Q_DBA','Q_EAE_OPS','Q_Entsec','Q_HELPDESK_HARDWARE','Q_HELPDESK_MALWARE','Q_HELPDESK_TELECOM','Q_HELPDESK_TRIAGE','Q_HYPERION_ADMIN','Q_ITOC','Q_ITOC_Alerts','Q_ITOC_TEST','Q_ITOC_TEST3','Q_IT_HR_APPS','Q_Legal_IP','Q_Legal_Marketing Review','Q_Legal_Network','Q_Legal_Procurement','Q_Legal_Vendor','Q_Messaging','Q_NETSTATSENGINE_IT','Q_Network Engineering','Q_Network_IDF','Q_ORACLE_APPS','Q_SI','Q_SI_OPS','Q_UNIVERSITY'};
    static Map<String,String> cattypemap;

     
    private static void Initialize()
    {
        DateTime myDateTime = DateTime.now();
        numberofdaysforclose = 3;
        String dayOfWeek = myDateTime.format('E');
        List<HD_Resolved_Status_Settings__c> custom_settings1 = new List<HD_Resolved_Status_Settings__c>();
        custom_settings1.add(new HD_Resolved_Status_Settings__c(name = 'days_from_resolved_to_closed_status', value__c = 3));
        custom_settings1.add(new HD_Resolved_Status_Settings__c(name = 'start_date', date__c  = date.newInstance(2016, 10, 1)));
        insert custom_settings1;
        
       
        List<HD_RF_TRIGGER_FLAG__c>  custom_settings2 = new List<HD_RF_TRIGGER_FLAG__c>();
        custom_settings2.add(new HD_RF_TRIGGER_FLAG__c(name ='HD_RemedyForceCustomization_Tri'));
        custom_settings2.add(new HD_RF_TRIGGER_FLAG__c(name ='HD_RemedyForceCustomization'));
     
        insert custom_settings2;
        if(custom_settings1 != null)          
          numberofdaysforclose= (Integer)custom_settings1[0].value__c;
        //urgency
         urgencymap  = HD_Test_Remedyforce_TestDataFactory.createUrgency(urgencyname);
        //impact
        impactmap = HD_Test_Remedyforce_TestDataFactory.createImpact(impactname);
        /*for(BMCServiceDesk__Status__c statuslist : [ SELECT ID,Name FROM BMCServiceDesk__Status__c Where BMCServiceDesk__appliesToIncident__c = true ] ) 
        {
               statusMapNametoID.put(statuslist.Name, statuslist.ID);
        }
            
        for(BMCServiceDesk__Urgency__c urgency : [select Id,Name from BMCServiceDesk__Urgency__c limit 100])
        {
            urgencyMap.put(urgency.Name,urgency);
        }*/
        statusMapNametoID = HD_Test_Remedyforce_TestDataFactory.insertAllStatus();
        cattypemap = HD_Test_Remedyforce_TestDataFactory.createcategorytype(cattypeNames);

        BMCServiceDesk__Category__c corp =  new BMCServiceDesk__Category__c(Name='Corporate IT',BMCServiceDesk__FKCategoryType__c=cattypemap.get('Q_HELPDESK_TRIAGE '),BMCServiceDesk__AvailableForIncidents__c=true,BMCServiceDesk__Display_In_SelfService__c=true);
        child_catList.add(corp);
        
        //adding the cat list 
        child_category = HD_Test_Remedyforce_TestDataFactory.createCategory(child_catList); 

        /*
        List<BMCServiceDesk__Category__c> categoryList = [SELECT Name,ID FROM BMCServiceDesk__Category__c WHERE Name= 'Corporate IT' limit 1];          
        
        if(categoryList.size()>0){
           for(BMCServiceDesk__Category__c category : categoryList)
              categoryMap.put(category.Name,category);    
        }
        impact = [select Id from BMCServiceDesk__Impact__c where Name = 'LOW'];
        */
         if(dayOfWeek == 'Sat' || dayOfWeek == 'Sun' || dayOfWeek == 'Mon' || dayOfWeek == 'Tue')
                numberofdaysforclose += 2;
        if(Incident == NULL)
        {
            User staff = HD_Test_Remedyforce_TestDataFactory.runAsUser('ServiceDesk Staff',true);
            //Creating test incident record with resolved status
            System.runAs(new UserTestHelper.UserBuilder().buildAndSave()) {
                Incident = new BMCServiceDesk__Incident__c(
                    BMCServiceDesk__FKClient__c = system.userinfo.getUserId(),
                    BMCServiceDesk__FKImpact__c=impactmap.get('LOW'), 
                    BMCServiceDesk__FKUrgency__c=urgencymap.get('Severity 4'), 
                    BMCServiceDesk__incidentDescription__c = 'New ticket',
                    BMCServiceDesk__FKCategory__c=child_category.get('Corporate IT'));
                //Id originalQueueId = Incident.ownerId;            
                //Incident.ownerId = staff.id;
                // Incident.BMCServiceDesk__queueName__c = 'Triage Team';
                Incident.BMCServiceDesk__FKStatus__c = statusMapNametoID.get('ASSIGNED');  
                insert Incident;
            }
           
            Incident = [select id, BMCServiceDesk__FKClient__c,BMCServiceDesk__FKImpact__c,BMCServiceDesk__FKUrgency__c,BMCServiceDesk__incidentDescription__c,BMCServiceDesk__FKCategory__c,HD_Incident_Group__c,BMCServiceDesk__StatusChangeDate__c from bmcservicedesk__incident__C where id = :Incident.id];
            Incident.BMCServiceDesk__incidentResolution__c = 'Test-Fixed';
            Incident.Effort_Estimation__c = '11:11';
            Incident.BMCServiceDesk__FKStatus__c = statusMapNametoID.get('RESOLVED');
            update Incident;
            //Setting Status Change date to any value between 14 and numberofdaysforclose
            Incident.BMCServiceDesk__StatusChangeDate__c=Date.today().addDays(-10);
            update Incident;
            
            }
    }
    public static testMethod void testSchedulable()
    {
        
        Test.startTest();   
        Initialize();
        // Schedule the  job
      String jobId = System.schedule('ScheduleApexClassTest',
                        CRON_EXP, 
                        new HD_Resolved_State_to_Closed());
        Test.stopTest();
        //Schedulable and Batchable classes get executed here
        
    }
    public static testMethod void testBatchable()
    {
        
        Test.startTest();   
        Initialize();
        System.debug('Inside test'+Incident);
        
        System.debug(Limits.getLimitAggregateQueries());
        String q='select Id, BMCServiceDesk__FKStatus__c from BMCServiceDesk__Incident__c where BMCServiceDesk__FKStatus__r.Name = \'RESOLVED\' and RecordType.Name != \'Service Incident\' and HD_Incident_Group__c = \'Corp IT\' and BMCServiceDesk__StatusChangeDate__c = LAST_N_DAYS:14 and BMCServiceDesk__StatusChangeDate__c < LAST_N_DAYS:'+numberofdaysforclose + 'order by createddate desc limit 1';
        
        System.debug('Database.executeBatch');
        HD_Batchable_Resolved_State_to_Closed batch=new HD_Batchable_Resolved_State_to_Closed(q, statusMapNametoID.get('CLOSED')); 
        Database.executeBatch(batch, 1);
        Test.stopTest();
        //Schedulable and Batchable classes get executed here
        System.debug('After test'+Incident);
        System.debug(Limits.getLimitAggregateQueries());
        Incident = [select id, BMCServiceDesk__FKClient__c,BMCServiceDesk__FKStatus__r.Name,BMCServiceDesk__FKImpact__c,BMCServiceDesk__FKUrgency__c,BMCServiceDesk__incidentDescription__c,BMCServiceDesk__FKCategory__c,HD_Incident_Group__c,BMCServiceDesk__StatusChangeDate__c from bmcservicedesk__incident__C where id = :Incident.id];
        
        System.debug('After closing:'+Incident);
        //Verifying if the resolved ticket has been closed
        System.assertEquals(statusMapNametoID.get('CLOSED'),Incident.BMCServiceDesk__FKStatus__c);
    }
    
}