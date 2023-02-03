trigger PLM_Launch_Item_Trigger on Launch_Item__c (after insert, before update, after update) 
{
    PLM_LaunchItemApprovalGeneric plmClass=new PLM_LaunchItemApprovalGeneric();
    public Boolean islaunchItemApprovalEnabled=plmClass.dataClass.getIsLaunchItemApprovalEnabled();
    //public static Boolean islaunchItemApprovalEnabled=Features_Toggle__c.getInstance('LaunchItemApproval').Toggle__c;
    //public String featureDisabledMessage{get;set;}
    List<Task> newTskList = new List<Task>();
    Map<String, Id> userMap = new Map<String, Id>();
    
    if(PLM_LaunchItemClass.firstRun){
        for(User usr : [Select Alias, Id from User where alias = 'SMCELWEE' or alias = 'MMOHIDEE' or alias = 'VCHEUNG' or alias = 'CNADER' or alias = 'BPRABHAL' or alias = 'RDOOLEY' or alias = 'FFAUSTIN'])
            userMap.put(usr.alias, usr.Id);
    }
    
    // Add new activities when new tasks are added
    if(Trigger.isInsert && Trigger.isAfter)
    {
        //PACE_LaunchItem licls = new PACE_LaunchItem();  
        PACE_LaunchItem.updateProgramField(Trigger.new);
    
    /*  tesk are removed #1/3
        for(Launch_Item__c item : Trigger.new)
        {
            
            
            Map<String, Date> milestoneMap = PLM_LaunchItemClass.ResolveDateForTask(item.Id);
            
            //Product Dependant Tasks 
            newTskList.add(PLM_LaunchItemClass.CreateTask(item.Product_Manager__c, 'Upload Scope Document', item.Id,milestoneMap.get('Upload Scope Document')));
            newTskList.add(PLM_LaunchItemClass.CreateTask(item.Product_Manager__c, 'Upload Product Design Documents', item.Id,milestoneMap.get('Upload Product Design Documents')));
            newTskList.add(PLM_LaunchItemClass.CreateTask(item.Product_Manager__c, 'Upload Package Design Documents', item.Id,milestoneMap.get('Upload Package Design Documents')));
            newTskList.add(PLM_LaunchItemClass.CreateTask(item.Product_Manager__c, 'Upload Go-To-Market Design Documents', item.Id,milestoneMap.get('Upload Go-To-Market Design Documents')));
            //newTskList.add(PLM_LaunchItemClass.CreateTask(item.Product_Manager__c, 'Setup Package Design Review Date', item.Id,milestoneMap.get('Setup Package Design Review Date')));
            //newTskList.add(PLM_LaunchItemClass.CreateTask(userMap.get('VCHEUNG'), 'Assign Readiness Date', item.Id,milestoneMap.get('Assign Readiness Date')));
            newTskList.add(PLM_LaunchItemClass.CreateTask(item.Product_Manager__c, 'Post Prototype Order Forms', item.Id,milestoneMap.get('Post Prototype Order Forms')));
            newTskList.add(PLM_LaunchItemClass.CreateTask(userMap.get('MMOHIDEE'), 'Setup System Integration Review Date', item.Id,milestoneMap.get('Setup System Integration Review Date')));
            newTskList.add(PLM_LaunchItemClass.CreateTask(userMap.get('SMCELWEE'), 'Update Product Catalog Structure', item.Id,milestoneMap.get('Update Product Catalog Structure')));
            newTskList.add(PLM_LaunchItemClass.CreateTask(item.Product_Manager__c, 'Post Test Order Forms and Invoice Item Designs', item.Id,milestoneMap.get('Post Test Order Forms and Invoice Item Designs')));
            newTskList.add(PLM_LaunchItemClass.CreateTask(userMap.get('SMCELWEE'), 'Complete Portal Provisioning', item.Id,milestoneMap.get('Complete Portal Provisioning')));
            //newTskList.add(PLM_LaunchItemClass.CreateTask(userMap.get('SMCELWEE'), 'Assign Backend Integration Completion Date', item.Id,milestoneMap.get('Assign Backend Integration Completion Date')));
            newTskList.add(PLM_LaunchItemClass.CreateTask(item.Product_Manager__c, 'Upload Launch Checklist', item.Id,milestoneMap.get('Upload Launch Checklist')));
            newTskList.add(PLM_LaunchItemClass.CreateTask(item.Product_Manager__c, 'Upload PLU Presentation', item.Id,milestoneMap.get('Upload PLU Presentation')));     
            if(islaunchItemApprovalEnabled)
            {
            newTskList.add(PLM_LaunchItemClass.CreateTask(item.Product_Manager__c, 'Seek Division GM approval', item.Id,milestoneMap.get('Seek Division GM approval')));
            }
        }
        insert newTskList;
        
        */
        
        /* Commenting Folllowing Beta,La,Ga Updates #1/2 
        PACECustomSettings__c defPahseRecordType = PACECustomSettings__c.getValues('DefinitionPhaseRecordTypeName');
        PACECustomSettings__c devPahseRecordType = PACECustomSettings__c.getValues('DevelopmentPhaseRecordTypeName');
        PACECustomSettings__c launchPahseRecordType = PACECustomSettings__c.getValues('LaunchPhaseRecordTypeName');
        List<PACE_Phase__c> phlist =new List<PACE_Phase__c>();
        Map<Id,String> programtoitemmap =new Map<Id,String>();
        List<Id> betaitems = new List<Id>();
        List<Id> laitems = new List<Id>();
        List<Id> gaitems= new List<Id>(); 
        List<Id> newId =new List<Id>();
        for(Launch_Item__c item:Trigger.new){
            newId.add(item.Id);
            if(item.Product_Phase__c=='Beta')
            {
                    System.Debug('Beta detected');
                    betaitems.add(item.Program__c);
             } 
             else if(item.Product_Phase__c=='LA')
             {
                 System.Debug('LA Detected');
                 laitems.add(item.Program__c);
              }
              else if(item.Product_Phase__c=='GA')
              {
                  System.Debug('GA detected');
                  gaitems.add(item.Program__c);
               }
        }
        for(Launch_Item__c item:[SELECT Id,Program__c,PLU__r.PLU_Date__c,PLU__r.Name FROM Launch_Item__c WHERE Id IN :newId]){
            System.Debug(item.Program__c+'Program');
            System.Debug(item.PLU__r.PLU_Date__c+'Date');
            programtoitemmap.put(item.Program__c,item.PLU__r.Name);
        
        }
        
        for(PACE_Phase__c betaph:[SELECT Id,Planned_Start_Date__c,PACE_Program__c,RecordType.Name FROM PACE_Phase__c WHERE PACE_Program__c IN :betaitems AND RecordType.Name=:devPahseRecordType.Value__c]){
                System.Debug('Beta Updated');
                betaph.Planned_Beta_Start_Date__c=programtoitemmap.get(betaph.PACE_Program__c);
                System.Debug(programtoitemmap.get(betaph.PACE_Program__c));
                System.Debug(betaph.Planned_Start_Date__c);
                phlist.add(betaph);
        }
        for(PACE_Phase__c laph:[SELECT Id,Planned_Start_Date__c,PACE_Program__c,RecordType.Name FROM PACE_Phase__c WHERE PACE_Program__c IN :laitems AND RecordType.Name=:launchPahseRecordType.Value__c]){
                System.Debug('LA Updated');
                laph.Planned_LA_Start_Date__c=programtoitemmap.get(laph.PACE_Program__c);    
                phlist.add(laph);
        }
        for(PACE_Phase__c gaph:[SELECT Id,Planned_Start_Date__c,PACE_Program__c,RecordType.Name FROM PACE_Phase__c WHERE PACE_Program__c IN :gaitems AND RecordType.Name=:launchPahseRecordType.Value__c]){
                 System.Debug('GA Updated');
                 gaph.Planned_GA_Start_Date__c=programtoitemmap.get(gaph.PACE_Program__c);   
                 phlist.add(gaph);
        }
        
        if(phlist.size()>0)
        {
            System.Debug('Update loop Entered');
            System.Debug(phlist.size());
            update phlist;
        }
         
         
         #1/2 */
           
           
           /* removing email notification as a part of task removal #2/3 
    // Add the Product Manager and other Standard Users to the Task Notification User List on Creation of new Launch Item       
        Set<PLM_Task_Notification_User__c> distributionSet = new Set<PLM_Task_Notification_User__c>();
        List<PLM_Task_Notification_User__c> distributionList = new List<PLM_Task_Notification_User__c>();
        
        for(Launch_Item__c item : Trigger.new) 
        {
            distributionSet.add(PLM_LaunchItemClass.CreateTaskList(item.Product_Manager__c,item.Id));
            distributionSet.addAll(PLM_LaunchItemClass.CreateDistributionList(item.id));
        }
        
        distributionList.addAll(distributionSet);
        
        if (distributionList.size()>0)
            insert distributionList;
          
             
             */
   
    }
    
    /**
        On update of launch item milestones, task activity dates have to be updated. Milestones could be updated manually by users or
        they could be updated when a PLU date is changed.
    */    
    
    if(Trigger.isUpdate && PLM_LaunchItemClass.firstRun && Trigger.isAfter)
    {

        List<Task> taskList = new List<Task>();
        List<Launch_Item__c> launchList = new List<Launch_Item__c>(); 
        List<Id> changedPlu = new List<Id>();
                
        List<Id> modifiedLaunchItems = new List<Id>();
        Map<Id, Id> launchItemOldPluMap = new Map<Id, Id>(); 
        Map<Id, Id> launchItemNewPluMap = new Map<Id, Id>();
        
        Map<Id, Date> launchSiRDateMap = new Map<Id, Date>();
        Map<Id, Date> launchBiRDateMap = new Map<Id, Date>();
        Map<Id, Date> launchProductLaunchUpdateMap = new Map<Id, Date>();
        Map<Id, Date> launchPkgDesignSubmissionDateMap = new Map<Id, Date>();
        Map<Id, Date> launchMomentumActivationDateMap = new Map<Id, Date>();
        Map<Id, Date> launch_LaunchReadinessMap = new Map<Id, Date>();
    
        Map<Id, Date> pluSiRDateMap = new Map<Id, Date>();
        Map<Id, Date> pluBiRDateMap = new Map<Id, Date>();
        Map<Id, Date> pluProductLaunchUpdateMap = new Map<Id, Date>();
        Map<Id, Date> pluPkgDesignSubmissionDateMap = new Map<Id, Date>();
        Map<Id, Date> pluMomentumActivationDateMap = new Map<Id, Date>();
        Map<Id, Date> plu_LaunchReadinessMap = new Map<Id, Date>();     
        
        // Get launch items for which date has changed  
        for(Launch_Item__c item : Trigger.new)
        {
            if((Trigger.oldMap.get(item.Id).System_Integration_Review_Date__c  != item.System_Integration_Review_Date__c)||
                (Trigger.oldMap.get(item.Id).Backend_Integration_Test_Dates__c != item.Backend_Integration_Test_Dates__c)||
                (Trigger.oldMap.get(item.Id).Product_Launch_Update__c != item.Product_Launch_Update__c)||
                //(Trigger.oldMap.get(item.Id).Momentum_Activation_Date__c != item.Momentum_Activation_Date__c)||
                //(Trigger.oldMap.get(item.Id).Launch_Readiness_Date__c != item.Launch_Readiness_Date__c)||
                (Trigger.oldMap.get(item.Id).Package_Design_Submission_Date__c != item.Package_Design_Submission_Date__c)){
                    modifiedLaunchItems.add(item.Id);
                }
                
                
                if(Trigger.oldMap.get(item.Id).PLU__c  != item.PLU__c){
                    modifiedLaunchItems.add(item.Id);
                    launchItemOldPluMap.put(item.Id, Trigger.oldMap.get(item.Id).PLU__c);
                    launchItemNewPluMap.put(item.Id, item.PLU__c);
                }
                
        }
    
        changedPlu.addAll(launchItemOldPluMap.values());
        changedPlu.addAll(launchItemNewPluMap.values());
        
        
        for(PLU__c plu: [
            Select 
            System_Integration_Review_Date__c,
            Product_Launch_Update__c,
            Package_Design_Submission_Date__c,
            Momentum_Activation__c,
            Launch_Readiness__c,
            Backend_Integration_Test__c
            from PLU__c where Id in:changedPlu]
        ){
        
            pluSiRDateMap.put(plu.Id, plu.System_Integration_Review_Date__c);
            pluBiRDateMap.put(plu.Id, plu.Backend_Integration_Test__c);
            pluPkgDesignSubmissionDateMap.put(plu.Id, plu.Package_Design_Submission_Date__c);
            pluProductLaunchUpdateMap.put(plu.Id, plu.Product_Launch_Update__c);
            pluMomentumActivationDateMap.put(plu.Id, plu.Momentum_Activation__c);
            plu_LaunchReadinessMap.put(plu.Id, plu.Launch_Readiness__c);                
            
        }
        

        // Add a list size check here.....
        // Get the latest PLU date for such launch items and cache in maps
        for(Launch_Item__c lic: [Select Id, PLU__c, 
            System_Integration_Review_Date__c, 
            Backend_Integration_Test_Dates__c, 
            Package_Design_Submission_Date__c,
            Product_Launch_Update__c,
            Momentum_Activation_Date__c,
            Launch_Readiness_Date__c 
            from Launch_Item__c where Id in :modifiedLaunchItems]){
                
            if((lic.Backend_Integration_Test_Dates__c == null)||(lic.Backend_Integration_Test_Dates__c == pluBiRDateMap.get(launchItemOldPluMap.get(lic.Id)))){
                lic.Backend_Integration_Test_Dates__c = pluBiRDateMap.get(launchItemNewPluMap.get(lic.Id));
                launchBiRDateMap.put(lic.Id, pluBiRDateMap.get(launchItemNewPluMap.get(lic.Id)));
            }
            else{
                launchBiRDateMap.put(lic.Id, lic.Backend_Integration_Test_Dates__c);
            }

            if((lic.Momentum_Activation_Date__c == null)||(lic.Momentum_Activation_Date__c == pluMomentumActivationDateMap.get(launchItemOldPluMap.get(lic.Id)))){
                lic.Momentum_Activation_Date__c = pluMomentumActivationDateMap.get(launchItemNewPluMap.get(lic.Id));
                launchMomentumActivationDateMap.put(lic.Id, pluMomentumActivationDateMap.get(launchItemNewPluMap.get(lic.Id)));
            }
            else{
                launchMomentumActivationDateMap.put(lic.Id, lic.Momentum_Activation_Date__c);
            }

            if((lic.Launch_Readiness_Date__c == null)||(lic.Launch_Readiness_Date__c == plu_LaunchReadinessMap.get(launchItemOldPluMap.get(lic.Id)))){
                lic.Launch_Readiness_Date__c = plu_LaunchReadinessMap.get(launchItemNewPluMap.get(lic.Id));
                launch_LaunchReadinessMap.put(lic.Id, plu_LaunchReadinessMap.get(launchItemNewPluMap.get(lic.Id)));
            }
            else{
                launch_LaunchReadinessMap.put(lic.Id, lic.Launch_Readiness_Date__c);
            }
    
            if((lic.Package_Design_Submission_Date__c == null)||(lic.Package_Design_Submission_Date__c == pluPkgDesignSubmissionDateMap.get(launchItemOldPluMap.get(lic.Id)))){
                lic.Package_Design_Submission_Date__c = pluPkgDesignSubmissionDateMap.get(launchItemNewPluMap.get(lic.Id));
                launchPkgDesignSubmissionDateMap.put(lic.Id, pluPkgDesignSubmissionDateMap.get(launchItemNewPluMap.get(lic.Id)));
            }
            else{
                launchPkgDesignSubmissionDateMap.put(lic.Id, lic.Package_Design_Submission_Date__c);
            }

            if((lic.Product_Launch_Update__c == null)||(lic.Product_Launch_Update__c == pluProductLaunchUpdateMap.get(launchItemOldPluMap.get(lic.Id)))){
                lic.Product_Launch_Update__c = pluProductLaunchUpdateMap.get(launchItemNewPluMap.get(lic.Id));
                launchProductLaunchUpdateMap.put(lic.Id, pluProductLaunchUpdateMap.get(launchItemNewPluMap.get(lic.Id)));
            }
            else{
                launchProductLaunchUpdateMap.put(lic.Id, lic.Product_Launch_Update__c);
            }
            
            if((lic.System_Integration_Review_Date__c == null)||(lic.System_Integration_Review_Date__c == pluSiRDateMap.get(launchItemOldPluMap.get(lic.Id)))){
                lic.System_Integration_Review_Date__c = pluSiRDateMap.get(launchItemNewPluMap.get(lic.Id));
                launchSiRDateMap.put(lic.Id, pluSiRDateMap.get(launchItemNewPluMap.get(lic.Id)));
            }
            else{
                launchSiRDateMap.put(lic.Id, lic.System_Integration_Review_Date__c);
            }

            launchList.add(lic);
        }
        
        update launchList;
        
        
        /* Removing task updates and email update as a part of Task Removal #3/3
        
        // Update the tasks with new PLU dates
        for(Task task:[Select t.Id, t.ActivityDate,t.WhatId, t.Subject From Task t where t.WhatId in :modifiedLaunchItems and t.IsClosed = false]){
            
            if( task.Subject.equals('Upload Scope Document') || task.Subject.equals('Upload Product Design Documents') ||
            task.Subject.equals('Upload Package Design Documents') || task.Subject.equals('Upload Go-To-Market Design Documents'))
            {
                task.ActivityDate = launchPkgDesignSubmissionDateMap.get(task.WhatId);
            }
            else if((task.Subject.equals('Setup Package Design Review Date')) || task.Subject.equals('Assign Readiness Date') ||
            task.Subject.equals('Post Prototype Order Forms') || task.Subject.equals('Setup System Integration Review Date') ||
            task.Subject.equals('Update Product Catalog Structure') || task.Subject.equals('Post Test Order Forms and Invoice Item Designs') ||
            task.Subject.equals('Complete Portal Provisioning'))
            {
                task.ActivityDate = launchSiRDateMap.get(task.WhatId);
            }
            else if(task.Subject.equals('Assign Backend Integration Completion Date'))
            {
                task.ActivityDate = launchBiRDateMap.get(task.WhatId);                
            }
            else if(task.Subject.equals('Upload Launch Checklist') || task.Subject.equals('Upload PLU Presentation'))
            {
                task.ActivityDate = launchProductLaunchUpdateMap.get(task.WhatId);                
            }  

            taskList.add(task);
            
        }
        
        // Update tasks
        update taskList;
        
       
     //@nakodand -- commenting the following lines for CR 1791616   
   // }    //end of if update

  //  if(Trigger.isUpdate && PLM_LaunchItemClass.firstRun && Trigger.isAfter)
  //  {

        // Send emails
        List<PLM_Task_Notification_User__c> tskNotificationUsersList = new List<PLM_Task_Notification_User__c>();
        for(PLM_Task_Notification_User__c tskUser : [select Id, User__c, Launch_Item__c, Send_Email__c from PLM_Task_Notification_User__c where Launch_Item__c IN :Trigger.new])
        {
            if(Trigger.newMap.get(tskUser.Launch_Item__c).Phase_Status__c != Trigger.oldMap.get(tskUser.Launch_Item__c).Phase_Status__c)
            {
                tskUser.Send_Email__c = true;
                tskNotificationUsersList.add(tskUser);
            }
        }
        if(tskNotificationUsersList.size()>0)
            update tskNotificationUsersList;
            
            
          end #3/3  */
            
            
        PLM_LaunchItemClass.firstRun = false;    
    }
    
   // PLM_LaunchItemClass.firstRun = false;
  /* Start Modified BY Chandra For CR 1419337*/
  
  if(islaunchItemApprovalEnabled)
   {
      System.Debug('LaunchItemApprovalEnabled');
    if(Trigger.isInsert && Trigger.isAfter)
    {
        //PLM_LaunchItemApprovalClass plmClass=new PLM_LaunchItemApprovalClass();
        //PLM_LaunchItemApprovalGeneric plmClass=new PLM_LaunchItemApprovalGeneric();
        plmClass.addDefaultLaunchApprovalTeam(Trigger.New);  // adding default approval team to launch Item
    }
    if(Trigger.isUpdate && Trigger.isAfter)
    {
        //PLM_LaunchItemApprovalClass plmClass=new PLM_LaunchItemApprovalClass();
        //PLM_LaunchItemApprovalGeneric plmClass=new PLM_LaunchItemApprovalGeneric();
        List<Launch_Item__c> launchItemList=new List<Launch_Item__c>();
        List<Launch_Item__c> archivedLaunchItemList=new List<Launch_Item__c>();
        for(Launch_Item__c li: Trigger.New)
        {
            if(li.Division__c !=null && li.Division__c !=Trigger.oldmap.get(li.Id).Division__c)
            {
                launchItemList.add(li);
            }
            if(li.Archive__c && li.Archive__c!=Trigger.oldmap.get(li.Id).Archive__c)
            {
                System.Debug('Archive Detected');
                archivedLaunchItemList.add(li);
            }
        }
        if(launchItemList.size()>0)
        {
            plmClass.updateExistingDivisionalApprovals(launchItemList); //update existing Division launch Approvals if Division changed at Launch Item level
        }
        if(archivedLaunchItemList.size()>0)
        {
            plmClass.removeApprovalSubscriptions(archivedLaunchItemList); //Remove Product Manager's subscription to Launch Approvals when Launch Item is archived.
        }
        
        
        /* Commenting Follwing Beta La Ga Update #2/2
        
        PACECustomSettings__c defPahseRecordType = PACECustomSettings__c.getValues('DefinitionPhaseRecordTypeName');
        PACECustomSettings__c devPahseRecordType = PACECustomSettings__c.getValues('DevelopmentPhaseRecordTypeName');
        PACECustomSettings__c launchPahseRecordType = PACECustomSettings__c.getValues('LaunchPhaseRecordTypeName');
        List<PACE_Phase__c> phlist =new List<PACE_Phase__c>();
        Map<Id,String> programtoitemmap =new Map<Id,String>();
        List<Id> betaitems = new List<Id>();
        List<Id> laitems = new List<Id>();
        List<Id> gaitems= new List<Id>(); 
        List<Id> newId =new List<Id>();
        for(Launch_Item__c item:archivedLaunchItemList){
            newId.add(item.Id);
            if(item.Product_Phase__c=='Beta')
            {
                    System.Debug('Beta detected');
                    betaitems.add(item.Program__c);
             } 
             else if(item.Product_Phase__c=='LA')
             {
                 System.Debug('LA Detected');
                 laitems.add(item.Program__c);
              }
              else if(item.Product_Phase__c=='GA')
              {
                  System.Debug('GA detected');
                  gaitems.add(item.Program__c);
               }
        }
        for(Launch_Item__c item:[SELECT Id,Program__c,PLU__r.PLU_Date__c,PLU__r.Name FROM Launch_Item__c WHERE Id IN :newId]){
            System.Debug(item.Program__c+'Program');
            System.Debug(item.PLU__r.PLU_Date__c+'Date');
            programtoitemmap.put(item.Program__c,item.PLU__r.Name);
        
        }
        
        for(PACE_Phase__c betaph:[SELECT Id,Planned_Start_Date__c,PACE_Program__c,RecordType.Name FROM PACE_Phase__c WHERE PACE_Program__c IN :betaitems AND RecordType.Name=:devPahseRecordType.Value__c]){
                System.Debug('Beta Updated');
                betaph.Actual_Beta_Start_Date__c=programtoitemmap.get(betaph.PACE_Program__c);
                System.Debug(programtoitemmap.get(betaph.PACE_Program__c));
                System.Debug(betaph.Actual_Start_Date__c);
                phlist.add(betaph);
        }
        for(PACE_Phase__c laph:[SELECT Id,Planned_Start_Date__c,PACE_Program__c,RecordType.Name FROM PACE_Phase__c WHERE PACE_Program__c IN :laitems AND RecordType.Name=:launchPahseRecordType.Value__c]){
                System.Debug('LA Updated');
                laph.Actual_LA_Start_Date__c=programtoitemmap.get(laph.PACE_Program__c);    
                phlist.add(laph);
        }
        for(PACE_Phase__c gaph:[SELECT Id,Planned_Start_Date__c,PACE_Program__c,RecordType.Name FROM PACE_Phase__c WHERE PACE_Program__c IN :gaitems AND RecordType.Name=:launchPahseRecordType.Value__c]){
                 System.Debug('GA Updated');
                 gaph.Actual_GA_Start_Date__c=programtoitemmap.get(gaph.PACE_Program__c);   
                 phlist.add(gaph);
        }
        
        if(phlist.size()>0)
        {
            System.Debug('Update loop Entered');
            System.Debug(phlist.size());
            update phlist;
        }
        #2/2 */
    }
    
    
    
    //Added by Hitesh CR 1633675
    if(Trigger.isUpdate)
    {

        List<Launch_Item__c> liList = new List<Launch_Item__c>();
        
            for(Launch_Item__c li : Trigger.new) 
                {
                    if(Trigger.oldMap.get(li.Id).PLU__c  != li.PLU__c && li.PLU__c!=null && li.Archive__c == false )
                            
                        {
                            liList.add(li);
                        }
                }
        
        plmClass.disableLIApprovalonPLUchange(liList,Trigger.isBefore,Trigger.isAfter);
        
     }
    
   }
   
  /* End Modified By Chandra For CR 1419337 */  
  //Added by Hitesh 29/03/2012
 /* if(Trigger.isInsert)
    {
       Launch_Item__c tempLI = new Launch_Item__c();
        for(Launch_Item__c item : Trigger.new)
        { 
            tempLI = [Select Temporary_PLU__c,PLU__r.Name,Date_Moved__c from Launch_Item__c where Id=:item.id ];
            tempLI.Temporary_PLU__c = tempLI.PLU__r.Name;
            
         }
         update tempLI;
    }
   if(Trigger.isUpdate)
   {
        List<Launch_Item__c> tempLIlist  = new List<Launch_Item__c>();
        for(Launch_Item__c li : Trigger.new) 
        {
        if(Trigger.oldMap.get(li.Id).PLU__c  != li.PLU__c)
        {
           
           Launch_Item__c temp1LI = [Select Temporary_PLU__c,MovedTo__c,Moved_From__c,PLU__r.Name,Date_Moved__c from Launch_Item__c where Id=:li.id ];
           if(Trigger.oldMap.get(li.Id).Temporary_PLU__c != null)
           temp1LI.Moved_From__c = Trigger.oldMap.get(li.Id).Temporary_PLU__c;
           else
           temp1LI.Moved_From__c = Trigger.oldMap.get(li.Id).PLU__r.Name;
           temp1LI.Temporary_PLU__c = temp1LI.PLU__r.Name;
           temp1LI.Date_Moved__c = DATE.today();
           tempLIlist.add(temp1LI);
        }
        }
        
        update tempLIlist;
    } */
    
}