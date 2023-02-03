/*
 * CR: FFPSA-490
 * Developer: Suhas
 * Description: This Class is used to send email alerts when the Project BED is within 5 Days
 * Date: 7th Jun 2018
 *  
 * CR: FFPSA-1002
 * Developer: Sandeep Naga
 * Change: Have further condition to send email alert: i) Only for integration projects, ii) Projects with any project product BIC not filled and iii) Projects which dont have an "non completed BED task/activity created"
 * Date: 15th April 2019 
*/
public class PSA_BEDCheckfor5Days implements Database.Batchable<sObject>{
      Date next5Days;
      String query;
      public List<EmailTemplate> template = new List<EmailTemplate>();
      String fromAddress;
      String orgWideEmailId;

      List<String> integrationProjectTypesList = new List<String>();
      List<String> bedTaskTypesList = new List<String>();

      
      public List<Id> pcliProjectIdsList = new List<Id>();
      

      

      

      public PSA_BEDCheckfor5Days()
      {
        
        next5Days = Date.today().addDays(5);

        //Get all the integration product types from custom metadata
        integrationProjectTypesList = [SELECT Value_Long__c FROM PSA_Common_Setting__mdt WHERE Name__c = 'IntegrationProjectType'].Value_Long__c.split(',');

        //Get all BED task types
        bedTaskTypesList = [SELECT Value_Long__c FROM PSA_Common_Setting__mdt WHERE Name__c = 'BEDTaskType'].Value_Long__c.split(',');

        //Email template and recipient data
        template = [SELECT id FROM EmailTemplate WHERE developerName = 'bedWithIn30Days_ProjectManager' limit 1];
        //fromAddress = PSA_Settings__c.getInstance('FromEmailAdress').Value__c;
        fromAddress = [Select Value_Long__c from PSA_Common_Setting__mdt where Name__c = 'FromEmailAdress'].Value_Long__c ;
        orgWideEmailId = [select Id from OrgWideEmailAddress where Address = :fromAddress limit 1].Id;

        //Old query only on project
        //querry = 'select pse__Project_Manager__c, pse__Project_Manager__r.Id , Owner_Manager_Email_address__c , pse__Project_Manager__r.email , AKAM_Project_ID__c, Billing_Effective_Date__c, Id from pse__Proj__c where pse__Stage__c != \'Closed\' and Basic_Implementation_Complete__c = null and Billing_Effective_Date__c >= TODAY AND Billing_Effective_Date__c <=  : next5Days ';
        
        //Obtain project Ids with specific product names and not part of the taskProjectIdsList and Project BED is after 5 but before 30 days from today and project BIC is not filled
        query =  'SELECT Project__r.Id,Project__r.pse__Project_Manager__r.email,Project__r.pse__Project_Manager__c,Project__r.Owner_Manager_Email_address__c,Product_Text_Area__c';
        query +=' FROM Project_Contract_Line_Item__c';
        query +=' WHERE';
        query +=' Project__r.pse__Stage__c != \'Closed\' AND';
        //query +=' Project__r.Basic_Implementation_Complete__c = null AND';
        query +=' Project__r.Billing_Effective_Date__c >= TODAY AND ';
        query +=' Project__r.Billing_Effective_Date__c <=  : next5Days';
        query +=' AND Product_Text_Area__c in :integrationProjectTypesList';

        
        
      }

    public Database.QueryLocator start(Database.BatchableContext BC){
      System.debug('@@query: '+query);
      return Database.getQueryLocator(query);
   }


   public void execute(Database.BatchableContext BC, List<sObject> scope){
     
      
       Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
      //Messaging.Singleemailmessage objEmail;


       List<Project_Contract_Line_Item__c> pclis = new List<Project_Contract_Line_Item__c>();
 
       Set<Id> projectIdsSet = new Set<Id>();
       Map<Id,Project_Contract_Line_Item__c> projectDetailsMap = new Map<Id,Project_Contract_Line_Item__c>();
       Map<Id,Boolean> projectProductBICMap = new Map<Id,Boolean>();

       //projs = scope;
       pclis = scope;

       for(Project_Contract_Line_Item__c pcli : pclis)
       {
          System.debug('@@Product_Text_Area__c: '+pcli.Product_Text_Area__c);
          projectDetailsMap.put(pcli.Project__r.Id,pcli);
       }

        if(projectDetailsMap!=null && !projectDetailsMap.isEmpty())
        {
          //Obtain the Map of Project IDs with Project Product BIC (False if any one project product BIC is null, true otherwise)
          for(pse__Project_Methodology__c projectProduct : [ SELECT pse__Project__r.Id,Basic_Implementation_Complete__c FROM pse__Project_Methodology__c WHERE pse__Project__r.Id IN :projectDetailsMap.keySet()])
          {
            Boolean bicFlag = (projectProduct.Basic_Implementation_Complete__c != null);
            if(projectProductBICMap.get(projectProduct.pse__Project__r.Id) == null || !bicFlag)
            {
              projectProductBICMap.put(projectProduct.pse__Project__r.Id,bicFlag);              
            }

          }       

          for(Id projectId : projectDetailsMap.keySet())
          {
            if(projectProductBICMap.get(projectId) == null || !projectProductBICMap.get(projectId))
            {
              projectIdsSet.add(projectId);
            }
          }               
  
          

          if(!projectIdsSet.isEmpty())
          {
            //Obtain the project IDs which have tasks created of type and status is not completed.
            for(Task task : [ SELECT WhatId FROM Task WHERE RecordType.DeveloperName = 'PSA_Activity' AND Type__c in :bedTaskTypesList AND Status != 'Completed' AND WhatId in :projectIdsSet ])
            {
              //For final set of project Ids, remove all the projects which have tasks of BED type and not completed.
              projectIdsSet.remove(task.WhatId);
            }
            
            if(!projectIdsSet.isEmpty())
            {
              //Fetch all the details of projects with the final projectIds
              for(Id projectId : projectIdsSet)
              {
                Project_Contract_Line_Item__c pcli = projectDetailsMap.get(projectId);
                //Send emails to the final set of Projects
                PSA_ProjectActions.sendMail_BED(pcli.Project__r.pse__Project_Manager__r.email , pcli.Project__r.pse__Project_Manager__c , template.get(0).Id ,pcli.Project__r.Id , orgWideEmailId, mailsToBeSent, pcli.Project__r.Owner_Manager_Email_address__c, null , null );
              }

            }
            
          }
        
        }
     
       	if(mailsToBeSent!=null && mailsToBeSent.size() > 0)
       	{
        	Messaging.SendEmailResult [] mailSendResult = Messaging.sendEmail(mailsToBeSent,false);
        	for(Messaging.SendEmailResult result : mailSendResult)
        	{
            	System.debug('Email result ' + result.IsSuccess());
            	System.debug('Individ rsl :' + result);
        	}
      	}
      
    }

    public void finish(Database.BatchableContext BC){
   	}
    
}