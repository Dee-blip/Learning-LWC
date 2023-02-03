function CreateMTA(pAccId){
	var result = "";
	try{
		result = sforce.apex.execute("Q2O_AgreementController","CreateViewMTA",{p_accId:pAccId})+"";
	} catch(err) {
		var myRegExp = /INSUFFICIENT_ACCESS/;
		var errString = err+"";
		if(errString.search(myRegExp) != -1)
			result = "0:You do not have sufficient access to create a Master Terms Agreement.";
		else
			result = "0:An unexpected error has occurred. Please contact your System Administrator\n\n" + "Error : " + err;
	}
	return result;
}