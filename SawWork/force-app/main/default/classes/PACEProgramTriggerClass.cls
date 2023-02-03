/*
Class: PACEProgramTriggerClass
Purpose: Validate Program phase movement and throw error if condition fails
Author: Gaurav Jain (gjain@akamai.com)
*/
public with sharing class PACEProgramTriggerClass {
	Set<Id> recrdTypeIds = new Set<Id>();
	public PACEProgramTriggerClass()
	{
		recrdTypeIds.add(Schema.SObjectType.PACE_Program__c.getRecordTypeInfosByName().get('New Program').getRecordTypeId());
		recrdTypeIds.add(Schema.SObjectType.PACE_Program__c.getRecordTypeInfosByName().get('PACE Program PM Readonly Record Type').getRecordTypeId());
		recrdTypeIds.add(Schema.SObjectType.PACE_Program__c.getRecordTypeInfosByName().get('PACE Program PM Readonly Record Type EC go').getRecordTypeId());
		recrdTypeIds.add(Schema.SObjectType.PACE_Program__c.getRecordTypeInfosByName().get('PACE Program Record Type').getRecordTypeId());
	}

	//Validate Dates - PACEENGG-47, PACEENGG-54
	public void validateDates(List<PACE_Program__c> listOfNewRecords)
	{
		for(PACE_Program__c program: listOfNewRecords)
		{
			String errorMsg = '';
			if(recrdTypeIds.contains(program.RecordTypeId))
			{
				if(program.Original_CC__c != null && program.Planned_CC__c != null && program.Original_CC__c > program.Planned_CC__c)
				{
					errorMsg += 'Original CC should be prior or on the same date as Planned/Actual CC.\n';
				}

				if(!program.Skipped_CC__c)
				{
					if(program.Original_EC__c != null && program.Original_CC__c != null && program.Original_EC__c <= program.Original_CC__c)
					{
						errorMsg += 'Original EC cannot be prior or equal to Original CC.\n';
					}
					if(program.Original_EC__c != null && program.Planned_CC__c != null && program.Original_EC__c <= program.Planned_CC__c)
					{
						errorMsg += 'Original EC cannot be prior or equal to Planned/Actual CC.\n';
					}
					if(program.Planned_EC__c != null && program.Original_CC__c != null && program.Planned_EC__c <= program.Original_CC__c)
					{
						errorMsg += 'Planned/Actual EC cannot be prior or equal to Original CC.\n';
					}
					if(program.Planned_EC__c != null && program.Planned_CC__c != null && program.Planned_EC__c <= program.Planned_CC__c)
					{
						errorMsg += 'Planned/Actual EC cannot be prior or equal to Planned/Actual CC.\n';
					}
				}

				//if(program.Original_SC__c != null && program.Planned_Actual_SC__c != null && program.Original_SC__c > program.Planned_Actual_SC__c)
				//{
				//	errorMsg += 'Original SC should be prior or on the same date as Planned/Actual SC.\n';
				//}

				if(program.Original_EC__c != null && program.Planned_EC__c != null && program.Original_EC__c > program.Planned_EC__c)
				{
					errorMsg += 'Original EC should be prior or on the same date as Planned/Actual EC.\n';
				}

				if(program.Original_LC__c != null && program.Original_EC__c != null && program.Original_LC__c <= program.Original_EC__c)
				{
					errorMsg += 'Original EC should be prior to Original LC.\n';
				}
				//if(program.Original_LC__c != null && program.Planned_EC__c != null && program.Original_LC__c <= program.Planned_EC__c)
				//{
				//	errorMsg += 'Original LC cannot be prior or equal to Planned/Actual EC.\n';
				//}
				//if(program.Planned_LC__c != null && program.Original_EC__c != null && program.Planned_LC__c <= program.Original_EC__c)
				//{
				//	errorMsg += 'Planned/Actual LC cannot be prior or equal to Original EC.\n';
				//}
				if(program.Planned_LC__c != null && program.Planned_EC__c != null && program.Planned_LC__c <= program.Planned_EC__c)
				{
					errorMsg += 'Planned/Actual EC should be prior to Planned/Actual LC.\n';
				}

				//if(program.Original_LC__c != null && program.Planned_LC__c != null && program.Original_LC__c > program.Planned_LC__c)
				//{
				//	errorMsg += 'Original LC should be prior or on the same date as Planned/Actual LC.\n';
				//}

				//if(program.Original_LA__c != null && program.Planned_LA__c != null && program.Original_LA__c > program.Planned_LA__c)
				//{
				//	errorMsg += 'Original LA should be prior or on the same date as Planned/Actual LA.\n';
				//}

				if(program.Original_LA__c != null && program.Original_LC__c != null && program.Original_LA__c < program.Original_LC__c)
				{
					errorMsg += 'Original LA cannot be prior to Original LC.\n';
				}

				if(program.Planned_LA__c != null && program.Planned_LC__c != null && program.Planned_LA__c < program.Planned_LC__c)
				{
					errorMsg += 'Planned/Actual LA cannot be prior to Planned/Actual LC.\n';
				}

				if(program.Original_GA__c != null && program.Original_LC__c != null && program.Original_GA__c < program.Original_LC__c)
				{
					errorMsg += 'Original GA cannot be prior to Original LC.\n';
				}
				//if(program.Original_GA__c != null && program.Planned_LC__c != null && program.Original_GA__c <= program.Planned_LC__c)
				//{
				//	errorMsg += 'Original GA cannot be prior or equal to Planned/Actual LC.\n';
				//}
				//if(program.Planned_GA__c != null && program.Original_LC__c != null && program.Planned_GA__c <= program.Original_LC__c)
				//{
				//	errorMsg += 'Planned/Actual GA cannot be prior or equal to Original LC.\n';
				//}
				if(program.Planned_GA__c != null && program.Planned_LC__c != null && program.Planned_GA__c < program.Planned_LC__c)
				{
					errorMsg += 'Planned/Actual GA cannot be prior to Planned/Actual LC.\n';
				}

				//if(program.Original_GA__c != null && program.Planned_GA__c != null && program.Original_GA__c > program.Planned_GA__c)
				//{
				//	errorMsg += 'Original GA should be prior or on the same date as Planned/Actual GA.';
				//}
			}

			if(!String.isBlank(errorMsg))
					program.addError(' ' + errorMsg);
		}
	}

	//Validate Concept to Definition Movement
	public void validateConceptToDefinitionMovement(List<PACE_Program__c> listOfNewRecords, Map<Id, PACE_Program__c> mapOfOldRecords)
	{
		for(PACE_Program__c program: listOfNewRecords)
		{
			PACE_Program__c oldProgram = mapOfOldRecords.get(program.Id);
			String errorMsg = '';
			if(program.Program_Phase__c == 'Definition' && oldProgram.Program_Phase__c == 'Concept' && recrdTypeIds.contains(program.RecordTypeId))
			{
				if(program.Original_EC__c == null)
				{
					errorMsg += 'Original EC Date cannot be blank\n';
				}
				
				if(program.Planned_EC__c == null)
				{
					errorMsg += 'Planned/Actual EC Date cannot be blank\n';
				}
				else if(program.Planned_EC__c < Date.today())
				{
					errorMsg += 'Planned/Actual EC date cannot be in the past\n';
				}
				
				if(!program.Skipped_CC__c && program.Original_CC__c == null)
				{
					errorMsg += 'Original CC Date cannot be blank\n';
				}
				else if(program.Original_CC__c > Date.today())
				{
					errorMsg += 'Original CC date cannot be in future\n';
				}

				if(!program.Skipped_CC__c && program.Planned_CC__c == null)
				{
					errorMsg += 'Planned/Actual CC Date cannot be blank\n';
				}
				else if(program.Planned_CC__c > Date.today())
				{
					errorMsg += 'Planned/Actual CC date cannot be in future';
				}

				if(!String.isBlank(errorMsg))
					program.addError(' ' + errorMsg);
			}
		}
	}

	//Validate movement from Definition to Development
	public void validateDefinitionToDevelopmentMovement(List<PACE_Program__c> listOfNewRecords, Map<Id, PACE_Program__c> mapOfOldRecords)
	{
		for(PACE_Program__c program: listOfNewRecords)
		{
			PACE_Program__c oldProgram = mapOfOldRecords.get(program.Id);
			String errorMsg = '';
			//Conditions for Non EOS EOL Programs
			if(program.Program_Phase__c == 'Development' && oldProgram.Program_Phase__c == 'Definition' && recrdTypeIds.contains(program.RecordTypeId))
			{
				//if(program.Original_LC__c == null)
				//{
				//	errorMsg += 'Original LC date cannot be blank\n';
				//}
				//else if(program.Original_LC__c < Date.today())
				//{
				//	errorMsg += 'Original LC date cannot be in the past\n';
				//}

				//if(program.Planned_LC__c == null)
				//{
				//	errorMsg += 'Planned/Actual LC date cannot be blank\n';
				//}
				//else if(program.Planned_LC__c < Date.today())
				//{
				//	errorMsg += 'Planned/Actual LC date cannot be in the past\n';
				//}

				if(program.Original_LA__c == null && program.Original_GA__c == null)
				{
					errorMsg += 'Both Original LA and Original GA cannot be blank\n';
				}

				if(program.Planned_LA__c == null && program.Planned_GA__c == null)
				{
					errorMsg += 'Both Planned/Actual LA and Planned/Actual GA dates cannot be blank\n';
				}

				if(program.Original_EC__c > Date.today())
				{
					errorMsg += 'Original EC date cannot be in the future\n';
				}

				if(program.Planned_EC__c > Date.today())
				{
					errorMsg += 'Planned/Actual EC date cannot be in future\n';
				}

				if(program.Original_SC__c != null && program.Planned_Actual_SC__c == null)
				{
					errorMsg += 'If Original SC date is available, Planned/Actual SC date cannot be blank\n';
				}
				else if(program.Planned_Actual_SC__c != null && program.Original_SC__c == null)
				{
					errorMsg += 'If Planned/Actual SC date is available, Original SC date cannot be blank\n';
				}

				if(program.Original_LA__c != null && program.Planned_LA__c == null)
				{
					errorMsg += 'If Original LA date is available, Planned/Actual LA date cannot be blank\n';
				}
				else if(program.Planned_LA__c != null && program.Original_LA__c == null)
				{
					errorMsg += 'If Planned/Actual LA date is available, Original LA date cannot be blank\n';
				}

				if(program.Original_GA__c != null && program.Planned_GA__c == null)
				{
					errorMsg += 'If Original GA date is available, Planned/Actual GA date cannot be blank';
				}
				else if(program.Planned_GA__c != null && program.Original_GA__c == null)
				{
					errorMsg += 'If Planned/Actual GA date is available, Original GA date cannot be blank';
				}

				if(!String.isBlank(errorMsg))
					program.addError(' ' + errorMsg);
			}
			//Conditions for EOS EOL Programs
			if(program.Program_Phase__c == 'Development' && oldProgram.Program_Phase__c == 'Definition' && !recrdTypeIds.contains(program.RecordTypeId))
			{
				if(program.Planned_EC__c == null)
				{
					errorMsg += 'Planned/Actual EC date cannot be blank\n';
				}

				if(program.Original_EC__c == null)
				{
					errorMsg += 'Original EC date cannot be blank\n';
				}
				
				//if(program.Planned_EC__c > Date.today())
				//{
				//	errorMsg += 'Planned/Actual EC date cannot be in the future\n';
				//}

				//if(program.Original_EC__c > Date.today())
				//{
				//	errorMsg += 'Original EC date cannot be in the future\n';
				//}

				if(program.Original_EOS__c == null && program.Original_EOL__c == null)
				{
					errorMsg += 'Both Original EOS and Original EOL cannot be blank\n';
				}

				if(program.Planned_Actual_EOS__c == null && program.Planned_Actual_EOL__c == null)
				{
					errorMsg += 'Both Planned/Actual EOS and Planned/Actual EOL cannot be blank\n';
				}

				if(program.Original_EOS__c != null && program.Planned_Actual_EOS__c == null)
				{
					errorMsg += 'If Original EOS is filled, Planned/Actual EOS cannot be blank\n';
				}
				else if(program.Original_EOS__c == null && program.Planned_Actual_EOS__c != null)
				{
					errorMsg += 'If Planned/Actual EOS is filled, Original EOS cannot be blank\n';
				}

				if(program.Original_EOL__c != null && program.Planned_Actual_EOL__c == null)
				{
					errorMsg += 'If Original EOL is filled, Planned/Actual EOL cannot be blank\n';
				}
				else if(program.Original_EOL__c == null && program.Planned_Actual_EOL__c != null)
				{
					errorMsg += 'If Planned/Actual EOL is filled, Original EOL cannot be blank\n';
				}
				if(!String.isBlank(errorMsg))
					program.addError(' ' + errorMsg);
			}
		}
	}

	//Validate movement from Development to Launch
	public void validateDevelopmentToLaunchMovement(List<PACE_Program__c> listOfNewRecords, Map<Id, PACE_Program__c> mapOfOldRecords)
	{
		for(PACE_Program__c program: listOfNewRecords)
		{
			PACE_Program__c oldProgram = mapOfOldRecords.get(program.Id);
			String errorMsg = '';
			if(program.Program_Phase__c == 'Launch' && oldProgram.Program_Phase__c == 'Development' && recrdTypeIds.contains(program.RecordTypeId))
			{
				//if(program.Planned_LC__c == null)
				//{
				//	errorMsg += 'Planned/Actual LC date cannot be blank\n';
				//}
				//if(program.Planned_LC__c > Date.today())
				//{
				//	errorMsg += 'Planned/Actual LC date cannot be in future\n';
				//}

				if(program.Planned_LA__c == null && program.Planned_GA__c == null)
				{
					errorMsg += 'Both Planned/Actual LA and Planned/Actual GA date cannot be blank\n';
				}
				
				if(program.Planned_LA__c < Date.today() && program.Planned_GA__c < Date.today())
				{
					errorMsg += 'Both Planned/Actual LA and Planned/Actual GA date cannot be in the past\n';
				}
				
				if(!String.isBlank(errorMsg))
					program.addError(' ' + errorMsg);
			}
		}
	}
}