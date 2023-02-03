/*=====================================================================================================+
Class name          :   SC_SI_IncidentMigration_Batch
Author              :   Himanshu, Vamsee
Created             :   21-Jul-20
Purpose             :   For Migrating Existing Incident related data to new Solution (ESESP-3015)
Test Class          :   SC_SI_AllTestCases_TC

+=====================================================================================================*/
global class SC_SI_IncidentMigration_Batch implements Database.Batchable<sObject>{
 
 	public Integer count = 3;
 	
 	public SC_SI_IncidentMigration_Batch(Integer inParam){
 	
 		count = inParam; 
 	}

   // Start Method
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        string batchQuery;
        // Batch Query Variable
        if(count == 1){
        List<Id> excludeIdList = new List<Id>();
            For(SC_SI_Service_Incident__c eachIncident : [SELECT SC_SI_Old_Incident_Id__c FROM SC_SI_Service_Incident__c WHERE SC_SI_Old_Incident_Id__c != null]){
                excludeIdList.add(eachIncident.SC_SI_Old_Incident_Id__c);
            }
            batchQuery = 'SELECT Id, BMCServiceDesk__Service_Request_Title__c, Name, BMCServiceDesk__FKCategory__r.Name, BMCServiceDesk__FKStatus__r.Name, OwnerID, '+ 
                'SI_OutageStart__c, SI_Type_of_customer_impact__c, SI_GSS_Inc_Manager_BIL__c, How_was_the_Issue_Detected__c, BMCServiceDesk__FKImpact__r.Name, ' +
                'BMCServiceDesk__incidentDescription__c, Customer_Advisory__c, CreatedbyId, Createddate, SI_Etherpad_Link__c, Total_Tier_Count__c, SI_Technical_Notes__c, '+
                'SI_Diagnosis__c, BMCServiceDesk__incidentResolution__c, SI_Incident_Caused_By__c, SI_Business_Unit_Category__c, SI_Incident_Sensitivity__c, BMCServiceDesk__closeDateTime__c, '+
                'SI_SD_Dashboard_Incident__c, SI_StatusChangeDate__c, SI_OutageEnd__c, Incident_Declared_Date_Time__c, BMCServiceDesk__FKUrgency__r.name, Days_Open__c, '+
                'SI_Network__c, SI_Executive_Summary__c, SI_Platform_Review_Date__c, SI_Impacted_CP_Codes_Domains__c, SI_Incident_Review_Present_Date__c, SI_Incident_Review_Status__c '+
                'FROM BMCServiceDesk__Incident__c WHERE RecordtypeID = \'012G0000000yTCC\' and (NOT Id IN :excludeIdList)'; 
        }
        else if(count ==2){
            batchQuery = 'SELECT Id, ParentId, Name, IsPrivate, ContentType, Body, Description FROM Attachment WHERE ParentId IN '+
                '(SELECT Id from BMCServiceDesk__Incident__c WHERE RecordtypeID = \'012G0000000yTCC\')';
        }
    	// For Test Class    
    	batchQuery =  (Test.isRunningTest()) ?  batchQuery + ' LIMIT 50' : batchQuery;
	
        return Database.getQueryLocator(batchQuery);
        
    }
    
    //Execute Method
    global void execute(Database.BatchableContext BC, List<sObject> scope){
       
       
       // Map to store Old SI ID + New SI ID for stamping new ID to Old Incident
       Map<ID,ID> OldSIID_newSIID_Map = new Map<ID,ID>();
       
       if(count == 1){
       	
           List<BMCServiceDesk__Incident__c> OldIncidentList = (BMCServiceDesk__Incident__c[]) scope;
       
			// Step - 1 : Data Migration for Service Incident Object
		   migrateData_Incidents(OldIncidentList, OldSIID_newSIID_Map); 
		  
		   // Step - 2 : Data Migration for Impacted Account Object
		   migrateData_ImpactedAccount(OldIncidentList, OldSIID_newSIID_Map); 
	   
		   // Step - 3 : Data Migration for Impacted Contact Object
		   migrateData_ImpactedContact(OldIncidentList, OldSIID_newSIID_Map); 
	   
		   // Step - 4 : Data Migration for Root Cause Object
		   migrateData_RootCause(OldIncidentList, OldSIID_newSIID_Map); 
	   
		   // Step - 5 : Data Migration for Impacted Product Object
		   migrateData_ImpactedProduct(OldIncidentList, OldSIID_newSIID_Map); 
	   
		   // Step - 6 : Data Migration for External Dependency Object
		   migrateData_ExternalDpendency(OldIncidentList, OldSIID_newSIID_Map); 
       
       	   // Step - 7 : Data Migration for INT Tool
		   migrateData_INTTool(OldIncidentList, OldSIID_newSIID_Map);
       	       	   
       
       }
       
        if(count == 2){
            
            List<Attachment> attachmentList = (Attachment[]) scope;
            Set<Id> parentIdList = new Set<id>();
            
            
            For(Attachment eachAttachment : attachmentList)
                parentIdList.add(eachAttachment.ParentId);
            
            Map<String, Id> OldSIID_newSIID_Map2 = new Map<String, Id>();
            
            for(SC_SI_Service_Incident__c eachIncident : [SELECT Id, SC_SI_Old_Incident_Id__c FROM SC_SI_Service_Incident__c WHERE SC_SI_Old_Incident_Id__c in: parentIdList]){
                OldSIID_newSIID_Map2.put(eachIncident.SC_SI_Old_Incident_Id__c, eachIncident.Id);
            }
        
        	// Step - 9 : Data Migration for Impacted Case Object(Need to Update Case OBject Only)
       		//migrateData_ImpactedCase(OldIncidentList, OldSIID_newSIID_Map); 
       		migrateAttachments(attachmentList, OldSIID_newSIID_Map2);
        }
       
        if(count == 3){
        
        	// Step - 10 : Data Migration for Incident LOE to Task Object
       		//migrateData_IncidentLOE(OldIncidentList, OldSIID_newSIID_Map2); 
        }
    }
    
    //Finish Method
    global void finish(Database.BatchableContext BC){ 
        
        count++;
        if(count == 2){
        	//SC_SI_IncidentMigration_Batch nextrun = new SC_SI_IncidentMigration_Batch(count);
        	//Database.executeBatch(nextrun,10);
        }
        
        
    }
    
    // 1. Data Migration for New Service Incident Object
    public Map<id,Id> migrateData_Incidents(List<BMCServiceDesk__Incident__c> OldIncidentList, Map<ID,ID> OldSIID_newSIID_Map ){
        List<SC_SI_Service_Incident__c> newIncidentList = new List<SC_SI_Service_Incident__c>();
        SC_SI_Service_Incident__c incidentRecord;
        
        //Status Map
        Map<String, String> statusMap = new Map<String, String>();
        statusMap.put('CANCELED','Canceled');
        statusMap.put('CLOSED','Closed');
        statusMap.put('IMPACT MITIGATED','2: Impact Mitigated');
        statusMap.put('IN PROGRESS','1: In Progress');
        statusMap.put('PRE-INCIDENT','Incident Request');
        statusMap.put('RESOLVED','3: Resolved');
        statusMap.put('ROOT CAUSE DETERMINED','1: In Progress');
        statusMap.put('SOLUTION IDENTIFIED','1: In Progress');
        
        Map<String, String> categoryMap = new Map<String, String>();
        categoryMap.put('Attack Response (SOC only)', 'Attack Response (SOC only)');
        categoryMap.put('BOCC Tools', 'BOCC Tools');
        categoryMap.put('CCU/ECCU/Purge', 'CCU/ECCU/Purge');
        categoryMap.put('Corporate', 'Corporate');
        categoryMap.put('Customer Metadata Propagation', 'Customer Metadata Propagation');
        categoryMap.put('Customer Security', 'Customer Security');
        categoryMap.put('Data Latency and Availability', 'Data Latency and Availability');
        categoryMap.put('DDC Data Latency and Availability', 'DDC Data Latency and Availability');
        categoryMap.put('End-User Impact', 'End User Impact');
        categoryMap.put('Enterprise Applications', 'Enterprise Applications');
        categoryMap.put('Financial Impact (COGS and Revenue)', 'Financial Impact (COGS and Revenue)');
        categoryMap.put('Invoicing EBS-AR', 'Invoicing EBS-AR');
        categoryMap.put('Logs/Billing', 'Logs/Billing');
        categoryMap.put('Luna Control Center: Application Availability', 'Luna Control Center: Application Availability');
        categoryMap.put('Mapping', 'Mapping');
        categoryMap.put('Media', 'Media');
        categoryMap.put('Multi-Customer', 'Multi-Customer');
        categoryMap.put('NetStorage', 'NetStorage');
        categoryMap.put('Network Operations', 'Network Operations');
        categoryMap.put('Other', 'Other');
        categoryMap.put('Portal', 'Portal');
        categoryMap.put('Privacy / Personal Data', 'Privacy/Personal Data');
        categoryMap.put('Purge', 'Purge');
        categoryMap.put('Risk', 'Risk');
        categoryMap.put('Security', 'Security');
        categoryMap.put('Security deprecated', 'Security deprecated');
        categoryMap.put('Single Customer', 'Single Customer');
        categoryMap.put('Top Customer', 'Top Customer');
        categoryMap.put('Unknown', 'Unknown');
        categoryMap.put('Web Performance Analytics', 'Web Performance Analytics');
        
        Map<String, String> howWasTheIssueDetectedMap = new Map<String, String>();
        howWasTheIssueDetectedMap.put('Customer reported','Customer');
        howWasTheIssueDetectedMap.put('Akamai monitoring','Akamai');
        howWasTheIssueDetectedMap.put('Third-party reported','Third Party');
        howWasTheIssueDetectedMap.put('Other','Other');
        howWasTheIssueDetectedMap.put('Blank','');
        
        Map<String, String> severityMap = new Map<String, String>();
        severityMap.put('Severity 1','Severity 1');
		severityMap.put('Severity 2','Severity 2');
		severityMap.put('Severity 3','Severity 3');
		severityMap.put('Severity 4','Severity 4');
		severityMap.put('None','');
        
       	
        
        For(BMCServiceDesk__Incident__c eachOldIncident : OldIncidentList){
            incidentRecord = new SC_SI_Service_Incident__c();
            incidentRecord.Title__c 						= eachOldIncident.BMCServiceDesk__Service_Request_Title__c;
           	incidentRecord.Legacy_Incident_Number__c 		= eachOldIncident.Name;
            incidentRecord.Category__c 						= categoryMap.get(eachOldIncident.BMCServiceDesk__FKCategory__r.Name);
            incidentRecord.Status__c 						= statusMap.get(eachOldIncident.BMCServiceDesk__FKStatus__r.Name);
            incidentRecord.Impact_Started__c 				= eachOldIncident.SI_OutageStart__c;
            //incidentRecord.Total_Incident_LOE_Hours__c	
            incidentRecord.Type_of_Customer_Impact__c 		= eachOldIncident.SI_Type_of_customer_impact__c; //It is Multiselect picklist
            
            incidentRecord.OwnerID 							= eachOldIncident.SI_GSS_Inc_Manager_BIL__c != null ? eachOldIncident.SI_GSS_Inc_Manager_BIL__c :
            													eachOldIncident.CreatedbyId;
            incidentRecord.How_was_the_issue_detected__c 	= howWasTheIssueDetectedMap.get(eachOldIncident.How_was_the_Issue_Detected__c); 
            incidentRecord.Severity__c 						= severityMap.get(eachOldIncident.BMCServiceDesk__FKImpact__r.Name);
            incidentRecord.Summary__c						= eachOldIncident.BMCServiceDesk__incidentDescription__c;
            incidentRecord.Customer_Advisory__c 			= eachOldIncident.Customer_Advisory__c; 
            incidentRecord.Incident_Requested_By__c   		= eachOldIncident.CreatedbyId;//Cannot be tagged to Createdby
            incidentRecord.SI_Incident_Requested_Date__c    = eachOldIncident.Createddate;
            incidentRecord.Incident_Created_Date__c    		= eachOldIncident.Createddate;
            incidentRecord.Etherpad_Link__c 				= eachOldIncident.SI_Etherpad_Link__c;
            //incidentRecord.Tier_Distribution__c 			= eachOldIncident.Total_Tier_Count__c;
            incidentRecord.Technical_Notes__c 				= eachOldIncident.SI_Technical_Notes__c; 
            incidentRecord.Diagnosis__c						= eachOldIncident.SI_Diagnosis__c;
            incidentRecord.Resolution__c					= eachOldIncident.BMCServiceDesk__incidentResolution__c;
            incidentRecord.Incident_Caused_By__c 			= eachOldIncident.SI_Incident_Caused_By__c;  
            incidentRecord.Business_Unit_Category__c 		= eachOldIncident.SI_Business_Unit_Category__c;
            incidentRecord.Sensitive_Incident__c 			= eachOldIncident.SI_Incident_Sensitivity__c ;
            incidentRecord.SD_Dashboard_Incident__c 		= eachOldIncident.SI_SD_Dashboard_Incident__c ;
            incidentRecord.SC_SI_Old_Incident_Id__c         = eachOldIncident.Id;
            incidentRecord.TIM_IC__c 						= eachOldIncident.OwnerID;
            incidentRecord.Incident_Closed_Canceled_Rejected_Date__c = eachOldIncident.BMCServiceDesk__closeDateTime__c; 
            incidentRecord.Validation_Override__c			= True;
            incidentRecord.Is_Migrated__c 					= True; 
            
            
            //Old Fields Mapping
            incidentRecord.SI_Status_Change_Date__c			= eachOldIncident.SI_StatusChangeDate__c;
            incidentRecord.SI_Incident_Closed__c			= eachOldIncident.SI_OutageEnd__c ;
            incidentRecord.SI_Incident_Declared_Date_Time__c= eachOldIncident.Incident_Declared_Date_Time__c;
            incidentRecord.SI_Urgency_Aggregate_Severity__c	= eachOldIncident.BMCServiceDesk__FKUrgency__r.Name;
            //incidentRecord.SI_Days_Open__c					= eachOldIncident.Days_Open__c ;
            incidentRecord.SI_Network__c 					= eachOldIncident.SI_Network__c;
            incidentRecord.SI_Executive_Summary__c			= eachOldIncident.SI_Executive_Summary__c;
            incidentRecord.SI_Platform_Review_Date__c 		= eachOldIncident.SI_Platform_Review_Date__c;
            incidentRecord.SI_Impacted_CP_Codes_Domains__c  = eachOldIncident.SI_Impacted_CP_Codes_Domains__c ;
            incidentRecord.SI_Incident_Review_Present_Date__c= eachOldIncident.SI_Incident_Review_Present_Date__c;
            incidentRecord.SI_Incident_Review_Status__c 	= eachOldIncident.SI_Incident_Review_Status__c;
            
            newIncidentList.add(incidentRecord);
                
        }
        
        Insert newIncidentList;
        
        for(SC_SI_Service_Incident__c eachIncidentRecord : newIncidentList){
            OldSIID_newSIID_Map.Put(eachIncidentRecord.SC_SI_Old_Incident_Id__c, eachIncidentRecord.Id);
        }
        return null;
     
    }
    
    
    // 2. Data Migration for Impacted Account Object
    public void migrateData_ImpactedAccount(List<BMCServiceDesk__Incident__c> OldIncidentList, Map<ID,ID> OldSIID_newSIID_Map ){
        
        system.debug('--OldSIID_newSIID_Map--'+OldSIID_newSIID_Map);
    
    	//Insert List
    	List<SC_SI_Impacted_Account__c> insertList = new List<SC_SI_Impacted_Account__c>();
    	SC_SI_Impacted_Account__c eachNewRec;
    	
    	for(SI_ServiceIncidentImpactedCustomers__c eachOldccrec : [SELECT SI_AccountName__c,SI_Service_Incident__c, Keywords__c FROM
    																	SI_ServiceIncidentImpactedCustomers__c  WHERE 
    																	SI_Service_Incident__c IN :OldIncidentList]){
    		
    		eachNewRec = new SC_SI_Impacted_Account__c(	Account_Name__c = eachOldccrec.SI_AccountName__c, 
                                                       	Is_Migrated__c = True,
                                                        Validation_Override__c = True,
                                                        Keywords__c = eachOldccrec.Keywords__c,
    													Service_Incident__c = OldSIID_newSIID_Map.get(eachOldccrec.SI_Service_Incident__c));	
    		insertList.add(eachNewRec);														
    	}
    	
    	Insert insertList;
    }
    
    // 3. Data Migration for Impacted Contact Object
    public void migrateData_ImpactedContact(List<BMCServiceDesk__Incident__c> OldIncidentList, Map<ID,ID> OldSIID_newSIID_Map){
    
    	//Insert List
    	List<SC_SI_Akamai_Contact__c> insertList = new List<SC_SI_Akamai_Contact__c>();
    	SC_SI_Akamai_Contact__c eachNewRec;
        Map<String, String> userRoleMap = new Map<String, String>();
        userRoleMap.put('Business Executive',	'Business Executive');
        userRoleMap.put('Incident Executive',	'Incident Executive');
        userRoleMap.put('NOCC Contact',	'NOCC Contact');
        userRoleMap.put('Subject Matter Expert',	'Subject Matter Expert');
        userRoleMap.put('Platform Presenter or Report Writer',	'Product/Platform Presenter');
        userRoleMap.put('CCare or GSS Presenter or Report Writer',	'GSS Presenter');
        userRoleMap.put('GSS Incident Manager',	'GSS Incident Manager');
        
    	
    	for(SI_ServiceIncidentContacts__c eachOldccrec : [SELECT SI_Remedyforce_Incident__c,SI_User__c,SI_Role__c, Keywords__c FROM
    																	SI_ServiceIncidentContacts__c WHERE 
    																	SI_Remedyforce_Incident__c IN :OldIncidentList]){
    		
    		eachNewRec = new SC_SI_Akamai_Contact__c(Service_Incident__c = OldSIID_newSIID_Map.get(eachOldccrec.SI_Remedyforce_Incident__c), 
    													User__c = eachOldccrec.SI_User__c, 
                                                     	Is_Migrated__c = True,
                                                     	Keywords__c = eachOldccrec.Keywords__c,
    													Role__c = userRoleMap.get(eachOldccrec.SI_Role__c));	
    		insertList.add(eachNewRec);														
    	}
    	
    	Insert insertList;
    }
    
    
    // 4. Data Migration for Root Cause Object
    public void migrateData_RootCause(List<BMCServiceDesk__Incident__c> OldIncidentList, Map<ID,ID> OldSIID_newSIID_Map){
    
    	//Insert List
    	List<SC_SI_Root_Cause__c> insertList = new List<SC_SI_Root_Cause__c>();
    	SC_SI_Root_Cause__c eachNewRec;
    	
    	for(SI_RootCause__c eachOldccrec : [SELECT SI_ServiceIncident__c,SI_RootCause__c,SI_RootCauseReason__c FROM
    																	SI_RootCause__c WHERE 
    																	SI_ServiceIncident__c IN :OldIncidentList]){
    		
    		eachNewRec = new SC_SI_Root_Cause__c(Service_Incident__c = OldSIID_newSIID_Map.get(eachOldccrec.SI_ServiceIncident__c), 
    													Root_Cause__c = eachOldccrec.SI_RootCause__c,Is_Migrated__c = True,
    													Root_Cause_Reason__c = eachOldccrec.SI_RootCauseReason__c);	
    		insertList.add(eachNewRec);														
    	}
    	
    	Insert insertList;
    }
    
    // 5. Data Migration for Impacted Product Object
    public void migrateData_ImpactedProduct(List<BMCServiceDesk__Incident__c> OldIncidentList, Map<ID,ID> OldSIID_newSIID_Map){
    
    	//Insert List
    	List<SC_SI_Impacted_Product__c> insertList = new List<SC_SI_Impacted_Product__c>();
    	SC_SI_Impacted_Product__c eachNewRec;
    	
    	for(SI_ServiceIncidentImpactedProducts__c eachOldccrec : [SELECT SI_ServiceIncident__c,SI_ParentProductName__c,
    																SI_ParentModuleName__c,SI_SubModule__c, Keywords__c FROM
    																SI_ServiceIncidentImpactedProducts__c WHERE 
    																SI_ServiceIncident__c IN :OldIncidentList]){
    		
    		eachNewRec = new SC_SI_Impacted_Product__c(Service_Incident__c = OldSIID_newSIID_Map.get(eachOldccrec.SI_ServiceIncident__c), 
    													ParentProductName__c 	= eachOldccrec.SI_ParentProductName__c,
    													ParentModuleName__c 	= eachOldccrec.SI_ParentModuleName__c,
    													SubModuleName__c 		= eachOldccrec.SI_SubModule__c,
                                                       	Keywords__c 			= eachOldccrec.Keywords__c,
                                                        Is_Migrated__c 			= True);	
    		insertList.add(eachNewRec);														
    	}
    	
    	Insert insertList;
    }
    
    // 6. Data Migration for External Dependency Object
    public void migrateData_ExternalDpendency( List<BMCServiceDesk__Incident__c> OldIncidentList, Map<ID,ID> OldSIID_newSIID_Map){
    
    	//Insert List
    	List<SC_SI_External_Dependency__c> insertList = new List<SC_SI_External_Dependency__c>();
    	SC_SI_External_Dependency__c eachNewRec;
        
        Map<String, String> typeMap = new Map<String, String>();
        typeMap.put('NOCC Issue',	'NOCC');
        typeMap.put('JIRA',	'Jira');
        typeMap.put('Bugzilla CR',	'Bugzilla CR');
        typeMap.put('Aloha Community',	'Aloha Community');
        typeMap.put('release.akamai.com',	'release.akamai.com');
        typeMap.put('Community Post',	'Community Post');
        typeMap.put('Severe vulnerability',	'Severe vulnerability');
       
    	
    	for(SI_AssociatedWorkItems__c eachOldccrec : [SELECT SI_RemedyForce_Incident__c,SI_Type__c,SI_Work_Item_Id__c FROM
    																SI_AssociatedWorkItems__c WHERE 
    																SI_RemedyForce_Incident__c IN :OldIncidentList]){
    		
    		eachNewRec = new SC_SI_External_Dependency__c(Service_Incident__c = OldSIID_newSIID_Map.get(eachOldccrec.SI_RemedyForce_Incident__c), 
    													Type__c		 		= typeMap.get(eachOldccrec.SI_Type__c),
    													Ticket_Number__c 	= eachOldccrec.SI_Work_Item_Id__c,
                                                        Validation_Override__c = True,
                                                        Is_Migrated__c 		= True);	
    		insertList.add(eachNewRec);														
    	}
    	
    	Insert insertList;
    }
    
    // 7. Data Migration for INT Tool - Mailer Object
    public void migrateData_INTTool( List<BMCServiceDesk__Incident__c> OldIncidentList, Map<ID,ID> OldSIID_newSIID_Map){
    
    	//Update List
    	List<EB_AkaMailer__c> UpdateList = new List<EB_AkaMailer__c>();
    	EB_AkaMailer__c eachNewRec;
    	
    	for(EB_AkaMailer__c eachOldccrec : [SELECT ID,CMC_SINumber__c ,CMC_IRAPT_SI_Number__c FROM
    																EB_AkaMailer__c WHERE 
    																CMC_SINumber__c IN :OldIncidentList]){
    		
    		eachOldccrec.CMC_IRAPT_SI_Number__c = OldSIID_newSIID_Map.get(eachOldccrec.CMC_SINumber__c);
    		UpdateList.add(eachOldccrec);														
    	}
    	
    	Update UpdateList;
    }
    
    
    
    public void migrateAttachments(List<Attachment> attachmentList, Map<String,ID> OldSIID_newSIID_Map2){
        List<Attachment> attachmentListInsert = new List<Attachment>();
        Attachment newAttachment;
        For(Attachment eachAttachment : attachmentList){
            newAttachment = new Attachment();
            newAttachment.parentid = OldSIID_newSIID_Map2.get(eachAttachment.ParentId);
			newAttachment.Name = eachAttachment.name;
            newAttachment.IsPrivate = eachAttachment.IsPrivate;
            newAttachment.ContentType = eachAttachment.ContentType;
            newAttachment.Body = eachAttachment.Body;
            newAttachment.Description = eachAttachment.Description;
            attachmentListInsert.add(newAttachment);
        }
        
        Insert attachmentListInsert;

        }
    
}