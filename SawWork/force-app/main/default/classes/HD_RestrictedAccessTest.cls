/*
* File Name: HD_RestrictedAccessTest
* Description : 
* @author :
* Modification Log ===============================================================
* Date 				      Author 				      Modification
* Aug 08th, 2020    Aneesh Budnar       PRTORES-1810 - Code scanner fixes
* Dec 23rd, 2020    Aneesh Budnar       PRTORES-342 - Test class code coverage - 6th and Final
*/
@IsTest(seeallData=False)
private class HD_RestrictedAccessTest{
    
    
    static List<BMCServiceDesk__Urgency__c> urgency3;
    static List<BMCServiceDesk__Impact__c> impactlow;
    
    static List<BMCServiceDesk__Category__c> cont_categoryList;
    static List<BMCServiceDesk__Category__c> blrcs_categoryList;
    static List<BMCServiceDesk__CategoryTypes__c> ctypes_list;
    
    //adding category map
    static Map<Id,BMCServiceDesk__Category__c> categoryIDmap = new  Map<Id,BMCServiceDesk__Category__c>(); 
    
    static Group  da_group ;
    
    Static BMCServiceDesk__CategoryTypes__c DC_Type = null;
    Static BMCServiceDesk__CategoryTypes__c NI_Type = null;
    
    Static BMCServiceDesk__Category__c raa_cat;
    Static BMCServiceDesk__Category__c contractor_cat;
    Static BMCServiceDesk__Category__c blrcs_cat;
    Static BMCServiceDesk__Category__c NI_cat;
    
    Private Static BMCServiceDesk__CategoryTypes__c getCTypes(String ctype_name){
        
        BMCServiceDesk__CategoryTypes__c rctype = null;
        List<BMCServiceDesk__CategoryTypes__c>  cd_types = [select id from  BMCServiceDesk__CategoryTypes__c where name = :ctype_name limit 1];
        
        if (cd_types.size() <= 0){
            BMCServiceDesk__CategoryTypes__c ctype = new BMCServiceDesk__CategoryTypes__c(Name = ctype_name );       
            insert ctype;
            rctype = ctype;
        }else{
            rctype = cd_types[0];
        }  
        
        return rctype;
        
    }
    
    
    
    
    private Static BMCServiceDesk__Category__c getCategory(String name, String ctype_id, String cs_queue, String cct){
        
        List<BMCServiceDesk__Category__c> catlist =  
            [select id,name,RA_Category_Group__c, RA_Secondary_Queue__c,RA_Config_Value__C  FROM  BMCServiceDesk__Category__c WHERE name =:name and BMCServiceDesk__FKCategoryType__c = :ctype_id and RA_Category_Group__c = 'Restricted Area Access'];
        
        
        if(catlist.size() <= 0) {
            BMCServiceDesk__Category__c raa_category = new BMCServiceDesk__Category__c();
            raa_category.Name =  name;     
            raa_category.BMCServiceDesk__FKCategoryType__c = ctype_id;
            raa_category.BMCServiceDesk__AvailableForIncidents__c = true;
            raa_category.RA_Category_Group__c = 'Restricted Area Access';      
            
            if(cct != ''){
                raa_category.RA_Config_Value__C = 'Contractor Category';
            }
            
            if(cs_queue != '')
            {
                raa_category.RA_Secondary_Queue__c = cs_queue;
            }
            return raa_category;   
        }else
        {
            return catlist[0];
        }
        
    }
    
    
    
    private  static BMCServiceDesk__Incident__c getIncident(String c_id){
        BMCServiceDesk__Incident__c inc = new BMCServiceDesk__Incident__c();
        inc.BMCServiceDesk__FKUrgency__c = urgency3[0].id;
        inc.BMCServiceDesk__incidentDescription__c = 'Test Description ';
        inc.BMCServiceDesk__FKClient__c = system.userInfo.getUserId();
        inc.BMCServiceDesk__FKStatus__c  = HD_Test_Data_Factory.statusMap.get('ASSIGNED');
        User contextUser = [SELECT Id, ManagerId FROM User WHERE Username like '%abudnar@akamai.com%' LIMIT 1];
        inc.OwnerId = contextUser.Id;
        inc.BMCServiceDesk__Client_Manager__c =  contextUser.ManagerId;
        inc.BMCServiceDesk__FKImpact__c  = impactlow[0].id;  
        inc.BMCServiceDesk__FKCategory__c = c_id;     
        
        return inc;  
    }
    
    private static void Init()
    {
        try{       
            HD_Test_Data_Factory.init();
            
            urgency3 = [select Id from BMCServiceDesk__Urgency__c where NAME = 'Severity 3' limit 1];
            if(urgency3.size() <= 0 )
            {
                BMCServiceDesk__Urgency__c  Urgency  = new BMCServiceDesk__Urgency__c();
                Urgency.Name = 'Severity 3';
                urgency3.add(Urgency);
                insert urgency3;
            }
            
            
            HD_Ticket_Priority__c priority_setting;
            
            if(HD_Ticket_Priority__c.getInstance('3') == null){
                
                priority_setting = new HD_Ticket_Priority__c();
                priority_setting.Name = '3';
                priority_setting.Urgency_Id__c = urgency3[0].Id;
                priority_setting.Urgency_Name__c = 'Severity 3';
                insert  priority_setting;
                
            }
            
            
            
            impactlow =  [ select Id from BMCServiceDesk__Impact__c where NAME = 'LOW' LIMIT 1 ];
            if (impactlow.size() <= 0 )
            {
                BMCServiceDesk__Impact__c impact = new BMCServiceDesk__Impact__c();
                impact.Name = 'LOW';
                impactlow.add(impact);
                insert impactlow;
            }         
            System.debug('---->'+impactlow[0].Id);
            
            
            
            DC_Type = getCTypes('Q_DataCenter_Access');
            upsert DC_Type;
            
            
            raa_cat = getCategory('Restricted Area Access',DC_Type.id,'','');
            insert raa_cat;
            
            
            blrcs_cat = getCategory('Bangalore India', DC_Type.id, 'BLR_CS','');
            insert blrcs_cat; 
            
            List<BMCServiceDesk__Category__c> categorylistforMap = new List<BMCServiceDesk__Category__c>();
            //categorylistforMap.add(DC_Type);
            categorylistforMap.add(raa_cat);
            categorylistforMap.add(blrcs_cat);
            
            for( BMCServiceDesk__Category__c cat: categorylistforMap)
            {
                categoryIDmap.put(cat.id, cat);
            }
            
            
        }
        catch(Exception e)
        {
            System.debug('Error Occured ------------> ' +e);
        }      
    }//
    
    static TestMethod void ContractorCategoryFlow(){
        
        Init();
        contractor_cat = getCategory('Contractor Category',DC_Type.id,'','cct');
        insert contractor_cat;
        categoryIDmap.put(contractor_cat.Id, contractor_cat);
        BMCServiceDesk__Incident__c incidenttest = getIncident(contractor_cat.id);
        insert incidenttest;
        
        List<BMCServiceDesk__Incident__c> incilisttest = new List<BMCServiceDesk__Incident__c>();
        incilisttest.add(incidenttest);
        
        
        HD_RestrictedAccess restAcctest = HD_RestrictedAccess.getInstance(incilisttest,categoryIDmap);
        
        BMCServiceDesk__Incident__c incident = getIncident(contractor_cat.id);
        insert incident;
        
        BMCServiceDesk__Incident__c incident2 = getIncident(contractor_cat.id);
        insert incident2;
        
        List<BMCServiceDesk__Incident__c> incilist = new List<BMCServiceDesk__Incident__c>();
        List<BMCServiceDesk__Incident__c> incilist_old = new List<BMCServiceDesk__Incident__c>();
        
        incilist_old.add(incident2);
        incilist.add(incident);
        
        HD_RestrictedAccess.submitApprovals(incilist);
        HD_RestrictedAccess restAcc1 = HD_RestrictedAccess.getInstance(incilist,incilist_old,categoryIDmap);
        restAcc1.afterUpdateChanges();
        
        
        raa_cat = HD_RestrictedAccess.getRAACat();      
        
        List<Id> inci_id_list = new List <Id>();
        for( BMCServiceDesk__Incident__c inc : incilist){
            inci_id_list.add(inc.Id);
            
        }
        
        HD_RestrictedAccess.SetSharing(incilist); 
        
        Test.startTest() ;
        HD_RestrictedAccess.TaskInsertion_Future(inci_id_list);
        Test.stopTest();
        
        List<BMCServiceDesk__Task__c>  tsklst = [select id,ownerid from BMCServiceDesk__Task__c where BMCServiceDesk__FKIncident__c = :incident.id Limit 1];      
        // System.assertNotEquals(tsklst.size(),0);
        //System.assertEquals(tsklst[0].ownerId,incident.ownerId);
        System.debug('--------------------->'+categoryIDmap);
        
        
        
    }//
    
    
    
    static TestMethod void ControllerFlow(){
        
        Init();
        
        blrcs_cat = getCategory('Bangalore India',DC_Type.id,'BLR_CS','');
        upsert blrcs_cat;
        BMCServiceDesk__Incident__c incident = getIncident( blrcs_cat.id);
        insert incident;
        
        BMCServiceDesk__Incident__c incident2 = getIncident( blrcs_cat.id);
        insert incident2; 
        
        
        
        List<BMCServiceDesk__Incident__c> incilist = new List<BMCServiceDesk__Incident__c>();      
        List<BMCServiceDesk__Incident__c> incilist_old = new List<BMCServiceDesk__Incident__c>();
        
        
        incilist_old.add(incident2);
        incident.HD_RAA_Approval_Flag__c = 'Controller Approved';
        update incident;
        incilist.add(incident);      
        
        HD_RestrictedAccess restAcc = HD_RestrictedAccess.getInstance(incilist,incilist_old,categoryIDmap);
        restAcc.afterUpdateChanges();
        
        restAcc.beforeUpdateChanges();
        
        System.assertNotEquals(incident.ownerId,null);
        
        
    }//
    
    /*
static TestMethod void NormalFlow(){
Init();


BMCServiceDesk__Incident__c incident = getIncident( raa_cat.id);
BMCServiceDesk__Incident__c incident_old =  incident;


List<BMCServiceDesk__Incident__c> incilist = new List<BMCServiceDesk__Incident__c>();

List<BMCServiceDesk__Incident__c> incilist_old = new List<BMCServiceDesk__Incident__c>();


incilist_old.add(incident_old);

incident.HD_RAA_Approval_Flag__c = 'Controller Approved';
update incident;
incilist.add(incident);

HD_RestrictedAccess.createTask(raa_cat,incident);

HD_RestrictedAccess restAcc = HD_RestrictedAccess.getInstance(incilist,incilist_old);

restAcc.beforeUpdateChanges();      

System.assertNotEquals(incident.ownerId,null);


}//

*/
    
}