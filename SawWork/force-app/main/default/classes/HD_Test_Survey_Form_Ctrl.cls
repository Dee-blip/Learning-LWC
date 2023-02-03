/*
* Developer @ Hemant Kumar
* This is TEst class for HD_Survey_Form_Ctrl.cls
* Used in HD_Survey_Form Ligtning component
* 
*/
@isTest(seeAllData=false)
public class HD_Test_Survey_Form_Ctrl {
    
    
    static TestMethod void testgetSurveyFormDetails(){
        
        //creating survey form test data : 
        HD_Survey_Form__c hsf = new HD_Survey_Form__c();
        hsf.Available_for_Categories__c = 'All';
        hsf.Days_Response_Will_Expire__c = 1;
        hsf.Description__c	= 'this is default form for failsafe';         
        hsf.Form_meta__c='{"question1": {"title": "How well did the Service Desk handle your request ?","type": "slider","min": "0","max": "10","value":"5"	}';
        hsf.IsActive__c=true;
        hsf.Survey_Intro__c='Please take a moment to provide feedback about your recent Service Request to help us improve our service.';
        hsf.Survey_Title__c	='Service Desk Satisfaction Survey';
        hsf.Survey_Type__c='Overall Survey';
        hsf.Team_Tag__c= 'Global';
        insert hsf;
        HD_Survey_Form_Ctrl.ClassObject('000000','hr');
        
        
    }//

    static TestMethod void testgetSurveyFormIncidentCategoriesDetails(){    
        
        //Creating Incident
        User staff = HD_Test_Remedyforce_TestDataFactory.runAsUser('ServiceDesk Staff',true);
        HD_IncidentTestDataFactory obj = new HD_IncidentTestDataFactory();
        BMCServiceDesk__Status__c new_status = [Select Id from BMCServiceDesk__Status__c where Name = 'ASSIGNED'limit 1];
        BMCServiceDesk__Incident__c incident = obj.getNewIncident(HD_IncidentTestDataFactory.Team.GENERIC);
        incident.OwnerId = staff.id;
        incident.BMCServiceDesk__queueName__c = 'Default Queue';
        incident.BMCServiceDesk__FKStatus__c = new_status.Id;
        incident.HD_Owner_Manager__c = System.UserInfo.getUserId();
        insert incident;
        
        
        //creating survey form test data : 
        HD_Survey_Form__c hsf = new HD_Survey_Form__c();
        hsf.Available_for_Categories__c = 'P2R';
        hsf.Days_Response_Will_Expire__c = 1;
        hsf.Description__c	= 'this is default form for failsafe';         
        hsf.Form_meta__c='{"question1": {"title": "How well did the Service Desk handle your request ?","type": "slider","min": "0","max": "10","value":"5"	}';
        hsf.IsActive__c=true;
        hsf.Survey_Intro__c='Please take a moment to provide feedback about your recent Service Request to help us improve our service.';
        hsf.Survey_Title__c	='Service Desk Satisfaction Survey';
        hsf.Survey_Type__c='Overall Survey';
        hsf.Team_Tag__c= 'hr';
        insert hsf;
        HD_Survey_Form_Ctrl.ClassObject(String.valueOf(incident.Id),'hr');
        
        
    }//
    
    static TestMethod void testgetSurveyFormTeamDetails(){        
        //creating survey form test data : 
        HD_Survey_Form__c hsf = new HD_Survey_Form__c();
        hsf.Available_for_Team__c = 'hr';
        hsf.Days_Response_Will_Expire__c = 1;
        hsf.Description__c	= 'this is default form for failsafe';         
        hsf.Form_meta__c='{"question1": {"title": "How well did the Service Desk handle your request ?","type": "slider","min": "0","max": "10","value":"5"	}';
        hsf.IsActive__c=true;
        hsf.Survey_Intro__c='Please take a moment to provide feedback about your recent Service Request to help us improve our service.';
        hsf.Survey_Title__c	='Service Desk Satisfaction Survey';
        hsf.Survey_Type__c='Overall Survey';
        hsf.Team_Tag__c= 'hr';
        insert hsf;
        HD_Survey_Form_Ctrl.ClassObject('000000','hr');
        
        
    }//
    
    
    static TestMethod void testSaveSurveyResponseData(){
        List<String> saveDataResponse = new List<String>();
        saveDataResponse.add ('{"title": "How well did the Service Desk handle your request ?","type": "slider","min": "0","max": "10","value":"5"}');
        //creating survey form test data : 
        HD_Survey_Form__c hsf = new HD_Survey_Form__c();
        hsf.Available_for_Categories__c = 'All';
        hsf.Days_Response_Will_Expire__c = 1;
        hsf.Description__c	= 'this is default form for failsafe';         
        hsf.Form_meta__c='{"question1": {"title": "How well did the Service Desk handle your request ?","type": "slider","min": "0","max": "10","value":"5"	}';
        hsf.IsActive__c=true;
        hsf.Survey_Intro__c='Please take a moment to provide feedback about your recent Service Request to help us improve our service.';
        hsf.Survey_Title__c	='Service Desk Satisfaction Survey';
        hsf.Survey_Type__c='Overall Survey';
        hsf.Team_Tag__c= 'hr';
        insert hsf;
        test.startTest();
        HD_Survey_Form_Ctrl.saveSurveyResponse(saveDataResponse, hsf.id, '', UserInfo.getUserId()); //getting the save response details
        test.stopTest();
    }//
    
    static TestMethod void testResponseObject(){
       // test.startTest();    
        HD_Survey_Form_Response_Obj obj = new HD_Survey_Form_Response_Obj();
        obj.title_x = '';
        obj.type_x= '';
        obj.value_x = ''; 
        system.assert(obj != null);
       // test.stopTest();
    }//
}//END CLASS