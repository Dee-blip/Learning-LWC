/** SpecialistCompTeamTrigger_bi_bu

@author : Ruchika Sharma <rsharma@akamai.com>
@Description : This Trigger calls SpecialistCompTeamTriggerClass to perform following funstions on update or insert of SpecialistCompTeam object :
                    	1.	Populate the value as “!{Prod Specialist Name}+‘Comp Team’” in name field.
						2.	Populate value in Unique_Prod_Specialist__c to make Product_Specialist__c unique.
   
   
    @History
    --Developer           --Date            --Change
    Ruchika Sharma		18/09/2014  	Created the trigger for CR 2703054 - Product Specialist Crediting 
**/

trigger SpecialistCompTeamTrigger_bi_bu on Specialist_Comp_Team__c (before insert, before update) 
{
	List<Specialist_Comp_Team__c> SCTList = new List<Specialist_Comp_Team__c>();
	List<ID> SCTProdSpecialistId = new List<ID>();
	for(Specialist_Comp_Team__c SpecialistCompTeam:Trigger.new){
		// though Product_Specialist__c is mandatory but still putting a null check
		if(SpecialistCompTeam.Product_Specialist__c!=null){
			if(Trigger.isInsert){
				SCTList.add(SpecialistCompTeam);
 				SCTProdSpecialistId.add(SpecialistCompTeam.Product_Specialist__c);
			}
			// Check if it is an update and Product specialist has been changed from previous value
			if(Trigger.isUpdate && Trigger.oldMap.get(SpecialistCompTeam.id).Product_Specialist__c!=SpecialistCompTeam.Product_Specialist__c){
			 	SCTList.add(SpecialistCompTeam);
 				SCTProdSpecialistId.add(SpecialistCompTeam.Product_Specialist__c);

			}
		}
	}
		
	SpecialistCompTeamTriggerClass.updateRecords(SCTList, SCTProdSpecialistId);

}