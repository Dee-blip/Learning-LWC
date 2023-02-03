@IsTest(seeallData=False)
private class HD_EscalationButtonControllerTest{
	static HD_EscalationButtonController controller;
    static BMCServiceDesk__Incident__c incident; // = [Select Id from BMCServiceDesk__Incident__c where BMCServiceDesk__state__c = true AND BMCServiceDesk__inactive__c = false AND BMCServiceDesk__type__c = 'Incident' AND Record_Type__c = 'Helpdesk' LIMIT 1];
	static List<ApexPages.Message> msgs;
    static HD_IncidentTestDataFactory incFactroy;


	static{


		
        
        
        incFactroy = new HD_IncidentTestDataFactory();//
        incident  =  incFactroy.getIncidentTestData(HD_IncidentTestDataFactory.Team.CORPIT);
	}

	static TestMethod void controllerTest(){
		if(incident!=null){
			ApexPages.currentPage().getParameters().put('incidentID',incident.Id);
			controller = new HD_EscalationButtonController();
            controller.currentNote.BMCServiceDesk__duration__c='10:22';
            controller.save();
		}
	}
    static TestMethod void caseOne(){
		if(incident!=null){
			ApexPages.currentPage().getParameters().put('incidentID',incident.Id);
			controller = new HD_EscalationButtonController();
            controller.currentNote.BMCServiceDesk__duration__c='111:22';
            controller.save();
            msgs = ApexPages.getMessages();
            System.debug('one '+msgs[0].getDetail().contains('Please provide Time Spent value in HH:MM format.'));
            System.assertEquals(true,msgs[0].getDetail().contains('Please provide Time Spent value in HH:MM format.'));

		}
	}
    static TestMethod void caseTwo(){
		if(incident!=null){
			ApexPages.currentPage().getParameters().put('incidentID',incident.Id);
			controller = new HD_EscalationButtonController();
            controller.currentNote.BMCServiceDesk__duration__c='11:90';
            controller.save();
            msgs = ApexPages.getMessages();
            System.debug('two '+msgs[0].getDetail().contains('minutes value in HH:MM can not exceed 59'));
            System.assertEquals(true,msgs[0].getDetail().contains('minutes value in HH:MM can not exceed 59'));

		}
	}
    static TestMethod void caseThree(){
		if(incident!=null){
			ApexPages.currentPage().getParameters().put('incidentID',incident.Id);
			controller = new HD_EscalationButtonController();
            controller.currentNote.BMCServiceDesk__duration__c='37:00';
            controller.save();
            msgs = ApexPages.getMessages();
            System.debug('three '+msgs[0].getDetail().contains('Time Spent value should be in the range 00:10 to 36:00'));
            System.assertEquals(true,msgs[0].getDetail().contains('Time Spent value should be in the range 00:10 to 36:00'));

		}
	}
    static TestMethod void caseFour(){
		if(incident!=null){
			ApexPages.currentPage().getParameters().put('incidentID',incident.Id);
			controller = new HD_EscalationButtonController();
            controller.currentNote.BMCServiceDesk__duration__c='36:06';
            controller.save();
            msgs = ApexPages.getMessages();
            System.debug('four '+msgs[0].getDetail().contains('Time Spent value should be in the range 00:10 to 36:00'));
            System.assertEquals(true,msgs[0].getDetail().contains('Time Spent value should be in the range 00:10 to 36:00'));

		}
	}
    static TestMethod void caseFive(){
		if(incident!=null){
			ApexPages.currentPage().getParameters().put('incidentID',incident.Id);
			controller = new HD_EscalationButtonController();
            controller.currentNote.BMCServiceDesk__duration__c='333';
            controller.save();
            
		}
	}
   
    static TestMethod void caseSix(){
		if(incident!=null){
			ApexPages.currentPage().getParameters().put('incidentID',incident.Id);
			controller = new HD_EscalationButtonController();
            controller.currentNote.BMCServiceDesk__duration__c='00:05';
            controller.save();
            msgs = ApexPages.getMessages();
            System.debug('six '+msgs[0].getDetail().contains('Time Spent value should be in the range 00:10 to 36:00'));
            System.assertEquals(true,msgs[0].getDetail().contains('Time Spent value should be in the range 00:10 to 36:00'));

		}
	}
    static TestMethod void caseSeven(){
		if(incident!=null){
			ApexPages.currentPage().getParameters().put('incidentID',incident.Id);
			controller = new HD_EscalationButtonController();
            controller.currentNote.BMCServiceDesk__duration__c='ww:ee';
            controller.save();
            msgs = ApexPages.getMessages();
            System.debug('seven '+msgs[0].getDetail().contains('There was a problem with parsing Time Spent value.'));
            System.assertEquals(true,msgs[0].getDetail().contains('There was a problem with parsing Time Spent value.'));

		}
	}
    
}