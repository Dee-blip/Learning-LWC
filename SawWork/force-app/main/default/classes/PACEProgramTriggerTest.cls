@isTest
public class PACEProgramTriggerTest {
	
	@isTest static void testTrigger() {
		PACE_Program__c  programObject = new PACE_Program__c (Original_CC__c=Date.today()-1 ,Division__c = 'Media',Name = 'PgmName',Program_Type__c='New Product',Version__c='1.0',Skipped_CC__c = true);
	    insert programObject;
	    System.assertNotEquals(programObject.id, null);

		User thisUser = [SELECT Id FROM User WHERE isActive=true and Profile.Name='Product Management' limit 1];

        System.runAs(thisUser)
        {

	        programObject.Skipped_CC__c = true;
	        programObject.Original_CC__c = Date.today();
	        try {
	        	update programObject;
	        }
	        catch(System.DmlException e)
	        {
	        	System.assertEquals(e.getDmlMessage(0), 'CC dates cannot be updated');
	        }
	        programObject.Skipped_CC__c = false;
	        programObject.Program_Phase__c = 'Definition';
	        try {
	        	update programObject;
	        }
	        catch(exception e)
	        {
	        	//System.assert(e.getDmlMessage(0).contains('Original CC should be prior or on the same date as Planned/Actual CC'));
	        }

	        programObject.Original_CC__c = null;
	        programObject.Planned_CC__c = null;
	        try {
	        	update programObject;
	        }
	        catch(exception e)
	        {
	        	//System.assert(e.getDmlMessage(0).contains('Original EC Date cannot be blank'));
	        }

	        programObject.Original_CC__c = Date.today()+1;
	        try {
	        	update programObject;
	        }
	        catch(exception e)
	        {
	        	//System.assert(e.getDmlMessage(0).contains('Original CC date cannot be in future'));
	        }

	        programObject.Planned_EC__c = Date.today()-1;
	        programObject.Planned_CC__c = Date.today()+1;
	        try {
	        	update programObject;
	        }
	        catch(exception e)
	        {
	        	//System.assert(e.getDmlMessage(0).contains('Planned/Actual EC cannot be prior or equal to Original CC'));
	        }

	        programObject.Original_EC__c = Date.today()+1;
	        programObject.Planned_EC__c = Date.today()+2;
	        programObject.Original_CC__c = Date.today() - 1;
	        programObject.Planned_CC__c = Date.today();
	        programObject.Resource_Status__c = 'On Track';
	        programObject.Schedule_Status__c = 'On Track';
	        
	        update programObject;

	        programObject.Program_Phase__c = 'Development';
	        try {
	        	update programObject;
	        }
	        catch(exception e)
	        {
	        	//System.assert(e.getDmlMessage(0).contains('Original LC date cannot be blank'));
	        }

	        programObject.Planned_LC__c = Date.today() - 1;
	        programObject.Planned_EC__c = Date.today() + 1;
	        programObject.Original_SC__c = Date.today();
	        try {
	        	update programObject;
	        }
	        catch(exception e)
	        {
	        	//System.assert(e.getDmlMessage(0).contains('Planned/Actual LC cannot be prior or equal to Original EC'));
	        }

	        programObject.Original_SC__c = null;
	        programObject.Planned_Actual_SC__c = Date.today();
	        try {
	        	update programObject;
	        }
	        catch(exception e)
	        {
	        	//System.assert(e.getDmlMessage(0).contains('Planned/Actual LC cannot be prior or equal to Original EC'));
	        }

	        programObject.Original_LA__c = Date.today();
	        programObject.Planned_LA__c = null;
	        programObject.Original_GA__c = Date.today();
	        programObject.Planned_GA__c = null;
	        try {
	        	update programObject;
	        }
	        catch(exception e)
	        {
	        	//System.assert(e.getDmlMessage(0).contains('If Original LA date is available, Planned/Actual LA date cannot be blank'));
	        	//System.assert(e.getDmlMessage(0).contains('If Original GA date is available, Planned/Actual GA date cannot be blank'));
	        }

	        programObject.Original_LA__c = null;
	        programObject.Planned_LA__c = Date.today();
	        programObject.Original_GA__c = null;
	        programObject.Planned_GA__c = Date.today();
	        programObject.Original_LC__c = Date.today()-1;
	        programObject.Original_EC__c = Date.today()+1;
	        try {
	        	update programObject;
	        }
	        catch(exception e)
	        {
	        	//System.assert(e.getDmlMessage(0).contains('If Planned/Actual LA date is available, Original LA date cannot be blank'));
	        	//System.assert(e.getDmlMessage(0).contains('If Planned/Actual GA date is available, Original GA date cannot be blank'));
	        	//System.assert(e.getDmlMessage(0).contains('Original LC date cannot be in the past'));
	        	//System.assert(e.getDmlMessage(0).contains('Original EC date cannot be in the future'));
	        }

	        programObject.Original_LC__c = Date.today();
	        programObject.Planned_LC__c = Date.today();
	        programObject.Original_LA__c = Date.today();
	        programObject.Original_GA__c = Date.today();
	        programObject.Planned_LA__c = Date.today();
	        programObject.Planned_GA__c = Date.today();
	        programObject.Planned_EC__c = Date.today();
	        programObject.Original_SC__c = Date.today();
	        programObject.Planned_Actual_SC__c = Date.today();
	        programObject.Original_SC__c = Date.today();
	        programObject.Original_CC__c = Date.today() - 2;
	        programObject.Original_EC__c = Date.today();
	        
	        try {
	        	update programObject;
	        }
	        catch(exception e)
	        {
	        	//System.assertEquals(e.getDmlMessage(0), 'CC dates cannot be updated');
	        }
	        programObject.Original_CC__c = Date.today() - 1;
	        try{
	        	update programObject;
	        }
	        catch(exception e)
	        {

	        }

	        programObject.Planned_LC__c = Date.today() + 1;
	        programObject.Planned_LA__c = Date.today() - 1;
	        programObject.Planned_GA__c = Date.today() - 1;
	        programObject.Program_Phase__c = 'Launch';
	        
	        try {
	        	update programObject;
	        }
	        catch(exception e)
	        {
	        	//System.assert(e.getDmlMessage(0).contains('Planned/Actual LC date cannot be in future'));
	        }

	        programObject.Planned_LC__c = null;
	        try {
	        	update programObject;
	        }
	        catch(exception e)
	        {
	        	//System.assert(e.getDmlMessage(0).contains('Planned/Actual LC date cannot be blank'));
	        }

	        programObject.Planned_LC__c = Date.today();
	        programObject.Planned_LA__c = Date.today();
	        programObject.Planned_GA__c = Date.today();
	        programObject.Program_Phase__c = 'Launch';
	        programObject.Original_CC__c = Date.today() - 2;
	        try {
	        	update programObject;
	        }
	        catch(exception e)
	        {
	        	//System.assert(e.getDmlMessage(0).contains('CC/EC dates cannot be updated'));
	        }

	        programObject.Original_CC__c = Date.today() - 1;
	        programObject.Original_LC__c = Date.today() - 1;
	        programObject.BatchDate__c = Date.today() - 1;
	        try {
	        	update programObject;
	        }
	        catch(exception e)
	        {
	        	//System.assertEquals(e.getDmlMessage(0), 'Original LC,Beta,LA,GA dates cannot be updated');
	        }

	        programObject.BatchDate__c = Date.today() + 1;
	        programObject.Original_LC__c = Date.today();
	        try
	        {
	        	update programObject;
	        }
	        catch(exception e)
	        {}

	        programObject.Original_CC__c = Date.today() - 2;
	        try {
	        	update programObject;
	        }
	        catch(exception e)
	        {
	        	//System.assertEquals(e.getDmlMessage(0), 'Only Planned/Actual LA and GA can be updated');
	        }
			Id EOL_EOS_CC_LockedRT =  Schema.SObjectType.PACE_Program__c.getRecordTypeInfosByName().get('EOL/EOS CC Locked').getRecordTypeId();
	        PACE_Program__c eolProgram = new PACE_Program__c (RecordTypeId=EOL_EOS_CC_LockedRT, Program_Phase__c = 'Concept', Mail_exception__c = false, Program_Manager__c = UserInfo.getUserId(), Division__c = 'Media',Name = 'EOL Phase Pgm',Program_Type__c='EOL/EOS',Version__c='1.0');
	    	insert eolProgram;

	    	eolProgram.Program_Phase__c = 'Definition';
	    	update eolProgram;

	    	eolProgram.Program_Phase__c = 'Development';
	    	try {
	    		update eolProgram;
	    	}
	    	catch(exception e)
	        {
	        	//System.assert(e.getDmlMessage(0).contains('Original EC date cannot be blank'));
	        }

	        eolProgram.Original_EOS__c = Date.today();
	        eolProgram.Original_EOL__c = Date.today();
	        try {
	    		update eolProgram;
	    	}
	    	catch(exception e)
	        {
	        	//System.assert(e.getDmlMessage(0).contains('If Original EOS is filled, Planned/Actual EOS cannot be blank'));
	        	//System.assert(e.getDmlMessage(0).contains('If Original EOL is filled, Planned/Actual EOL cannot be blank'));
	        }

	        eolProgram.Planned_EC__c = Date.today()+1;
	        eolProgram.Original_EOS__c = null;
	        eolProgram.Original_EOL__c = null;
	        eolProgram.Planned_Actual_EOS__c = Date.today();
	        eolProgram.Planned_Actual_EOL__c = Date.today();
	        try {
	    		update eolProgram;
	    	}
	    	catch(exception e)
	        {
	        	//System.assert(e.getDmlMessage(0).contains('If Planned/Actual EOS is filled, Original EOS cannot be blank'));
	        	//System.assert(e.getDmlMessage(0).contains('If Planned/Actual EOL is filled, Original EOL cannot be blank'));
	        }
	    }
	}

	@isTest static void testPhase()
	{
		PACE_Program__c  programObject = new PACE_Program__c (Original_CC__c=Date.today()-1 ,Division__c = 'Media',Name = 'PgmName',Program_Type__c='New Product',Version__c='1.0');
        insert programObject;
        System.assertNotEquals(programObject.id, null);
        programObject.Name = 'NewPgmName';
        update programObject;
        List<PACE_Phase__c> phases = [Select Id, Name, PACE_Program__c, RecordTypeId From PACE_Phase__c Where Name in (:programObject.Name+'- ' + 'Definition', :programObject.Name+'- ' + 'Development',:programObject.Name+'- ' + 'Launch',:programObject.Name+'- ' + 'Concept')];
        System.assertEquals(4, phases.size());
	}
}