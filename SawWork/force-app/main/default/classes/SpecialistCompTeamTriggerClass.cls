/** SpecialistCompTeamTriggerClass

@author : Ruchika Sharma <rsharma@akamai.com>
@Description : This class implements the following logic for the SpecialistCompTeamTrigger_bi_bu trigger :
                    	1.	Populate the value as “!{Prod Specialist Name}+‘Comp Team’” in name field.
						2.	Populate value in Unique_Prod_Specialist__c to make Product_Specialist__c unique.
   
   
    @History
    --Developer           --Date            --Change
    Ruchika Sharma		18/09/2014  	Created the class for CR 2703054 - Product Specialist Crediting 
**/
public class SpecialistCompTeamTriggerClass{
	

/*updateRecords : This method updates Specialist_Comp_Team__c records
@Param: list<Specialist_Comp_Team__c>, List<ID>
*/
	public static void updateRecords(list<Specialist_Comp_Team__c> SCTList, List<ID> SCTProdSpecialistId){
		// Get name of prodSpecialist through their id which is obtained from each of the Specialist_Comp_Team__c record
		Map<Id, USER> prodSpecialist= new MAP<ID, USER>([SELECT Id, Name From USER Where Id IN:SCTProdSpecialistId]);
		
		for(Specialist_Comp_Team__c SCT: SCTList){
			//Populate the value as “!{Prod Specialist Name}” in name field.
			SCT.Name = prodSpecialist.get(SCT.Product_Specialist__C).Name;
			//Populate value in Unique_Prod_Specialist__c to make Product_Specialist__c unique.
			SCT.Unique_Prod_Specialist__c = SCT.Product_Specialist__C;
		}
		
	}

}