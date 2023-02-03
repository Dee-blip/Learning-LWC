/**
	History
		
		--Developer			--Date			--Description
		Ali KM				19/04/2012		Created this Class for -> CR 1588081 Exception - Too many scripts statements when reassigning 200 Accounts.
											- During Account Reassignment.Opportunity owner change Contract share code also runs this causes 'too many scripts..' error. This code is redundant
											and should not run when Opportunity owner change is triggered due to Account Reassignment. In-order to mend this created a override flag which is set
											to true during Account Reassignment and in-turn overrides the Contract share code in 'OpportunityTrigger_ai'. However when opportunity owner is changed
											from anywhere else Contract share code runs as expected.
*/
public global class GSMFeatureOverride 
{
	public static boolean overrideOpportunityOwnerContractShareTrigger=false;
}