/**
* ByPassAndLimitUtils
* Util class to disable code on the fly and to get various details like limits and context while developing
* Author        Date        Description
* Ruchika Sharma  10/12/17  Created Class
                    SFDC-2130 : PSOR -- Refresh Job that links Contract to Account Header.
*/
Public class ByPassAndLimitUtils {


public static Map<String,Officer> officers;


// ASYNC CONTEXT
/**
* True if future limits are available
*/
Public static Boolean isFutureCallAvailable(){
	return remainingFutureCalls() > 0;
}
/**
* Eval how many future call we have
*/
Public static Integer remainingFutureCalls(){
return Limits.getLimitFutureCalls() - Limits.getFutureCalls();
}

/**
* Identifies how many SOQLs are remaining in this transaction
*/
Public static Integer remainingSOQLS(String key){
	if(isRegistered(key))
		return getOfficer(key).remainingSOQLS();
	else
		return Limits.getLimitQueries() - Limits.getQueries();
}

/**
* Identifies how much CPU time is remaining in this transaction
*/
Public static Integer remainingCPUTime(String key){
	if(isRegistered(key))
		return getOfficer(key).remainingCPUTime();
	else
		return Limits.getLimitCpuTime() - Limits.getCpuTime();
}/**
* Identifies how much heap size is remaining in this transaction
*/
Public static Integer remainingHeapSize(String key){
	if(isRegistered(key))
		return getOfficer(key).remainingHeapSize();
	else
		return Limits.getLimitHeapSize() - Limits.getQueries();
}


/**
* Do code Registeration and the max. time it should be executed
*/
Public static void doRegisteration(String key, Integer numberOfExecutions){
	System.debug(LoggingLevel.ERROR,'register by NAP: '+numberOfExecutions);
	getOfficer(key,numberOfExecutions);
}

/**
* Do all code Registeration at once and the max. time it should be executed
*/
Public static void doRegisteration(List<String> keys, Integer numberOfExecutions){
	System.debug(LoggingLevel.ERROR,'register by NAP: '+numberOfExecutions);
	for(String key: keys)
		getOfficer(key,numberOfExecutions);
}


/*
* Set Akam field for calling object
*/
public static void setAkamField(Boolean isInsert,Boolean isUpdate,List<sObject> newList){
	system.debug(LoggingLevel.ERROR,'setAkamField getting called : '+isInsert+' newList: '+newList.size());
	  if(!UserInfo.getName().equalsIgnoreCase('Connection User')){
       
            if (isInsert) {
        
                AkamFieldHandler akamFieldHandler = new AkamFieldHandler();
                AkamFieldHandler.insertHandler(newList);
            } 
            else if (isUpdate) {
            
                AkamFieldHandler akamFieldHandler = new AkamFieldHandler();
                AkamFieldHandler.updateHandler(newList);
            }
        }
}

/**
* runs the code and increment counter by one, before calling it first register code with max execution
*/
Public static Boolean run(String key){
	Officer off = getOfficer(key);
	return off.run();
}
/**
* Start and stop tests for Officer
*/
Public static void startTest(String key){
	getOfficer(key,0).setTestMode(true);
}

Public static void stopTest(String key){
	getOfficer(key,0).setTestMode(false);
}

/**
* Disable code
*/
Public static void disable(String key){
	System.debug(LoggingLevel.ERROR,'diabling key: '+key);
	getOfficer(key).setDisabled(true);
}

/**
* Disable multiple codes
*/
Public static void disable(List<String> keys){
	System.debug(LoggingLevel.ERROR,'diabling key list: '+keys);
	for(String key:keys)
		getOfficer(key).setDisabled(true);
}

/**
* Enable code for execution
*/
Public static void enable(String key){
	getOfficer(key).setDisabled(false);
}

/**
* Eval if code is under limits
*/
Public static Boolean isUnderLimit(String key){
	return getOfficer(key).isLimitAvailable();
}


/**
* Evals if a code can be executed
*/
Public static Boolean canRun(String key){
	return getOfficer(key).canRun();
}

/**
* Evals if all code can be executed
*/
Public static Boolean canRun(Set<String> keys){

	for(String key : keys){
		if(isRegistered(key) && !canRun(key))
		return false;
	}
	return true;
}
/**
* True if code has been disabled
*/
Public static Boolean isDisabled(String key){
	system.debug(LoggingLevel.ERROR,'in isDisabled: '+getOfficer(key).isDisabled());
	return getOfficer(key).isDisabled();
}

/**
* True if startTest(String) has been called
*/
Public static Boolean isTest(String key){
	return getOfficer(key).isTestMode();
}
/**
* Identify if there's an officer that keep track of the code
*/
Public static Boolean isRegistered(String key){
	return getOfficers().containsKey(key);
}


private static Map<String,Officer> getOfficers(){
	if(officers == null){
		officers = new Map<String,Officer>();
	}
	return officers;
}

/**
* Returns the officer matching key, if it does not exist create a new one
*/
private static Officer getOfficer(String key){
	return getOfficer(key,1);
}

private static Officer getOfficer(String key, Integer maxExecutions){

	if(!isRegistered(key)){
		officers.put(key,new Officer(key,maxExecutions));
	}
	return getOfficers().get(key);
}


/**
* THE OFFICER
*
* Every code controlled by the ByPassAndLimitUtils has its definition,
* that maintain its names and other attributes.
*/
private class Officer {

	String name;

	Integer runLimit;
	Integer runCounter;

	Boolean inTestMode;
	Boolean disabled;

	/**
	* Class constructor, defines the name and max. number of executions
	*/
	public Officer(String Pname, Integer maxExecutions){
		name = Pname;
		runLimit = maxExecutions;
		runCounter = 0;
		inTestMode = false;
		disabled = false;
		system.debug(LoggingLevel.ERROR,'Pname: '+name);
	}

	/**
	* set the inTestMode flag
	*/
	private void setTestMode(Boolean testMode){
		inTestMode = testMode;
	}

	private Boolean isTestMode(){
		return inTestMode;
	}

	/**
	* Disable / enable the code
	*/
	private void setDisabled(Boolean disable){
		system.debug(LoggingLevel.ERROR,'disabled in setDisabled:: '+disable);
		disabled = disable;
	}
	/**
	* True if code has been disabled
	*/
	private Boolean isDisabled(){
		system.debug(LoggingLevel.ERROR,'disabled:: '+disabled);
		return disabled;
	}

	/**
	* runs code if it can be executed, without checking system limits
	*/
	private Boolean run(){
		if(!canRunWithNoLimitEval()) return false;

		runCounter++;
		return true;
	}

	//To do: isLimitAvailable should not be available in run method.
	/**
	* Evals if the code can be executed, without checking system limits
	*/
	private Boolean canRunWithNoLimitEval(){
		return (runLimit > runCounter || runLimit == 0 && inTestMode) && !disabled;
	}

	/**
	* Evals if the code can be executed and also checks it with respect to salesforce limits.
	*/
	private Boolean canRun(){
		return (runLimit > runCounter || runLimit == 0 && inTestMode) && !disabled && isLimitAvailable();
	}

	/*
	*Eval how many SOQLs we have
	*/
	private Integer remainingSOQLS(){
		return Limits.getLimitQueries() - Limits.getQueries();
	}

	/*
	*Eval how much CPU time we have and if we can write more code or should it be optimized.
	*/
	private Integer remainingCPUTime(){
		return Limits.getLimitCpuTime() - Limits.getCpuTime();
	}
	/*
	* Eval how much heap size remaining, BEWARE not to introduce it in prod as getHeapSize is an expensive process.
	*/
	private Integer remainingHeapSize(){
		return Limits.getLimitHeapSize() - Limits.getHeapSize();
	}

	/**
	* True if we haven't reached the future limit
	*/
	private Boolean isLimitAvailable(){
		return (remainingSOQLS() > 0 && remainingCPUTime()>0 && remainingHeapSize()>0);
	}
	
	}
}