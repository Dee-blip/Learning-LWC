public  class HD_RestrictedAccess{

  public Static Boolean SKIP_TRIGGER = false;
  
  static HD_RestrictedAccess ins = null;
  
  static String CatContractor = 'Contractor Category';
  public List<BMCServiceDesk__Incident__c> NewTrigger = new LIst<BMCServiceDesk__Incident__c>(); 
  public List<BMCServiceDesk__Incident__c> OldTrigger = new LIst<BMCServiceDesk__Incident__c>(); 
  
  public static Boolean inprocess = false;
  Static Map<Id,BMCServiceDesk__Category__c> catMap = new Map<Id,BMCServiceDesk__Category__c>();

  private HD_RestrictedAccess(List<BMCServiceDesk__Incident__c> newversionObj){
  
   NewTrigger.addAll(newversionObj);
   //catMap.putAll(CategoryMap());
  }
  
  private HD_RestrictedAccess(List<BMCServiceDesk__Incident__c> newversionObj,List<BMCServiceDesk__Incident__c> oldobj)
  {
  
    NewTrigger.addAll(newversionObj);
    OldTrigger.addAll(oldobj);
    
  }

//Singleton pattern Method  
  public static HD_RestrictedAccess getInstance(List<BMCServiceDesk__Incident__c> newtrigger, List<BMCServiceDesk__Incident__c> oldtrigger,Map<Id,BMCServiceDesk__Category__c> categoryIdMap ){
    if(ins == null){
      ins = new HD_RestrictedAccess(newtrigger,oldtrigger);
    }
    if(catMap.size() <= 0 ){
        catMap.putAll(categoryIdMap);
    
    }
    return ins;
      
  }
  
  public static HD_RestrictedAccess getInstance(List<BMCServiceDesk__Incident__c> newtrigger,Map<Id,BMCServiceDesk__Category__c> categoryIdMap ){
    if(ins == null){
      ins = new HD_RestrictedAccess(newtrigger);
      if(catMap.size() <= 0 ){
        catMap.putAll(categoryIdMap);
    
      }
    }
    return ins;
      
  }
      

//Getting the MAP of categories

/*
  private static Map<String,BMCServiceDesk__Category__c> CategoryMap(){
  
      Map<String,BMCServiceDesk__Category__c> category_Map = new Map<String,BMCServiceDesk__Category__c>();
      List<BMCServiceDesk__Category__c> catList = new List<BMCServiceDesk__Category__c>();
      catList = [ Select Id,RA_Category_Group__c,name,RA_Config_Value__c,RA_Secondary_Queue__c From BMCServiceDesk__Category__c  Where RA_Category_Group__c = 'Restricted Area Access'];
      for(BMCServiceDesk__Category__c cat : catList)
      {
        category_Map.put(cat.Id,cat);
      }
      return category_Map;
  }
*/

  public static Boolean isRAA(String catid){
  
    if(catMap.containsKey(catid) && catMap.get(catid).RA_Category_Group__c == 'Restricted Area Access'){
      return true;
    }
    else{ 
      return false;
    }
  }

  public static void submitApprovals(List<BMCServiceDesk__Incident__c> incident_list){
    
     if(incident_list.size() > 0){
         List<Approval.ProcessSubmitRequest> app_list = new List<Approval.ProcessSubmitRequest>();
         
         for(BMCServiceDesk__Incident__c incident:incident_list){
            Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
            app.setObjectId(incident.id);
            app_list.add(app);
          } 
          
          List <Approval.ProcessResult> result = Approval.process(app_list);
     }     
  }

 
  
  public static  BMCServiceDesk__Category__c getRAACat(){
  
    BMCServiceDesk__Category__c cat = null;
    for(String key:catMap.keySet()){
           if(catMap.get(key).name == 'Restricted Area Access'){
              cat = catMap.get(key);
              break; 
           }
        
         }
         return cat;
  }
   
  public Static  Map<String,String >  allQueue(){
    Map<String,String> queue_map =  new Map<String,String>();
    List<Group> all_queue   = new List <Group>();
    all_queue = [select id,name from Group where type = 'Queue'];
    for(Group que : all_queue)
    { 
      queue_map.put(que.name,que.id);
    }
    return queue_map;
  }   
        
   
  public Static List <BMCServiceDesk__Task__c> getTasks(){
 
    
    List <BMCServiceDesk__Task__c> tasks = new List <BMCServiceDesk__Task__c>();
    tasks = [select id,ownerId,BMCServiceDesk__FKIncident__c from  BMCServiceDesk__Task__c where  BMCServiceDesk__FKCategory__c IN :catMap.keySet()];
    return tasks;
 
  }
  
  
  public  Boolean isControllerApproved(){
    integer i = 0;
    Boolean controller_approved = false;
    BMCServiceDesk__Incident__c oldobj = new BMCServiceDesk__Incident__c();
    for(BMCServiceDesk__Incident__c insobj : NewTrigger){ 
      if (OldTrigger.size() > i){
           oldobj = OldTrigger[i];
           if( oldobj.HD_RAA_Approval_Flag__c != 'Controller Approved' && insobj.HD_RAA_Approval_Flag__c == 'Controller Approved'){      
              controller_approved = true;
              break;
            }
           i++;
      }     
    }
   
   return controller_approved;
  }
  
  
  
  public static void SetSharing(List<BMCServiceDesk__Incident__c> incident_list){
  
      List<BMCServiceDesk__Incident__Share> incident_share_list = new List<BMCServiceDesk__Incident__Share>();
  
      for(BMCServiceDesk__Incident__c incident : incident_list){
        BMCServiceDesk__Incident__Share incidentShare = new BMCServiceDesk__Incident__Share();
        incidentShare.ParentId =  incident.Id;
        incidentShare.UserOrGroupId = incident.BMCServiceDesk__Client_Manager__c;
        incidentShare.RowCause = Schema.BMCServiceDesk__Incident__Share.RowCause.Approval_Sharing__c;
        incidentShare.AccessLevel = 'edit';
        incident_share_list.add(incidentShare);
      }
     insert incident_share_list;
  }
  

@future(callout=true)
  public static void TaskInsertion_Future(List<Id> ins_incident_id){
    
    List <BMCServiceDesk__Incident__c> incidents = [select id,BMCServiceDesk__incidentDescription__c,BMCServiceDesk__Client_Name__c,BMCServiceDesk__FKClient__c,BMCServiceDesk__FKCategory__c,ownerId From BMCServiceDesk__Incident__c where id In :ins_incident_id Limit 10];
    List<BMCServiceDesk__Task__c> tskl =  new List<BMCServiceDesk__Task__c>();
    String  rectypeid = null;
    rectypeid =  Schema.SObjectType.BMCServiceDesk__Task__c.getRecordTypeInfosByName().get('Restricted Access Task').getRecordTypeId();
    //Map<String,BMCServiceDesk__Category__c> cat_map =   CategoryMap();
    
     Map<Id,BMCServiceDesk__Category__c> cat_map  = new Map<Id,BMCServiceDesk__Category__c>();
     cat_map.putAll(catMap);

   for(BMCServiceDesk__Incident__c incident : incidents){
   
     BMCServiceDesk__Task__c tsk = new BMCServiceDesk__Task__c();
     tsk.BMCServiceDesk__FKIncident__c = incident.id;
     tsk.BMCServiceDesk__FKCategory__c = incident.BMCServiceDesk__FKCategory__c;
     
     if(cat_map.get(incident.BMCServiceDesk__FKCategory__c).RA_Config_Value__c != CatContractor ){
          tsk.Requestor__c = incident.BMCServiceDesk__Client_Name__c;
        }
    
     if(rectypeid != null){
       tsk.RecordTypeId = rectypeid;
     }
    
     tsk.BMCServiceDesk__taskDescription__c = incident.BMCServiceDesk__incidentDescription__c;
     tsk.BMCServiceDesk__FKClient__c = incident.BMCServiceDesk__FKClient__c;
     tsk.ownerId = incident.ownerId;
     tskl.add(tsk);
    }
  
     insert (tskl);
  }


 //Method for after insert
  public  void afterInsert(){

    if(NewTrigger.size() > 0){
        
      List<BMCServiceDesk__Incident__c> appr_inci_list = new List<BMCServiceDesk__Incident__c>();
      for(BMCServiceDesk__Incident__c insobj : NewTrigger){
                    
        if(  isRAA(insobj.BMCServiceDesk__FKCategory__c) == true)
        {
          appr_inci_list.add(insobj);
        }//if
    
      }//for
      
      if(appr_inci_list.size() > 0){
        setSharing(appr_inci_list);
        submitApprovals(appr_inci_list);
      }
          
    }//If
  
  }//afterInsert


  public void afterUpdateChanges(){

    List <BMCServiceDesk__Task__c>     upsert_task_list = new List <BMCServiceDesk__Task__c>();    
    List <BMCServiceDesk__Incident__c> tsk_inci_list    = new List <BMCServiceDesk__Incident__c>();
    List <BMCServiceDesk__Incident__c> appr_inci_list   = new List <BMCServiceDesk__Incident__c>();  
    List <BMCServiceDesk__Task__c>     all_tasks        = new List <BMCServiceDesk__Task__c>();
    List <Id> ins_id_list = new List<Id>();
   
    BMCServiceDesk__Category__c  category = new BMCServiceDesk__Category__c();
    Map<String,String>  queMap = new Map<String,String>();
   
    
    integer i = 0;
    String queue_id = null;
    
    if (isControllerApproved() == true){
      all_tasks =  getTasks(); 
      
    }// isControllerApproved
        
    if(NewTrigger.size() > 0   ){
              
      for(BMCServiceDesk__Incident__c insobj : NewTrigger){
       
        if(  isRAA(insobj.BMCServiceDesk__FKCategory__c) == true && OldTrigger.size() > i){
         
            BMCServiceDesk__Incident__c oldobj = OldTrigger[i];
                 
            if( oldobj.HD_RAA_Approval_Flag__c != 'Self Approved' && insobj.HD_RAA_Approval_Flag__c == 'Self Approved'){
              if(inprocess != true){
                 
                 appr_inci_list.add(insobj);
                 inprocess = true;               
               }                              
             }
                          
              if( (oldobj.HD_RAA_Approval_Flag__c != 'Manager Approved' && insobj.HD_RAA_Approval_Flag__c == 'Manager Approved') || 
                (oldobj.HD_RAA_Approval_Flag__c != 'Self Approved' && insobj.HD_RAA_Approval_Flag__c == 'Self Approved' &&  catMap.get(insobj.BMCServiceDesk__FKCategory__c).RA_Config_Value__c == CatContractor))
              {           
                ins_id_list.add(insobj.id);
              }        
              
              
              if( oldobj.HD_RAA_Approval_Flag__c != 'Controller Approved' && insobj.HD_RAA_Approval_Flag__c == 'Controller Approved'){
                 if(all_tasks.size() > 0 ){
                   for (BMCServiceDesk__Task__c tsk : all_tasks){
                      
                      if(tsk.BMCServiceDesk__FKIncident__c == insobj.id){
                        tsk.ownerId = insobj.ownerId;
                        upsert_task_list.add(tsk);
                        //break;
                     }
                   }
                 }
               }// if  oldobj.HD_RAA_Approval_Flag__c
    
        }//if isRAA
           i++;
      }//for newTrigger
    
    }//If
    
      
      
      if(ins_id_list.size() > 0  )
      {
        
        TaskInsertion_Future(ins_id_list);
      }   
    
      
     if( upsert_task_list.size() > 0)
     {
         HD_RestrictedAccess.SKIP_TRIGGER = true;
         update  upsert_task_list;     
         HD_RestrictedAccess.SKIP_TRIGGER = false;
     }
     

     if(appr_inci_list.size() > 0)
      {     
        submitApprovals(appr_inci_list);
      }
  
 
  }// afterUpdateChanges
  
  
  
 public  void beforeUpdateChanges(){

   
  if( isControllerApproved()  == true ){
    
    Integer i = 0; 
    String queue_id = null; 
    BMCServiceDesk__Incident__c oldobj = new BMCServiceDesk__Incident__c();
    BMCServiceDesk__Category__c category = new BMCServiceDesk__Category__c();
    
    List<BMCServiceDesk__Task__c>  update_tasks_list = new List <BMCServiceDesk__Task__c>();
    Map<String,String>  queMap = new Map<String,String>();
    
    queMap.putAll(allQueue());
  
    if(queMap.containsKey('Corporate Services')){
        queue_id = queMap.get('Corporate Services');
    }  
  
    if(NewTrigger.size() > 0 ){
 
      for(BMCServiceDesk__Incident__c insobj : NewTrigger){
    
        if( isRAA(insobj.BMCServiceDesk__FKCategory__c) == true && OldTrigger.size() > i){
        
          oldobj = OldTrigger[i];
                                                       
          if( oldobj.HD_RAA_Approval_Flag__c != 'Controller Approved' && insobj.HD_RAA_Approval_Flag__c == 'Controller Approved'){
          
            if( queue_id != null && queMap.size() > 0){
            
              category = catMap.get(insobj.BMCServiceDesk__FKCategory__c);                      
              queue_id = ((category.RA_Secondary_Queue__C != null  && queMap.containsKey(category.RA_Secondary_Queue__C))?  queMap.get(category.RA_Secondary_Queue__C) : queue_id);
              insobj.ownerId = queue_id;
              insobj.HD_Routing_Settings__c = 'Override Routing';
      
             }// if queue_id
         
          } // if oldobj.HD_
       
    
        } //isRAA
        
        i++;
        
       }//NeTrigger
      }//NewtriggerSize
    } //if isControllerApproved
     
  }// beforeUpdateChanges 
    

}//Class Ends