@IsTest(seeallData=false)
private class HD_Test_AddNoteControllerTest{
    static HD_AddNoteController addNoteController;
    static BMCServiceDesk__Incident__c incident;

    //Positive test case
    static{

        HD_IncidentTestDataFactory incFactory =  new HD_IncidentTestDataFactory();
        incident = incFactory.getIncidentTestData(HD_IncidentTestDataFactory.Team.GENERIC);
        //Test.startTest();
    }

    static TestMethod void addNoteTest(){
        Test.startTest();
        //incident = [Select Id from BMCServiceDesk__Incident__c where BMCServiceDesk__state__c = true AND BMCServiceDesk__inactive__c = false AND BMCServiceDesk__type__c = 'Incident' AND Record_Type__c = 'Helpdesk' LIMIT 1];
        if(incident!=null){
            ApexPages.currentPage().getParameters().put('incidentID',incident.Id);
            addNoteController = new HD_AddNoteController();
            BMCServiceDesk__IncidentHistory__c  ih =  new BMCServiceDesk__IncidentHistory__c();
            addNoteController.saveNote();
            
            
            
           
            HD_AddNoteController an2  = new HD_AddNoteController();
            an2.currentNote.BMCServiceDesk__duration__c = '00:15';
            an2.source = 'ServiceRequest';
            an2.saveNote();
            
            
            HD_AddNoteController an3  = new HD_AddNoteController();
            an3.currentNote.BMCServiceDesk__duration__c = '36:15';
            an3.source = 'ServiceRequest';
            an3.saveNote();
            
            HD_AddNoteController an4  = new HD_AddNoteController();
            an4.currentNote.BMCServiceDesk__duration__c = '37:15';
            an4.source = 'ServiceRequest';
            an4.saveNote();
            
            HD_AddNoteController an5  = new HD_AddNoteController();
            an5.currentNote.BMCServiceDesk__duration__c = '36:151';
            an5.source = 'ServiceRequest';
            an5.saveNote();
            an5.cancel();
            
            HD_AddNoteController an6  = new HD_AddNoteController();
            an6.currentNote.BMCServiceDesk__duration__c = '30:ab';
            an6.source = 'ServiceRequest';
            an6.saveNote();
             
        }
    }
}