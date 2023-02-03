/*
Template: Apex Class/Trigger Template 

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : Used as apart of Utility Class

Purpose : an implementation for Change request Managment
          
Usage : used as an implementation for the trigger support class.
          
Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Trigger Associated : [ HD_ChangeReqMgmt, ]
Class used : 
              
*/
public  class HD_ChangeReqMgmt_class {

//class instance
private static HD_ChangeReqMgmt_class chreqInstance = null;

//defining the Trigger New version and Old version List
private List<BMCServiceDesk__Change_Request__c> newVerTrigger = null;
private List<BMCServiceDesk__Change_Request__c> oldVerTrigger = null;
private static List<GroupMember> groups;
private static List<sObject> sObjectsList;
   
   //Singelton method
    public static HD_ChangeReqMgmt_class getInstance( List<BMCServiceDesk__Change_Request__c> chgreqnewTriggerversion )
    {

        //adding lazy loading of class instance
        if(chreqInstance == null)
        {
          chreqInstance = new HD_ChangeReqMgmt_class( chgreqnewTriggerversion );
        }
     return  chreqInstance;
    }
    
    public static HD_ChangeReqMgmt_class getInstance(List<BMCServiceDesk__Change_Request__c> chngTrigger, List<BMCServiceDesk__Change_Request__c> chngOldTrigger)
    {
         if(chreqInstance == null || chreqInstance.oldVerTrigger == null )
        {
          chreqInstance = new HD_ChangeReqMgmt_class( chngTrigger,chngOldTrigger );
        }
         return  chreqInstance;
    }
    
   //Constructors
    private HD_ChangeReqMgmt_class( List<BMCServiceDesk__Change_Request__c> newTriggerversion ) {
        HD_CMR_SETTINGS__c SETTING_CABQueueId = HD_CMR_SETTINGS__c.getInstance('CAB_Queue_Id');
        groups =  [select Id from GroupMember where Group.Type = 'Queue' and GroupId = :SETTING_CABQueueId.Value__c and UserOrGroupId = :UserInfo.getUserId()];
        System.debug('GSIZE '+groups.size());
        sObjectsList = Database.query('SELECT Id,Name From BMCServiceDesk__Status__c');
        
        if( newTriggerversion.size() > 0 )
        {
           newVerTrigger  = new List<BMCServiceDesk__Change_Request__c>();
           newVerTrigger.addAll(newTriggerversion);
        }

    }
        
    private HD_ChangeReqMgmt_class( List<BMCServiceDesk__Change_Request__c> newTriggerversion, List<BMCServiceDesk__Change_Request__c> oldTriggerversion ) {
        HD_CMR_SETTINGS__c SETTING_CABQueueId = HD_CMR_SETTINGS__c.getInstance('CAB_Queue_Id');
        groups =  [select Id from GroupMember where Group.Type = 'Queue' and GroupId = :SETTING_CABQueueId.Value__c and UserOrGroupId = :UserInfo.getUserId()];
        System.debug('GSIZE '+groups.size());
        sObjectsList = Database.query('SELECT Id,Name From BMCServiceDesk__Status__c');

        if( newTriggerversion.size() > 0 )
        {
           newVerTrigger  = new List<BMCServiceDesk__Change_Request__c>();
           newVerTrigger.addAll(newTriggerversion);
        }
        
        if( oldTriggerversion.size() > 0 )
        {
        
           oldVerTrigger  = new List<BMCServiceDesk__Change_Request__c>();
           oldVerTrigger.addAll(oldTriggerversion);
        }
    }//HD_ChangeReqMgmt_class()

    /*
     this method is used to set the data values for the record during create
     usage: before insert
    */
    public void  InitialSaveDataSetter()
    {     
        for(BMCServiceDesk__Change_Request__c chreq : newVerTrigger )
        {
          if( chreq.BMCServiceDesk__FKInitiator__c == null )
            chreq.BMCServiceDesk__FKInitiator__c = chreq.OwnerId;

        }

    }
      
   
   
   
  /*    
  public void setPriority(){
  
     Integer i =0;
     LIST<BMCServiceDesk__Priority__c> priorityList = [SELECT id,BMCServiceDesk__FKUrgency__c,BMCServiceDesk__FKImpact__c FROM BMCServiceDesk__Priority__c LIMIT 100];
     
     for( BMCServiceDesk__Change_Request__c chr:  newVerTrigger){
      
       if( oldVerTrigger == null || ( oldVerTrigger[i].BMCServiceDesk__FKUrgency__c != chr.BMCServiceDesk__FKUrgency__c || oldVerTrigger[i].BMCServiceDesk__FKImpact__c != chr.BMCServiceDesk__FKImpact__c))
         
         for( BMCServiceDesk__Priority__c priority : priorityList){
         
           if(priority.BMCServiceDesk__FKUrgency__c == chr.BMCServiceDesk__FKUrgency__c && priority.BMCServiceDesk__FKImpact__c == chr.BMCServiceDesk__FKImpact__c)
            chr.BMCServiceDesk__FKPriority__c = priority.Id;
          }
      }
   
     i++;
  } //Method
 */    
 
 
  public void validateSchedulestartDateSponsorAppr(){
      
    HD_CMR_SETTINGS__c SETTING_TESTMODE = HD_CMR_SETTINGS__c.getInstance('Test_Mode');
    if(SETTING_TESTMODE != NULL && SETTING_TESTMODE.Value__c == 'FALSE'){
     integer i =0;
     DateTime dt =  DateTime.now();
     
     for( BMCServiceDesk__Change_Request__c chr:  newVerTrigger){
      
     
     if( oldVerTrigger != null && oldVerTrigger.size() > 0 &&oldVerTrigger[i] != null && oldVerTrigger[i].CR_Approval_Status__c != NULL && chr.CR_Approval_Status__c != NULL && !oldVerTrigger[i].CR_Approval_Status__c.Equals('SPONSOR APPROVED') 
       &&  chr.CR_Approval_Status__c.Equals('SPONSOR APPROVED') && chr.BMCServiceDesk__Scheduled_Start_Date__c < dt  && chr.BMCServiceDesk__Change_Category__c != 'Emergency Change'){
       
       
         chr.addError('Sponsor should approve the Change Request '+chr.Name+' before its Scheduled Start Date '); 
       
       }
     
      i++;
     }
  
      }
      else{
        System.debug('validateSchedulestartDateSponsorAppr() not executed');  
      }
  }
      
  public void grantEditableAccess(){

    Integer i =0;
    boolean delete_required  = false;
    List<BMCServiceDesk__Change_Request__Share> change_share_list = new List<BMCServiceDesk__Change_Request__Share>();
       
    for( BMCServiceDesk__Change_Request__c chr:  newVerTrigger){
      
       if( oldVerTrigger == null || ( oldVerTrigger[i].HD_Sponsor__c != chr.HD_Sponsor__c ) ){
         

          BMCServiceDesk__Change_Request__Share ChangeShare = new BMCServiceDesk__Change_Request__Share();
          ChangeShare.ParentId = chr.ID;
          ChangeShare.UserOrGroupId =  chr.HD_Sponsor__c;
          ChangeShare.RowCause = Schema.BMCServiceDesk__Change_Request__Share.RowCause.Sponsor__c;
          ChangeShare.AccessLevel = 'edit';
          change_share_list.add(ChangeShare);
       }
       
       if( oldVerTrigger == null || ( oldVerTrigger[i].Change_Coordinator_Primary__c != chr.Change_Coordinator_Primary__c ) ){   
          
          BMCServiceDesk__Change_Request__Share ChangeShareCordinator = new BMCServiceDesk__Change_Request__Share();
          ChangeShareCordinator.ParentId = chr.ID;
          ChangeShareCordinator.UserOrGroupId =  chr.Change_Coordinator_Primary__c;
          ChangeShareCordinator.RowCause = Schema.BMCServiceDesk__Change_Request__Share.RowCause.Coordinator__c;
          ChangeShareCordinator.AccessLevel = 'edit';
          change_share_list.add(ChangeShareCordinator);
          
            
       }
               
       if(oldVerTrigger != null && (oldVerTrigger[i].HD_Sponsor__c != chr.HD_Sponsor__c ||  oldVerTrigger[i].Change_Coordinator_Primary__c != chr.Change_Coordinator_Primary__c)){
             
         delete_required  = true;
       }
       i++;           
     }
       
     if(change_share_list.size() > 0)
         insert change_share_list;
       
     if (delete_required == true)
     {
          List<BMCServiceDesk__Change_Request__Share> SharingList = [Select Id,UserOrGroupId,ParentId,RowCause from BMCServiceDesk__Change_Request__Share where RowCause = 'Sponsor__c' or RowCause = 'Coordinator__c' ];
          List<BMCServiceDesk__Change_Request__Share> deleteList = new List<BMCServiceDesk__Change_Request__Share>(); 
          i = 0;
         
          for( BMCServiceDesk__Change_Request__c chr:  newVerTrigger){
      
              if( oldVerTrigger[i].HD_Sponsor__c != chr.HD_Sponsor__c ){
              
                  for(BMCServiceDesk__Change_Request__Share chrShare : SharingList){
                     if(chrShare.ParentId == chr.Id && chrShare.UserOrGroupId == oldVerTrigger[i].HD_Sponsor__c && chrShare.RowCause == 'Sponsor__c' ){
                        deleteList.add(chrShare);
                     }
                  }
                                
              }
              
              if( oldVerTrigger[i].Change_Coordinator_Primary__c != chr.Change_Coordinator_Primary__c){
              
                  for(BMCServiceDesk__Change_Request__Share chrShare : SharingList){
                     if(chrShare.ParentId == chr.Id && chrShare.UserOrGroupId == oldVerTrigger[i].Change_Coordinator_Primary__c && chrShare.RowCause == 'Coordinator__c' ){
                        deleteList.add(chrShare);
                     }
                  }
                                
              }
              
              i++;          
       
          }
          
          if(deleteList.size() > 0 )
                 delete deletelist;
                 
       
       }
 
  } //Method    
      
      
  public void PicklistToLookup(String pickCol, String lookupCol, String objName,String colLabel){

    if(oldVerTrigger != null){
      Boolean col_changed = false;
      integer i =0;
      for(SObject chreq : newVerTrigger ){

              SObject  oldchreq = oldVerTrigger[i];
              if (chreq.get(pickCol) != oldchreq.get(pickCol)  || chreq.get(lookupCol) != oldchreq.get(lookupCol)){
                col_changed = true;
                break;  
              }
       }
       if (!col_changed)
       return;
    }
        
       
       Map<string,sObject> sobjNames = new Map<string,sObject>() ;
       Map<string,sObject> sobjIds = new Map<string,sObject>() ;

       for( sObject st : sObjectsList)
         { 
           sobjNames.put((String) st.get('Name'),st);
           sobjIds.put((String) st.get('Id'),st);
         }
       
        String pickVal = '';
        String lookupVal = '';
        
        if(oldVerTrigger == null || oldVerTrigger.size() < 1){
        
           for(SObject chreq : newVerTrigger ){
             pickVal = (String) chreq.get(pickCol);
             lookupVal = (String) chreq.get(lookupCol);                              
              
                 if( String.isNotBlank(pickVal) ){
                   chreq.put(lookupCol, (String) sobjNames.get(pickVal).get('id') );
                 }  
                  else if( String.isNotBlank(lookupVal) ){
                     chreq.put(pickCol, (String) sobjIds.get(lookupVal).get('Name') );
                 }
                 try{
             }catch (Exception e){
             
              chreq.addError('Invalid selection for '+colLabel);
             }
           
           }
        
         }else{  
            integer i = 0;
            for(SObject chreq : newVerTrigger ){

                SObject  oldchreq = oldVerTrigger[i];
                pickVal = (String) chreq.get(pickCol);
                lookupVal = (String) chreq.get(lookupCol);
               try{
                 
                if ( pickVal != ((String) oldchreq.get(pickCol)) ){
                   chreq.put(lookupCol, (String) sobjNames.get(pickVal).get('id') );
                }
                else if ( lookupVal != ((String) oldchreq.get(lookupCol)) ){
                  chreq.put(pickCol, (String) sobjIds.get(lookupVal).get('Name') );
                }
                }catch (Exception e){
                
                  chreq.addError('Invalid selection for '+colLabel);
                }
         
                i++;
             }
       }
        
  }//PicklistToLookup
     
   
   /*
   public void verifyLockedCMRUpdate(){
      
     
     HD_CMR_SETTINGS__c SETTING_CABQueueId = HD_CMR_SETTINGS__c.getInstance('CAB_Queue_Id');
     HD_CMR_SETTINGS__c SETTING_AUTOLOCK = HD_CMR_SETTINGS__c.getInstance('Auto_Lock');
     
      System.debug('CMR SET '+SETTING_AUTOLOCK.Value__c+'---'+SETTING_CABQueueId.Value__c);
      
     if( SETTING_AUTOLOCK == NULL || SETTING_AUTOLOCK.Value__c != 'true' || SETTING_CABQueueId == NULL || SETTING_CABQueueId.Value__c == '' )
      return;
      
    
    
       
     System.debug('Error here');  
     //List<GroupMember> groups =  [select Id from GroupMember where Group.Type = 'Queue' and GroupId = :SETTING_CABQueueId.Value__c and UserOrGroupId = :UserInfo.getUserId()];
     //System.debug('GSIZE '+groups.size());
     integer i = 0;
     
     for(BMCServiceDesk__Change_Request__c chreq : newVerTrigger ){
     
      System.debug('GSIZE ---- '+groups.size()+' ---- '+chreq.Change_Locked__c+' ------ '+oldVerTrigger[i].Change_Locked__c);
     //if (groups.size() < 1  && chreq.Change_Locked__c == true && oldVerTrigger[i].Change_Locked__c == true && chreq.HD_Change_status__C  != 'AUTO CLOSED' ){
       if (groups.size() < 1  && chreq.Change_Locked__c == true && oldVerTrigger[i].Change_Locked__c == true && chreq.Auto_Closed__c  == FALSE ){
          chreq.addError('CMR is auto locked. Contact CMR CAB Managers to update the CMR');   
            
      }
      i++;
          
     }      
        
   
   }//method verifyLockedCMRUpdate
   
   */

   public void verifyResourceEmail(){
     
     for(BMCServiceDesk__Change_Request__c chreq : newVerTrigger ){
       
       if( String.isBlank(chreq.HD_Resources__c))
         continue;
         
         String emailString = (  chreq.HD_Resources__c.endsWith(',') ?  chreq.HD_Resources__c.trim() : (chreq.HD_Resources__c.trim()+','));
         if(  String.isNotBlank(chreq.HD_Resources__c) && Pattern.matches('^((\\w+([-+.\']\\w+)*@akamai\\.com*([\\s]*?[,][\\s]*))*)$' , emailString) != true  ) 
         { chreq.HD_Resources__c.addError('Please enter valid akamai email address for Resources');
           return ;
         }

         for(String email : emailString.split(',')){
           if(Pattern.matches('^((\\w+([-+.\']\\w+)*@akamai\\.com*([\\s]*?[\\s]*))*)$' , email.trim()) != true)
           {
             chreq.addError('Please enter valid email address seperated by comma. \''+email+'\' is not valid.');
           }
         }
     }
       
   }//verifyResourceEmail
   
   
     
   public void verifyNotificationEmail(){
      integer i = 0;
      for(BMCServiceDesk__Change_Request__c chreq : newVerTrigger ){
       
       if( String.isBlank(chreq.Status_Change_Notification__c) ||(oldVerTrigger != null &&  oldVerTrigger[i].Change_Coordinator_Primary__c == chreq.Change_Coordinator_Primary__c))
         continue;
         
         String emailString = (  chreq.Status_Change_Notification__c.endsWith(',') ?  chreq.Status_Change_Notification__c.trim() : (chreq.Status_Change_Notification__c.trim()+','));
         if(  String.isNotBlank(chreq.Status_Change_Notification__c) && Pattern.matches('^((\\w+([-+.\']\\w+)*@akamai\\.com*([\\s]*?[,][\\s]*))*)$' , emailString) != true  ) 
         { chreq.Status_Change_Notification__c.addError('Please enter valid akamai email address for Resources');
           return ;
         }

         for(String email : emailString.split(',')){
           if(Pattern.matches('^((\\w+([-+.\']\\w+)*@akamai\\.com*([\\s]*?[\\s]*))*)$' , email.trim()) != true)
           {
             chreq.addError('Please enter valid email address seperated by comma. \''+email+'\' is not valid.');
             
           }
         }
         i++;
     }
     
   
   }//method
   

     
    //Send email notifications to Resources,Status Notification email addressess and choordinators added in related lists.
    //Email will be sent on status change.
    public void sendNotification(){
    
      //get from address
      HD_CMR_SETTINGS__c HD_TICKETING_EMAIL_ID = HD_CMR_SETTINGS__c.getInstance('HDTicketing_Email_Id');
      // get email template id.
      
     HD_CMR_SETTINGS__c NOEMAILS = HD_CMR_SETTINGS__c.getInstance('No_Email_Resources');   
       
      Integer i = -1;     
      List<String> chrIds = new List<String>();      
      //List<String> toEmailList  = new List<String>();
      Map<String,List<String>> chrEmails = new MAP<String,String[]>();
      Map<ID,BMCServiceDesk__Change_Request__c> chrMap = new Map<ID,BMCServiceDesk__Change_Request__c>();
       
       
       for(BMCServiceDesk__Change_Request__c chreq : newVerTrigger ){
         i += 1;
         List<String> toEmailList  = new List<String>();  
         if(oldVerTrigger != null && oldVerTrigger[i].HD_Change_Status__c != chreq.HD_Change_Status__c ){   
           
            if( !String.ISBLANK(chreq.HD_Resources__c ))
            {
              LIST<String> rs_emaillst;
              if(NOEMAILS != NULL && NOEMAILS.Value__c.trim() != ''){
                rs_emaillst = new LIST<String>();
                Boolean adrsemail = true;
                
                for(String rsemail : chreq.HD_Resources__c.split(',')){
                  adrsemail = true;
                  for(String noemail : NOEMAILS.Value__c.split(',')){
                     if(noemail == rsemail){
                       adrsemail = false;
                       break;
                       }
                      
                  }
                  
                  if (adrsemail == true){
                     rs_emaillst.add(rsemail);
                  }
                  
                }
                  if (rs_emaillst.size() > 0)
                       toEmailList.addAll(rs_emaillst);
                       
              }else{
                     toEmailList.addAll(chreq.HD_Resources__c.split(','));
              }
            }  
            
            
            if( !String.ISBLANK(chreq.Status_Change_Notification__c ))
              toEmailList.addAll(chreq.Status_Change_Notification__c.split(',')); 
                 
            chrEmails.put(chreq.id,toEmailList);
            chrmap.put(chreq.id,chreq);
    
                                              
         }
       
       }
       
       //add related list coordinators emails ids.
       String[] emailIds =  new List<String>();
       for( Change_coordinator__c ch :   [select Id,User__r.Email,Change_request__c FROM  Change_coordinator__c where Change_Request__c  IN :chrEmails.keySet()]){
   
           emailIds =  chrEmails.get(ch.Change_request__c);
           emailIds.add(ch.User__r.Email);
           chrEmails.put(ch.Change_request__c, emailIds);

       }
       
       Messaging.SingleEmailMessage[] emailMessageList = new List<Messaging.SingleEmailMessage> ();
       String[] toEmailAddresses =  new List<String>();
       BMCServiceDesk__Change_Request__c chreq;
       for (String chrid : chrEmails.keySet()){
          
         toEmailAddresses = chrEmails.get(chrid);
         chreq =   chrMap.get(chrid);

         if(toEmailAddresses != null && toEmailAddresses.size() > 0){
         
           Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
           mail.setToAddresses(toEmailAddresses);
           mail.setSubject('Change Request (Ref:CR:'+chreq.Name+') has been updated  '); 

           String textBody = 'Change Request '+chreq.Name+' has been updated.';
           textBody += mailBody(chreq);
           mail.setPlainTextBody(textBody);    
           emailMessageList.add(mail);  
         } 
        
       }   
         
       if(emailMessageList.size() > 0)
         Messaging.sendEmail(emailMessageList);
       
  
     }//method sendNotification
     
     
     
     public String mailBody(BMCServiceDesk__Change_Request__c chreq ){

        String textBody = '\n\nChange Request details - ';
        textBody += '\nOwner: '+chreq.HD_Owner_Name__c;
        textBody += '\nChange Category: '+chreq.BMCServiceDesk__Change_Category__c;
        textBody += '\nChange Summary: '+chreq.Change_Summary__c;
        textBody += '\nScheduled Start Date: '+chreq.BMCServiceDesk__Scheduled_Start_Date__c+' UTC (YYYY-MM-DD)';
        textBody += '\nScheduled End Date: '+chreq.BMCServiceDesk__Scheduled_End_Date__c +' UTC (YYYY-MM-DD)'; 
        textBody += '\nSponsor: '+chreq.HD_Sponsor_Name__c;
        textBody += '\nChange Status: '+chreq.HD_Change_Status__c;
        textBody += '\n\n Click on link to view more details -  '+URL.getSalesforceBaseUrl().toExternalForm()+'/'+chreq.id;

        return textBody;
     }

     
    
   public static void remindUnclosed(){
   System.debug('ABCDE -');
   
   LIST<BMCServiceDesk__Change_Request__c> chrs = [select NAME, ID, Change_summary__c,BMCServiceDesk__Scheduled_Start_Date__c,BMCServiceDesk__Scheduled_End_Date__c,
                                                   HD_SPONSOR__r.NAME,HD_SPONSOR__r.ID,HD_SPONSOR__r.Email,HD_SPONSOR__r.IsActive,
                                                   Change_Coordinator_Primary__r.IsActive,Change_Coordinator_Primary__r.ID,Change_Coordinator_Primary__r.Name,Change_Coordinator_Primary__r.EMail,owner.Name,Owner.EMail,owner.IsActive
                                                   from BMCServiceDesk__Change_Request__c where HD_Change_status__C = 'COMPLETED' OR HD_Change_status__C = 'IN PROGRESS'];
 
        
        MAP<String,SET<BMCServiceDesk__Change_Request__c>> UserChr = new MAP<String,SET<BMCServiceDesk__Change_Request__c>>() ;
        System.debug('CRM1');
        for(BMCServiceDesk__Change_Request__c chr : chrs){
            BMCServiceDesk__Change_Request__c ch ;
              System.debug('CRM2 -'+chr.Name);

            if(chr.BMCServiceDesk__Scheduled_End_Date__c.addDays(3) <= System.now() && chr.BMCServiceDesk__Scheduled_End_Date__c.addDays(4) > System.now() ){
            
              System.debug('CRM Add 3day -'+chr.Name);
               ch = chr;
            
            }
          
            if(chr.BMCServiceDesk__Scheduled_End_Date__c.addDays(7) <= System.now() && chr.BMCServiceDesk__Scheduled_End_Date__c.addDays(8) > System.now() ){
            
              System.debug('CRM Add 7 day -'+chr.Name);
               ch = chr;
            
            }
            System.debug('CRM ab - '+ System.now().format('E'));
            
            HD_CMR_SETTINGS__c SETTING_REMINDWEEK = HD_CMR_SETTINGS__c.getInstance('Close_Reminder_Week_Day');
            if(chr.BMCServiceDesk__Scheduled_End_Date__c.addDays(8) <= System.now() && SETTING_REMINDWEEK != NULL && SETTING_REMINDWEEK.Value__c == System.now().format('E'))
            {
               System.debug('CRM Add Above week -'+chr.Name);
               ch = chr;
            }
        
            
            if(ch != null)
            {
            System.debug('CRM IF CH -'+ch.Name);
            SET<BMCServiceDesk__Change_Request__c> mapList = new SET<BMCServiceDesk__Change_Request__c>() ;
            SET<BMCServiceDesk__Change_Request__c> mapList1 = new SET<BMCServiceDesk__Change_Request__c>() ;
            SET<BMCServiceDesk__Change_Request__c> mapList2 = new SET<BMCServiceDesk__Change_Request__c>() ;
             
             
             if (UserChr.containsKey(ch.HD_SPONSOR__r.Email) ){
             
              mapList =  UserChr.get(ch.HD_SPONSOR__r.Email);
             
             }
              System.debug('CRM IF CH2 -'+ch.Name);
              System.debug('CRM IF mail2 - '+ch.HD_SPONSOR__r.Email);
              
              mapList.add(ch);
              if( ch.HD_SPONSOR__r.IsActive == true )
               { UserChr.put(ch.HD_SPONSOR__r.Email,mapList);
               } 
             
             
              if (UserChr.containsKey(ch.Owner.Email)){
             
               mapList1 =  UserChr.get(ch.owner.Email);
             
             }
             
             
              mapList1.add(ch);
              if(ch.owner.isActive == true){
              UserChr.put(ch.owner.Email,mapList1);
              System.debug('CRM IF CH3 -'+ch.Name);
             }
              

              if (UserChr.containsKey(ch.Change_Coordinator_Primary__r.Email)){
             
              mapList2 =  UserChr.get(ch.Change_Coordinator_Primary__r.Email);
             
             }
              mapList2.add(ch);
              if(ch.Change_Coordinator_Primary__r.isActive == true){
                UserChr.put(ch.Change_Coordinator_Primary__r.Email,mapList2);
                System.debug('CRM IF CH4 -'+ch.Name);
              }
              
              
              
              System.debug('CRM keysize -'+UserChr.keyset().size());
        }
     }// For Loop
     
     System.debug('CRM5 - '+UserChr.keyset().size());
     if (UserChr.keyset().size() > 0)
      HD_ChangeReqMgmt_class.sendEmail(UserChr,'Below Change Request(s) needs to be Closed since Scheduled End time has passed','Change Request - Unclosed Change Management Requests');
     
     

  }//method
   


   
  public static void sendEmail(MAP<String,Set<BMCServiceDesk__Change_Request__c>> UserChr,String emailmsg, String emailSubject){
  
    String tblhd= '<HTML>';
    tblhd += '<br>'+emailmsg ;
    tblhd += '<br><br>';
    tblhd += '<table width="100%" cellspacing="0" cellpadding="2" border="1">';

    tblhd += '<thead>';
    tblhd += '<tr>';
    tblhd += '<th>Change Request </th>';    
    tblhd += '<th>Summuary </th>';  
    tblhd += '<th>Scheduled Start - End Timings (UTC) </th>';   
    tblhd += '<th> Owner | Sponsor | Coordinator </th>';        
    tblhd += '</tr>';   
    tblhd += '</thead> <tbody>';
    String body = null;
    String htmlend = '</tbody></table></br></br></HTML>';
    Messaging.SingleEmailMessage[] emailMessageList = new List<Messaging.SingleEmailMessage> ();
    LIST<String> toemails ;
    System.debug('CRM6 -');
    HD_CMR_SETTINGS__c SETTING_TESTMODE = HD_CMR_SETTINGS__c.getInstance('Test_Mode');
    HD_CMR_SETTINGS__c SETTING_TESTEMAILS = HD_CMR_SETTINGS__c.getInstance('Test_Emails');
    LIST<String> testemails = new LIST<String>();
    if (SETTING_TESTEMAILS.Value__c != NULL && SETTING_TESTEMAILS.Value__c.trim() != '' && SETTING_TESTEMAILS != null ){
       testemails = SETTING_TESTEMAILS.Value__c.split(',');
    }
    
    for(String mailId : UserChr.keyset()){
       toemails = new LIST<String>();
       System.debug('CRM4 -'+mailID);
       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
           
           if(SETTING_TESTMODE != NULL && SETTING_TESTMODE.Value__c == 'TRUE' && testemails.size() > 0){
             toemails =  testemails;
           }else{
            toemails.add(mailId);
           }
           
           mail.setToAddresses(toemails);
           mail.setSubject(emailSubject); 
           body = tblhd;
            
         for(BMCServiceDesk__Change_Request__c ch : UserChr.get(mailId)){
            body += '<tr>';
            body += '<td>'+'<a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+ch.Id+'">'+ch.Name+'</a></td>';
            body += '<td>'+ch.Change_Summary__c+'</td>';
            body += '<td> Start Time - '+ch.BMCServiceDesk__Scheduled_Start_Date__c+'<br>End Time &nbsp;- '+ch.BMCServiceDesk__Scheduled_End_Date__c+'</td>';
            body += '<td>'+ch.Owner.Name+'<br>'+ch.HD_Sponsor__r.Name+'<br>'+ch.Change_Coordinator_Primary__r.Name+'</td>';
            body += '</tr>';
         }
         
         body += htmlend;
         if(SETTING_TESTMODE != NULL && SETTING_TESTMODE.Value__c == 'TRUE' && testemails.size() > 0){
         
         body += 'This is test email- Original email intended for '+mailId;
         }
         
         mail.setHtmlBody(body);    
         emailMessageList.add(mail); 
    
      }
      
      if(emailMessageList.size() > 0)
         Messaging.sendEmail(emailMessageList);
   
   }
     
     

     
    public static void  autoClose(){


      DateTime dtm = System.now().addDays(-15);

      LIST<BMCServiceDesk__Change_Request__c> chrs = [select NAME, ID, Change_summary__c,BMCServiceDesk__Scheduled_Start_Date__c,BMCServiceDesk__Scheduled_End_Date__c,
                                                   HD_SPONSOR__r.NAME,HD_SPONSOR__r.isActive,HD_SPONSOR__r.ID,HD_SPONSOR__r.Email, BMCServiceDesk__Change_Category__c,
                                                   Change_Coordinator_Primary__r.isActive,Change_Coordinator_Primary__r.ID,Change_Coordinator_Primary__r.Name,Change_Coordinator_Primary__r.EMail,owner.Name,Owner.EMail,Owner.isActive
                                                   from BMCServiceDesk__Change_Request__c where HD_Change_status__C = 'AUTO FAILED' AND  BMCServiceDesk__Scheduled_End_Date__c < :dtm];
 

       LIST<BMCServiceDesk__Change_Request__c> updatelist =  new LIST<BMCServiceDesk__Change_Request__c>();
       MAP<String,SET<BMCServiceDesk__Change_Request__c>> UserChr = new MAP<String,SET<BMCServiceDesk__Change_Request__c>>() ;
        System.debug('CRM1');
        for(BMCServiceDesk__Change_Request__c chr : chrs){

               


              String[] emailaddress = new String[]{};

              if( chr.HD_SPONSOR__r.IsActive == true ){
                emailaddress.add(chr.HD_SPONSOR__r.Email);
              }
              if( chr.Owner.IsActive == true ){
                emailaddress.add(chr.Owner.EMail);
              }
              
              if(chr.Change_Coordinator_Primary__r.IsActive == true){
                emailaddress.add(chr.Change_Coordinator_Primary__r.EMail);
              }

               System.debug('AUTO CLOSE email -- '+emailaddress);

              //chr.HD_Change_status__C  = 'AUTO CLOSED';
              chr.HD_Change_status__C  = 'CLOSED';
              chr.Auto_Closed__c = TRUE;
              chr.Change_Locked__c = false;
              if( chr.BMCServiceDesk__Actual_Start_Date__c  == NULL)
               {chr.BMCServiceDesk__Actual_Start_Date__c  = chr.BMCServiceDesk__Scheduled_Start_Date__c;}

              if( chr.BMCServiceDesk__Actual_End_Date__c == NULL) 
               {chr.BMCServiceDesk__Actual_End_Date__c = chr.BMCServiceDesk__Scheduled_End_Date__c;}

              if (chr.BMCServiceDesk__Actual_End_Date__c == chr.BMCServiceDesk__Actual_Start_Date__c )
               { chr.BMCServiceDesk__Actual_End_Date__c = chr.BMCServiceDesk__Actual_Start_Date__c.addMinutes(1);}
                
              // Added to avoid Review Date Validation Error  
             
                 chr.BMCServiceDesk__Review_Date__c = chr.BMCServiceDesk__Actual_End_Date__c.addDays(15);
                System.debug('ABCDEF -- '+chr.BMCServiceDesk__Review_Date__c );

               
              for (String email_addr:emailaddress ){
                SET<BMCServiceDesk__Change_Request__c> mapList = new SET<BMCServiceDesk__Change_Request__c>() ;
                if(UserChr.containsKey(email_addr)){
                  mapList = UserChr.get(email_addr);
                }
                System.debug('IN ABCDEF 1234 '+chr.BMCServiceDesk__Review_Date__c);
                mapList.add(chr);
                UserChr.put(email_addr,mapList);
              }
           System.debug('CMR ID '+chr.Name);

        }
        System.debug('CMR ID UPDATE ALL - ');
        update chrs;

        System.debug('CMR ID UPDATE ALL  DONE');
        System.debug('ABCD User Size '+UserChr.size());
         HD_ChangeReqMgmt_class.sendEmail(UserChr,'Below Change Managment Requests are moved to AUTO CLOSED status, as there is no update on the change request post the scheduled end time', 'Change Request - Auto Closing the Change Request');
     



     }

     public static void remindScheduledDate(){

       System.debug('REMIND SCHEDULED');
       System.debug('ABC Time now- '+System.Now());
       DateTime dt1 = System.Now();

        Integer min_s,min_e;
       

       integer min = dt1.minute();
       
       if (min >= 0 && min < 15){
         min_s = 15;
         min_e = 30;
       }

       if (min > 14 && min < 30) {

        min_s = 30;
        min_e = 45;

       } 

       if (min > 29 && min < 45) {
        
        min_s = 45;
        min_e = 60;
       } 

       if (min > 44 && min < 60 ) {
         dt1 = System.now().addMinutes(16);
         min_s = 0;
         min_e = 15;
        
       } 

      DateTime s_dt =  DateTime.newInstance( dt1.Year(), dt1.Month(), dt1.Day(), dt1.hour(), min_s, 0);
      DateTime e_dt =  DateTime.newInstance( dt1.Year(), dt1.Month(), dt1.Day(), dt1.hour(), min_e, 0);
      

     
      LIST<BMCServiceDesk__Change_Request__c> chrs = [select NAME, ID, Change_summary__c,BMCServiceDesk__Scheduled_Start_Date__c,BMCServiceDesk__Scheduled_End_Date__c,HD_Sponsor_Name__c,
                                                   HD_SPONSOR__r.IsActive,HD_SPONSOR__r.NAME,HD_SPONSOR__r.ID,HD_SPONSOR__r.Email, HD_Owner_Name__c,BMCServiceDesk__Change_Category__c,HD_Change_Status__c,
                                                   Change_Coordinator_Primary__r.IsActive,Change_Coordinator_Primary__r.ID,Change_Coordinator_Primary__r.Name,Change_Coordinator_Primary__r.EMail,owner.Name,Owner.EMail,Owner.IsActive 
                                                   from BMCServiceDesk__Change_Request__c where (HD_Change_Status__c IN ('AUTHORIZED','AUTO FAILED','IN PROGRESS','COMPLETED') )];
     


    String body = null;
  
    Messaging.SingleEmailMessage[] emailMessageList = new List<Messaging.SingleEmailMessage> ();
    

    for(BMCServiceDesk__Change_Request__c chr : chrs ){

           System.debug(' Name  - '+chr.Name+' - Start Time : '+chr.BMCServiceDesk__Scheduled_Start_Date__c+' -End Time : '+chr.BMCServiceDesk__Scheduled_End_Date__c);
           

            
           if (chr.BMCServiceDesk__Scheduled_Start_Date__c >= s_dt && chr.BMCServiceDesk__Scheduled_Start_Date__c < e_dt)
           { 

             Messaging.SingleEmailMessage email1 =  getFormattedEmail(chr, 'Change Request '+chr.Name+' Change the Status of the CMR to In Progress',' The Change Request  '+chr.Name+' is going to start at Scheduled Start Date :'+ chr.BMCServiceDesk__Scheduled_Start_Date__c +' UTC (YYYY-MM-DD)');
             emailMessageList.add(email1); 

           } 


           if (chr.BMCServiceDesk__Scheduled_End_Date__c >= s_dt && chr.BMCServiceDesk__Scheduled_End_Date__c < e_dt)
              { 
                Messaging.SingleEmailMessage email2 =  getFormattedEmail(chr, 'Change Request '+chr.Name+' Change the Status of the CMR to Completed',' The Change Request  '+chr.Name+' need to be completed on or before Scheduled End Date:'+ chr.BMCServiceDesk__Scheduled_End_Date__c +' UTC (YYYY-MM-DD)');
                emailMessageList.add(email2);
              }
             

       }
         
    
      
      
      if(emailMessageList.size() > 0)
         Messaging.sendEmail(emailMessageList);



     }

     public static Messaging.SingleEmailMessage getFormattedEmail(BMCServiceDesk__Change_Request__c chr, String subject, String bodytext){

        LIST<String> toemails ;
        System.debug('CRM6 -');
        HD_CMR_SETTINGS__c SETTING_TESTMODE = HD_CMR_SETTINGS__c.getInstance('Test_Mode');
        HD_CMR_SETTINGS__c SETTING_TESTEMAILS = HD_CMR_SETTINGS__c.getInstance('Test_Emails');
        LIST<String> testemails = new LIST<String>();

        if (SETTING_TESTEMAILS.Value__c != NULL && SETTING_TESTEMAILS.Value__c.trim() != '' && SETTING_TESTEMAILS != null ){
           testemails = SETTING_TESTEMAILS.Value__c.split(',');
        }

        String emailSubject = '';
        String htmlbody = '<html> <body><br>';
        toemails = new LIST<String>();

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
             
             if(SETTING_TESTMODE != NULL && SETTING_TESTMODE.Value__c == 'TRUE' && testemails.size() > 0){
               toemails =  testemails;
             }else{
              if( chr.HD_SPONSOR__r.IsActive == true ){
                toemails.add(chr.HD_SPONSOR__r.Email);
              }
              if( chr.Owner.IsActive == true ){
                toemails.add(chr.Owner.EMail);
              }
              
              if(chr.Change_Coordinator_Primary__r.IsActive == true){
                toemails.add(chr.Change_Coordinator_Primary__r.EMail);
              }
              

             }

             mail.setToAddresses(toemails);
             mail.setSubject(subject); 
             String body  = htmlbody;
             body += bodytext;

            body += '<br><br>Change Request details - ';
            body += '<br>Owner: '+chr.HD_Owner_Name__c;
            body += '<br>Change Category: '+chr.BMCServiceDesk__Change_Category__c;
            body += '<br>Change Summary: '+chr.Change_Summary__c;
            body += '<br>Scheduled Start Date: '+chr.BMCServiceDesk__Scheduled_Start_Date__c+' UTC (YYYY-MM-DD)';
            body += '<br>Scheduled End Date: '+chr.BMCServiceDesk__Scheduled_End_Date__c +' UTC (YYYY-MM-DD)'; 
            body += '<br>Sponsor: '+chr.HD_Sponsor_Name__c;
            body += '<br>Change Status: '+chr.HD_Change_Status__c;

          //   body += '<br><br><b> You need to change the status of the Change Request to In Progress within 15 minutes of the Schedule Start time to avoid the Change Request going to AutoFailed State.</b>';
          

            body += '<br><br><b> You need to change the status of the Change Request  within 15 minutes of the Schedule Start/End time. Otherwise Change Request will be marked for CAB review.</b>';
            
            body += '<br><br> Click on link to view more details -  '+URL.getSalesforceBaseUrl().toExternalForm()+'/'+chr.id;

            if(SETTING_TESTMODE != NULL && SETTING_TESTMODE.Value__c == 'TRUE' && testemails.size() > 0){
         
                body += 'This is test email- Original email intended for '+toemails;
            }
            body += '</body></html>';
            mail.setHtmlBody(body); 


            return mail;   

     }




     
}